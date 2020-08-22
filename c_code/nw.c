#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

#include "helpers.h"

CellDecision decide_cell_nw(int diagonalScore, int aboveScore, int leftScore) {
    int maxScore = max(diagonalScore, max(aboveScore, leftScore));
    if (maxScore == aboveScore)
        return (CellDecision) {aboveScore, Above};
    else if (maxScore == leftScore)
        return (CellDecision) {leftScore, Left};
    else // if (maxScore == aboveScore)
        return (CellDecision) {diagonalScore, Diagonal};
}

CellDecision **nw(char *seq1, unsigned long len1, char *seq2, unsigned long len2) {
    // Initialise cell decision table
    CellDecision** decisions = malloc(sizeof(CellDecision*) * (len1+1));

    decisions[0] = malloc(sizeof(CellDecision) * (len2+1));
    decisions[0][0] = (CellDecision) {0, Nil};
    for(unsigned long j = 1; j < len2 + 1; j++) {
        decisions[0][j] = (CellDecision) {j * GAP_PENALTY, Left};
    }

    for (unsigned long i = 1; i < len1 + 1; i++) {
        decisions[i] = malloc(sizeof(CellDecision) * (len2+1));
        decisions[i][0] = (CellDecision) {i * GAP_PENALTY, Above};
    }

    for (unsigned long i = 0; i < len1; i++) {
        for (unsigned long j = 0; j < len2; j++) {
            decisions[i+1][j+1] = decide_cell_nw(
                    decisions[i][j].score + match(seq1[i], seq2[j]),
                    decisions[i][j + 1].score + GAP_PENALTY,
                    decisions[i + 1][j].score + GAP_PENALTY
            );
        }
    }

    return decisions;
}

char **nw_linear(char *seq1, unsigned long len1, char *seq2, unsigned long len2) {
    // printf("Solving %.*s %.*s \n", len1, seq1, len2, seq2);
    // If it's easy, just do it directly
    if ((len1 < 20 && len2 < 20) || len1 < 4 || len2 < 4) {
        CellDecision** decisions = nw(seq1, len1, seq2, len2);

        BestCell bc = (BestCell) {0, 1, 1};
        char** alignedPair = backtrace(seq1, len1, seq2, len2, decisions, &bc, true);
        // printf("SW solve    top: %s\n", alignedPair[0]);
        // printf("SW solve bottom: %s\n", alignedPair[1]);

        for (unsigned long i = 0; i < len1 + 1; i++) {
            free(decisions[i]);
        }
        free(decisions);

        return alignedPair;
    }

    // Solve for the top half of the matrix going down
    int* prev = malloc(sizeof(int) * (len2+1));
    prev[0] = 0;
    for(unsigned long i = 1; i <= len2; i++) {
        prev[i] = i * GAP_PENALTY;
    }
    for (unsigned long i = 1; i <= (len1 +1)/2; i++) {
        int* current = malloc(sizeof(int) * (len2+1));
        current[0] = i * GAP_PENALTY;

        for (unsigned long j = 1; j <= len2; j++) {
            current[j] = decide_cell_nw(
                    prev[j - 1] + match(seq1[i - 1], seq2[j - 1]),
                    prev[j] + GAP_PENALTY,
                    current[j - 1] + GAP_PENALTY
            ).score;
            // printf("%d ", current[j]);
        }
        // printf("\n");

        // Only keeping the current and previous score vectors
        free(prev);
        prev = current;
    }

    // printf("back\n");

    int* midDownwards = prev;

    // Solve for the bottom half of the matrix going up
    prev = malloc(sizeof(int) * (len2+1));
    prev[0] = 0;
    for (unsigned long i = 1; i <= len2; i++) {
        prev[i] = i * GAP_PENALTY;
    }
    int k = 1;
    for (unsigned long i = len1-1; i >= (len1 + 1)/2; i--, k++) {
        int* current = malloc(sizeof(int) * (len2+1));
        current[0] = k * GAP_PENALTY;

        for (unsigned long j = 1; j <= len2; j++) {
            current[j] = decide_cell_nw(
                    prev[j - 1] + match(seq1[i], seq2[len2 - j]),
                    prev[j] + GAP_PENALTY,
                    current[j - 1] + GAP_PENALTY
            ).score;
            // printf("%d ", current[j]);
        }
        // printf("\n");

        free(prev);
        prev = current;
    }

    // Find the best point to cross the middle vector at
    int bestScore = 0;
    unsigned long bestPos = 0;
    // The maths here is a bit funky because of the clunky way I've indexed things
    for (unsigned long i = 1; i <= len2; i++) {
        // printf("%d %d\n", prev[i - 1], midDownwards[len2 - i + 1]);
        prev[i - 1] += midDownwards[len2 - i + 1];
        if (prev[i - 1] > bestScore) {
            bestScore = prev[i - 1];
            bestPos = len2 - i;
        }
    }

    // printf("Best %d %lu\n", bestScore, bestPos);

    // Solve sub-matrices
    // Top left: solve from current top-left cell down to and including the 'best' crossing cell
    char** topPath = nw_linear(seq1, (len1 + 1) / 2,
                               seq2, bestPos + 1);

    // Bottom right: solve from the bottom-right diagonal of the 'best' crossing cell,
    // exploiting NW which always goes to the absolute top-left to the current bottom-right cell
    char** bottomPath = nw_linear(seq1 + (len1 + 1) / 2, len1 - (len1 + 1) / 2,
                                  seq2 + bestPos + 1, len2 - bestPos - 1);

    // Append the two subsequences
    char** alignedPair = malloc(sizeof(char*) * 2);

    alignedPair[0] = malloc(sizeof(char) * (strlen(topPath[0]) + strlen(bottomPath[0]) + 1));
    alignedPair[0][0] = '\0';
    // printf("Top: .%s. .%s.\n", topPath[0], bottomPath[0]);
    strcat(alignedPair[0], topPath[0]);
    strcat(alignedPair[0], bottomPath[0]);

    // printf("Bottom: .%s. .%s.\n", topPath[1], bottomPath[1]);
    // printf("Was solving %.*s %.*s \n", len1, seq1, len2, seq2);

    alignedPair[1] = malloc(sizeof(char) * (strlen(topPath[1]) + strlen(bottomPath[1]) + 1));
    alignedPair[1][0] = '\0';
    strcat(alignedPair[1], topPath[1]);
    strcat(alignedPair[1], bottomPath[1]);

    free(prev);
    free(midDownwards);

    free(topPath[0]);
    free(topPath[1]);
    free(topPath);
    free(bottomPath[0]);
    free(bottomPath[1]);
    free(bottomPath);

    return alignedPair;
}
