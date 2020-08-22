#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

#include "helpers.h"
#include "sw.h"
#include "swGotoh.h"
#include "swParallel.h"

void run_sw(char *seq1, unsigned long len1, char *seq2, unsigned long len2) {
    BestCell bestCell = (BestCell) {0, 0, 0};
    CellDecision** decisions = sw(seq1, len1, seq2, len2, &bestCell);

    char** aligned = backtrace(seq1, len1, seq2, len2, decisions, &bestCell, false);

    printf("Smith-Waterman (quadratic space) gives score: %d\n", score_aligned_pair(aligned[0], aligned[1]));
    printf("Aligned 1: %s\n", aligned[0]);
    printf("Aligned 2: %s\n\n", aligned[1]);

    free(aligned[0]);
    free(aligned[1]);
    free(aligned);
    for (unsigned long i = 0; i < len1 + 1; i++) {
        free(decisions[i]);
    }
    free(decisions);
}

void run_nw(char *seq1, unsigned long len1, char *seq2, unsigned long len2) {
    BestCell bestCell = (BestCell) {0, 0, 0};
    CellDecision** decisions = sw(seq1, len1, seq2, len2, &bestCell);

    char** aligned = backtrace(seq1, len1, seq2, len2, decisions, &bestCell, true);

    printf("Needleman-Wunsch (quadratic space) gives score: %d\n", score_aligned_pair(aligned[0], aligned[1]));
    printf("Aligned 1: %s\n", aligned[0]);
    printf("Aligned 2: %s\n\n", aligned[1]);

    free(aligned[0]);
    free(aligned[1]);
    free(aligned);
    for (unsigned long i = 0; i < len1 + 1; i++) {
        free(decisions[i]);
    }
    free(decisions);
}

void run_sw_linear_parallel(char *seq1, unsigned long len1, char *seq2, unsigned long len2) {
    SWSequencePairWithSem sp = (SWSequencePairWithSem) {seq1, len1, seq2, len2,false, false, NULL};
    char** aligned = sw_linear_parallel(sp);

    printf("Smith-Waterman (linear space, parallel gives score): %d\n", score_aligned_pair(aligned[0], aligned[1]));
    printf("Aligned 1: %s\n", aligned[0]);
    printf("Aligned 2: %s\n\n", aligned[1]);

    free(aligned[0]);
    free(aligned[1]);
    free(aligned);
}

void run_sw_gotoh(char *seq1, unsigned long len1, char *seq2, unsigned long len2) {
    char** aligned = sw_gotoh_linear(seq1, len1, seq2, len2, false, false, false, false, false, false);

    printf("Smith-Waterman (linear space, affine gap scoring) gives score: %d\n", score_gotoh(aligned[0], aligned[1]));
    printf("Aligned 1: %s\n", aligned[0]);
    printf("Aligned 2: %s\n\n", aligned[1]);

    free(aligned[0]);
    free(aligned[1]);
    free(aligned);
}

char* read_fasta(char* file_name, unsigned long sequence_length) {
    char* seq = malloc(sizeof(char) * (sequence_length + 1));
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
