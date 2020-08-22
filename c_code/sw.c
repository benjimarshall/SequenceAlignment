#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <limits.h>

#include "nw.h"
#include "sw.h"
#include "helpers.h"

CellDecision decide_cell_sw(int diagonalScore, int aboveScore, int leftScore) {
    int maxScore = max(max(0, diagonalScore), max(aboveScore, leftScore));
    if (maxScore == 0)
        return (CellDecision) {0, Nil};
    else if (maxScore == aboveScore)
        return (CellDecision) {aboveScore, Above};
    else if (maxScore == leftScore)
        return (CellDecision) {leftScore, Left};
    else // if (maxScore == aboveScore)
        return (CellDecision) {diagonalScore, Diagonal};
}

GapDecision decide_gap(int startScore, int extendScore) {
    if (startScore <= extendScore) {
        return (GapDecision) {extendScore, GapExtend};
    }
    else {
        return (GapDecision) {startScore, GapStart};
    }
}

CellDecision **sw(char *seq1, unsigned long len1, char *seq2, unsigned long len2, BestCell *bestCell) {
    // Initialise cell decision table
    CellDecision** decisions = malloc(sizeof(CellDecision*) * (len1+1));
    for (unsigned long i = 0; i < len1 + 1; i++) {
        decisions[i] = malloc(sizeof(CellDecision) * (len2+1));
        for(unsigned long j = 0; j < len2 + 1; j++)
        {
            decisions[i][j] = (CellDecision) {0, Nil};
        }
    }

    for (unsigned long i = 0; i < len1; i++) {
        for (unsigned long j = 0; j < len2; j++) {
            decisions[i+1][j+1] = decide_cell_sw(
                    decisions[i][j].score + match(seq1[i], seq2[j]),
                    decisions[i][j + 1].score + GAP_PENALTY,
                    decisions[i + 1][j].score + GAP_PENALTY
            );
            if (decisions[i+1][j+1].score >= bestCell->score) {
                bestCell->score = decisions[i+1][j+1].score;
                bestCell->i = i+1;
                bestCell->j = j+1;
            }
        }
    }

    return decisions;
}

CellDecision **nw_best(char *seq1, unsigned long len1, char *seq2, unsigned long len2, BestCell *bestCell) {
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
            if (decisions[i+1][j+1].score > bestCell->score) {
                bestCell->score = decisions[i+1][j+1].score;
                bestCell->i = i+1;
                bestCell->j = j+1;
            }
        }
    }

    return decisions;
}

char **sw_linear(char *seq1, unsigned long len1, char *seq2, unsigned long len2,
                 bool fixedTop, bool fixedBottom) {
    // if (fixedTop) we must start from the top left cell
    // if (fixedBottom) we must finish in the bottom right cell

    debug_print("Solving %.*s %.*s T%d B%d \n", (int)len1, seq1, (int)len2, seq2, fixedTop, fixedBottom);
    // If it's easy, just do it directly
    if ((len1 < BOTH_MIN_LENGTH && len2 < BOTH_MIN_LENGTH) || len1 < ABSOLUTE_MIN_LENGTH || len2 < ABSOLUTE_MIN_LENGTH) {
        BestCell bc = (BestCell) {0, 0, 0};

        CellDecision** decisions;
        if (fixedTop) {
            decisions = nw_best(seq1, len1, seq2, len2, &bc);
        }
        else {
            decisions = sw(seq1, len1, seq2, len2, &bc);
        }

        char** alignedPair = backtrace(seq1, len1, seq2, len2, decisions, &bc, fixedBottom);
        debug_print("SW solve    top: %s\n", alignedPair[0]);
        debug_print("SW solve bottom: %s\n", alignedPair[1]);

        for (unsigned long i = 0; i < len1 + 1; i++) {
            free(decisions[i]);
        }
        free(decisions);

        return alignedPair;
    }

    bool stringsSwapped = len1 < len2;
    if (stringsSwapped) {
        char* tmp_s = seq1;
        seq1 = seq2;
        seq2 = tmp_s;

        unsigned long tmp_l = len1;
        len1 = len2;
        len2 = tmp_l;
    }

    // Solve for the top half of the matrix going down
    BestCell bestForwards = (BestCell) {0, 0, 0};
    CellDecision (*decide)(int, int, int) = fixedTop ? &decide_cell_nw : &decide_cell_sw;
    int* prev = malloc(sizeof(int) * (len2+1));
    for (unsigned long j = 0; j <= len2; j++) {
        prev[j] = fixedTop ? j * GAP_PENALTY : 0;
    }


    for (unsigned long i = 1; i <= (len1 +1)/2; i++) {
        int* current = malloc(sizeof(int) * (len2+1));
        current[0] = fixedTop ? i*GAP_PENALTY : 0;

        for (unsigned long j = 1; j <= len2; j++) {
            current[j] = (*decide)(
                    prev[j - 1] + match(seq1[i - 1], seq2[j - 1]),
                    prev[j] + GAP_PENALTY,
                    current[j - 1] + GAP_PENALTY
            ).score;

            if (current[j] > bestForwards.score) {
                bestForwards.score = current[j];
                bestForwards.i = i;
                bestForwards.j = j;
            }

            debug_print("%d ", current[j]);
        }
        debug_print("%s", "\n");

        // Only keeping the current and previous score vectors
        free(prev);
        prev = current;
    }

    debug_print("%s", "back\n");

    int* midDownwards = prev;
    BestCell bestBackwards = (BestCell) {0, 1, 1};
    decide = fixedBottom ? &decide_cell_nw : &decide_cell_sw;

    // Solve for the bottom half of the matrix going up
    prev = malloc(sizeof(int) * (len2+1));
    // memset(prev, 0, sizeof(int) * (len2+1));
    for (unsigned long j = 0; j <= len2; j++) {
        prev[j] = fixedBottom ? j * GAP_PENALTY : 0;
    }

    for (unsigned long i = len1-1; i >= (len1 + 1)/2; i--) {
        int* current = malloc(sizeof(int) * (len2+1));
        current[0] = fixedBottom ? (len1-i)*GAP_PENALTY : 0;

        for (unsigned long j = 1; j <= len2; j++) {
            current[j] = (*decide)(
                    prev[j - 1] + match(seq1[i], seq2[len2 - j]),
                    prev[j] + GAP_PENALTY,
                    current[j - 1] + GAP_PENALTY
            ).score;

            if (current[j] > bestBackwards.score) {
                bestBackwards.score = current[j];
                bestBackwards.i = i;
                bestBackwards.j = j;
            }

            debug_print("%d ", current[j]);
        }
        debug_print("%s", "\n");

        free(prev);
        prev = current;
    }

    // Find the best point to cross the middle vector at
    int bestMiddleScore = INT_MIN;
    unsigned long bestPos = 0;
    // The maths here is a bit funky because of the clunky way I've indexed things
    for (unsigned long i = 1; i <= len2 + 1; i++) {
        debug_print("%d %d\n", prev[i - 1], midDownwards[len2 - i + 1]);
        prev[i - 1] += midDownwards[len2 - i + 1];
        if (prev[i - 1] > bestMiddleScore) {
            bestMiddleScore = prev[i - 1];
            bestPos = len2 + 1 - i;
        }
    }

    debug_print("Best %d %lu\n", bestMiddleScore, bestPos);

    // Solve sub-matrices
    char **alignedPair;

    debug_print("Forwards: %d, middle: %d, backwards: %d\n", bestForwards.score, bestMiddleScore, bestBackwards.score);
    debug_print("Forwards i, j: %lu %lu\n", bestForwards.i, bestForwards.j);
    debug_print("Middle pos: %lu\n", bestPos);
    debug_print("Backwards i, j: %lu %lu\n", bestBackwards.i, bestBackwards.j);

    if ((!fixedBottom && bestForwards.score >= bestMiddleScore) && (fixedTop || bestForwards.score >= bestBackwards.score)) {
        debug_print("%s", "choice1\n");
        alignedPair = sw_linear(seq1, bestForwards.i, seq2, bestForwards.j, fixedTop, true);
    }
    else if ((!fixedTop && bestBackwards.score >= bestMiddleScore) && (fixedBottom || bestBackwards.score >= bestForwards.score)) {
        debug_print("%s", "choice2\n");
        alignedPair = sw_linear(seq1 + bestBackwards.i, len1 - bestBackwards.i,
                                seq2 + len2 - bestBackwards.j, bestBackwards.j,
                                true, fixedBottom);
    }
    else {
        debug_print("%s", "choice3\n");

        // Top left: solve from current top-left cell down to and including the 'best' crossing cell
        char** topPath = sw_linear(seq1, (len1 + 1) / 2, seq2, bestPos, fixedTop, true);

        // Bottom right: solve from the bottom-right diagonal of the 'best' crossing cell,
        // exploiting NW which always goes to the absolute top-left to the current bottom-right cell
        char** bottomPath = sw_linear(seq1 + (len1 + 1) / 2, len1 - (len1 + 1) / 2,
                                      seq2 + bestPos, len2 - bestPos, true, fixedBottom);

        // Append the two subsequences
        alignedPair = malloc(sizeof(char *) * 2);

        alignedPair[0] = malloc(sizeof(char) * (strlen(topPath[0]) + strlen(bottomPath[0]) + 1));
        alignedPair[0][0] = '\0';
        strcat(alignedPair[0], topPath[0]);
        strcat(alignedPair[0], bottomPath[0]);

        alignedPair[1] = malloc(sizeof(char) * (strlen(topPath[1]) + strlen(bottomPath[1]) + 1));
        alignedPair[1][0] = '\0';
        strcat(alignedPair[1], topPath[1]);
        strcat(alignedPair[1], bottomPath[1]);

        free(topPath[0]);
        free(topPath[1]);
        free(topPath);
        free(bottomPath[0]);
        free(bottomPath[1]);
        free(bottomPath);
    }

    if (stringsSwapped) {
        char* tmp_s = alignedPair[0];
        alignedPair[0] = alignedPair[1];
        alignedPair[1] = tmp_s;
    }

    free(prev);
    free(midDownwards);

    debug_print("Top: %s\n", alignedPair[0]);
    debug_print("Bottom: %s\n", alignedPair[1]);
    debug_print("Was solving %.*s %.*s \n", (int)len1, seq1, (int)len2, seq2);

    return alignedPair;
}
