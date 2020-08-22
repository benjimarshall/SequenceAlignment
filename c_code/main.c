#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

#include "tests.h"

int main(int argc, char *argv[]) {
    if (argc < 3) {
        printf("Usage:\n./main <seq1> <seq2>\n");
        return 1;
    }
    char* seq1 = read_fasta(argv[1], 65536);
    bool seq1_from_file = seq1 ? true : false;
    char* seq1_actual = seq1_from_file ? seq1 : argv[1];
    char* seq2 = read_fasta(argv[2], 65536);
    bool seq2_from_file = seq2 ? true : false;
    char* seq2_actual = seq2_from_file ? seq2 : argv[2];
    unsigned long len1 = strlen(seq1_actual);
    unsigned long len2 = strlen(seq2_actual);

    run_sw(seq1_actual, len1, seq2_actual, len2);
    run_nw(seq1_actual, len1, seq2_actual, len2);
    run_sw_linear_parallel(seq1_actual, len1, seq2_actual, len2);
    run_sw_gotoh(seq1_actual, len1, seq2_actual, len2);

    if (seq1_from_file) free(seq1);
    if (seq2_from_file) free(seq2);

    return 0;
}
