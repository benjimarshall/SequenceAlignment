#include <stdio.h>
#include <stdlib.h>

#include "sequence_file_reader.h"
#include "device_manager.h"

int main(int argc, char *argv[]) {
    device_init();

    printf("Beware due to unfixed bodges in the FPGA-HPS interface the first character of\n"
           "each sequence will not be used in the alignment.\n");

    if (argc < 5) {
        printf("Usage:\n./align <seqs_are_dna> <using_blosum> <seq1> <seq2>\n"
               "Where {seqs_are_dna, using_blosum} are each in {0, 1}\n"
               "The maximum sequence lengths are 1023 for seq1 and 1535 for seq2.\n");
        return 1;
    }

    int seqs_are_dna = atoi(argv[1]);
    int using_blosum = atoi(argv[2]);

    // Read in sequences, either from a file or as an argument
    char* seq1 = read_fasta(argv[3], 65536);
    int seq1_from_file = seq1 ? 1 : 0;
    char* seq1_actual = seq1_from_file ? seq1 : argv[3];
    char* seq2 = read_fasta(argv[4], 65536);
    int seq2_from_file = seq2 ? 1 : 0;
    char* seq2_actual = seq2_from_file ? seq2 : argv[4];

    start_job(seq1_actual, seq2_actual, seqs_are_dna);

    // Rudimentary timers for processing time, counting the number of checks that occur before
    // the grid_finished and finished flags are set by the device
    unsigned long long grid_wait = 0ULL;
    unsigned long long total_wait = 0ULL;

    while (1) {
        StatusFlags flags = get_status_flags();
        if (flags.grid_finished) {
            if (flags.finished) {
                break;
            }
            else {
                total_wait++;
            }
        }
        else {
            grid_wait++;
            total_wait++;
        }
    }

    printf("Grid wait: %llu\nTotal Wait: %llu\n\n", grid_wait, total_wait);
    char results[1024+1536+1];
    int maxCol = 0;
    int maxRow = 0;

    read_results(results, &maxCol, &maxRow, 1);

    printf("Alignment: %s\n", results);

    int score = 0;
    char** alignedPair =
        parse_results(seq1_actual, seq2_actual, results, maxCol, maxRow, &score, seqs_are_dna, using_blosum);

    printf("Score: %d\n", score);
    printf("%s\n", alignedPair[0]);
    printf("%s\n", alignedPair[1]);

    free(alignedPair[0]);
    free(alignedPair[1]);
    free(alignedPair);

    if (seq1_from_file) free(seq1);
    if (seq2_from_file) free(seq2);

    return 0;
}
