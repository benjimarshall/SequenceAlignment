#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "helpers.cuh"
#include "sw.cuh"
#include "swGotoh.cuh"
#include "swSingleBlock.cuh"

void run_sw(char* d_seq1, unsigned long len1, char* d_seq2, unsigned long len2, cudaStream_t stream) {
    AlignedPair* alignedPair = sw(stream, d_seq1, len1, d_seq2, len2, false, false);

    printf("Smith-Waterman (quadratic space) gives score: %d\n",
            score_aligned_pair(alignedPair->seq1, alignedPair->seq2));
    printf("Aligned 1: %s\n", alignedPair->seq1);
    printf("Aligned 2: %s\n\n", alignedPair->seq2);

    cudaFree(alignedPair->seq1);
    cudaFree(alignedPair->seq2);
    cudaFree(alignedPair);
}

void run_nw(char* d_seq1, unsigned long len1, char* d_seq2, unsigned long len2, cudaStream_t stream) {
    AlignedPair* alignedPair = sw(stream, d_seq1, len1, d_seq2, len2, true, true);

    printf("Needleman-Wunsch (quadratic space) gives score: %d\n",
            score_aligned_pair(alignedPair->seq1, alignedPair->seq2));
    printf("Aligned 1: %s\n", alignedPair->seq1);
    printf("Aligned 2: %s\n\n", alignedPair->seq2);

    cudaFree(alignedPair->seq1);
    cudaFree(alignedPair->seq2);
    cudaFree(alignedPair);
}

void run_sw_linear_parallel(char* d_seq1, unsigned long len1, char* d_seq2, unsigned long len2, cudaStream_t stream) {
    SWSequencePairWithStream sp = (SWSequencePairWithStream) {d_seq1, len1, d_seq2, len2, false, false, stream};
    AlignedPair* alignedPair = (AlignedPair*) swLinear(&sp);

    printf("Smith-Waterman (linear space, parallel) gives score: %d\n",
            score_aligned_pair(alignedPair->seq1, alignedPair->seq2));
    printf("Aligned 1: %s\n", alignedPair->seq1);
    printf("Aligned 2: %s\n\n", alignedPair->seq2);

    cudaFree(alignedPair->seq1);
    cudaFree(alignedPair->seq2);
    cudaFree(alignedPair);
}

void run_sw_gotoh(char* d_seq1, unsigned long len1, char* d_seq2, unsigned long len2, cudaStream_t stream) {
    SWGotohSequencePairWithStream sp = (SWGotohSequencePairWithStream) {
        d_seq1, len1, d_seq2, len2,
        false, false, false, false, false, false,
        stream
    };
    AlignedPair* alignedPair = (AlignedPair*) swGotohLinear(&sp);

    printf("Smith-Waterman (linear space, affine gap scoring) gives score: %d\n",
            score_gotoh(alignedPair->seq1, alignedPair->seq2));
    printf("Aligned 1: %s\n", alignedPair->seq1);
    printf("Aligned 2: %s\n\n", alignedPair->seq2);

    cudaFree(alignedPair->seq1);
    cudaFree(alignedPair->seq2);
    cudaFree(alignedPair);
}

void run_sw_singleblock(char* d_seq1, unsigned long len1, char* d_seq2, unsigned long len2, cudaStream_t stream) {
    AlignedPair* alignedPair = sw_single_block(stream, d_seq1, len1, d_seq2, len2, false, false);

    printf("Smith-Waterman (quadratic space, using single CUDA block) gives score: %d\n",
            score_aligned_pair(alignedPair->seq1, alignedPair->seq2));
    printf("Aligned 1: %s\n", alignedPair->seq1);
    printf("Aligned 2: %s\n\n", alignedPair->seq2);

    cudaFree(alignedPair->seq1);
    cudaFree(alignedPair->seq2);
    cudaFree(alignedPair);
}

char* read_fasta(char* file_name, unsigned long sequence_length) {
    char* seq = (char*) malloc(sizeof(char) * (sequence_length + 1));
    *seq = '\0';
    FILE* f = fopen(file_name, "r");

    if (f) {
        char line[100];
        char* l = fgets(line, 100UL*sizeof(char), f);
        while (fgets(line, 100UL*sizeof(char), f)) {
            // Strip newlines
            char* newline_position = strchr(line, '\n');
            if (newline_position != NULL) {
                *newline_position = '\0';
            }
            else {
                printf("A line in %s was too long\n", file_name);
                free(seq);
                return NULL;
            }

            strcat(seq, line);
        }
        fclose(f);
    }
    else {
        // printf("Couldn't read %s\n", file_name);
        free(seq);
        return NULL;
    }

    return seq;
}
