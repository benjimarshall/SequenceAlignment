#include <limits.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "swGotoh.h"
#include "sw.h"
#include "nw.h"

GotohGrids sw_gotoh(char *seq1, unsigned long len1, char *seq2, unsigned long len2, BestCell *bestCell) {
    // Initialise cell decision table
    CellDecision** decisions = malloc(sizeof(CellDecision*) * (len1+1));
    GapDecision** vertical = malloc(sizeof(CellDecision*) * (len1+1));
    GapDecision** horizontal = malloc(sizeof(CellDecision*) * (len1+1));
    for (unsigned long i = 0; i < len1 + 1; i++) {
        decisions[i] = malloc(sizeof(CellDecision) * (len2+1));
        vertical[i] = malloc(sizeof(GapDecision) * (len2+1));
        horizontal[i] = malloc(sizeof(GapDecision) * (len2+1));
        for(unsigned long j = 0; j < len2 + 1; j++)
        {
            decisions[i][j] = (CellDecision) {0, Nil};
            vertical[i][j] = (GapDecision) {GAP_START, GapStart};
            horizontal[i][j] = (GapDecision) {GAP_START, GapStart};
        }
    }

    for (unsigned long i = 0; i < len1; i++) {
        for (unsigned long j = 0; j < len2; j++) {
            vertical[i+1][j+1] = decide_gap(decisions[i][j + 1].score + GAP_START,
                                            vertical[i][j + 1].score + GAP_EXTEND);
            horizontal[i+1][j+1] = decide_gap(decisions[i + 1][j].score + GAP_START,
                                              horizontal[i + 1][j].score + GAP_EXTEND);

            decisions[i+1][j+1] = decide_cell_sw(
                    decisions[i][j].score + match(seq1[i], seq2[j]),
                    vertical[i + 1][j + 1].score,
                    horizontal[i + 1][j + 1].score
            );
            if (decisions[i+1][j+1].score >= bestCell->score) {
                bestCell->score = decisions[i+1][j+1].score;
                bestCell->i = i+1;
                bestCell->j = j+1;
            }
        }
    }

    return (GotohGrids) {decisions, horizontal, vertical};
}

GotohGrids nw_gotoh(char *seq1, unsigned long len1, char *seq2, unsigned long len2, BestCell *bestCell, bool verticalGapStarted, bool horizontalGapStarted) {
    // Initialise cell decision table
    CellDecision** decisions = malloc(sizeof(CellDecision*) * (len1+1));
    GapDecision** vertical = malloc(sizeof(CellDecision*) * (len1+1));
    GapDecision** horizontal = malloc(sizeof(CellDecision*) * (len1+1));

    decisions[0] = malloc(sizeof(CellDecision) * (len2+1));
    vertical[0] = malloc(sizeof(GapDecision) * (len2+1));
    horizontal[0] = malloc(sizeof(GapDecision) * (len2+1));

    decisions[0][0] = (CellDecision) {0, Nil};

    int gapValue = (verticalGapStarted ? GAP_EXTEND : GAP_START) - GAP_EXTEND;
    for (unsigned long i = 1; i < len1 + 1; i++) {
        decisions[i] = malloc(sizeof(CellDecision) * (len2+1));
        vertical[i] = malloc(sizeof(GapDecision) * (len2+1));
        horizontal[i] = malloc(sizeof(GapDecision) * (len2+1));

        decisions[i][0] = (CellDecision) {gapValue + GAP_EXTEND, Above};
        horizontal[i][0] = (GapDecision) {gapValue + GAP_START + GAP_EXTEND, GapStart};
        vertical[i][0] = (GapDecision) {gapValue + GAP_EXTEND, GapExtend};
        gapValue += GAP_EXTEND;
    }

    // First gap on top row is actually a GapStart, not a GapExtend
    vertical[1][0] = (GapDecision) {(verticalGapStarted ? GAP_EXTEND : GAP_START), GapStart};

    gapValue = (horizontalGapStarted ? GAP_EXTEND : GAP_START) - GAP_EXTEND;
    for(unsigned long j = 1; j < len2 + 1; j++) {
        decisions[0][j] = (CellDecision) {gapValue + GAP_EXTEND, Left};
        horizontal[0][j] = (GapDecision) {gapValue + GAP_EXTEND, GapExtend};
        vertical[0][j] = (GapDecision) {gapValue + GAP_START + GAP_EXTEND, GapStart};
        gapValue += GAP_EXTEND;
    }

    // First gap on top column is actually a GapStart, not a GapExtend
    horizontal[0][1] = (GapDecision) {(horizontalGapStarted ? GAP_EXTEND : GAP_START), GapStart};

    for (unsigned long i = 0; i < len1; i++) {
        for (unsigned long j = 0; j < len2; j++) {
            vertical[i+1][j+1] = decide_gap(decisions[i][j + 1].score + GAP_START,
                                            vertical[i][j + 1].score + GAP_EXTEND);
            horizontal[i+1][j+1] = decide_gap(decisions[i + 1][j].score + GAP_START,
                                              horizontal[i + 1][j].score + GAP_EXTEND);

            decisions[i+1][j+1] = decide_cell_nw(
                    decisions[i][j].score + match(seq1[i], seq2[j]),
                    vertical[i + 1][j + 1].score,
                    horizontal[i + 1][j + 1].score
            );

            if (decisions[i+1][j+1].score > bestCell->score) {
                bestCell->score = decisions[i+1][j+1].score;
                bestCell->i = i+1;
                bestCell->j = j+1;
            }
        }
    }

    return (GotohGrids) {decisions, horizontal, vertical};
}

char **sw_gotoh_linear(char *seq1, unsigned long len1, char *seq2, unsigned long len2,
                bool fixedTop, bool fixedBottom, bool gapTop, bool gapBottom, bool gapLeft, bool gapRight) {
    // if (fixedTop) we must start from the top left cell
    // if (fixedBottom) we must finish in the bottom right cell

    debug_print("Solving %.*s %.*s T%d B%d TG%d BG%d \n", (int)len1, seq1, (int)len2, seq2,
            fixedTop, fixedBottom, gapTop, gapBottom);
    // If it's easy, just do it directly
    if ((len1 < BOTH_MIN_LENGTH && len2 < BOTH_MIN_LENGTH) ||
            len1 < ABSOLUTE_MIN_LENGTH || len2 < ABSOLUTE_MIN_LENGTH) {
        BestCell bc = (BestCell) {0, 0, 0};

        GotohGrids grids;
        if (fixedTop) {
            grids = nw_gotoh(seq1, len1, seq2, len2, &bc, gapTop, gapLeft);
        }
        else {
            grids = sw_gotoh(seq1, len1, seq2, len2, &bc);
        }

        char** alignedPair = backtrace_gotoh(seq1, len1, seq2, len2, grids, &bc, fixedBottom, gapBottom, gapRight);
        debug_print("SW solve    top: %s\n", alignedPair[0]);
        debug_print("SW solve bottom: %s\n", alignedPair[1]);

        for (unsigned long i = 0; i < len1 + 1; i++) {
            free(grids.decisions[i]);
            free(grids.vertical[i]);
            free(grids.horizontal[i]);
        }
        free(grids.decisions);
        free(grids.vertical);
        free(grids.horizontal);

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

        bool temp_b = gapTop;
        gapTop = gapLeft;
        gapLeft = temp_b;

        temp_b = gapBottom;
        gapBottom = gapRight;
        gapRight = temp_b;
    }


    // Solve for the top half of the matrix going down
    BestCell bestForwards = (BestCell) {0, 0, 0};
    CellDecision (*decide)(int, int, int) = fixedTop ? &decide_cell_nw : &decide_cell_sw;
    int* prev_score = malloc(sizeof(int) * (len2 + 1));
    int* prev_vertical = malloc(sizeof(int) * (len2 + 1));
    int* current_horizontal = malloc(sizeof(int) * (len2 + 1));
    // memset(prev_score, 0, sizeof(int) * (len2+1));
    int verticalGapStart = gapTop ? GAP_EXTEND : GAP_START;
    int horizontalGapStart = gapLeft ? GAP_EXTEND : GAP_START;
    prev_score[0] = 0;
    prev_vertical[0] = 0;
    prev_vertical[1] = verticalGapStart;

    for (unsigned long j = 1; j <= len2; j++) {
        prev_score[j] = fixedTop ? horizontalGapStart + (j-1) * GAP_EXTEND : 0;
        prev_vertical[j] = horizontalGapStart + (j-2) * GAP_EXTEND + GAP_START;
        debug_print("(%d, X, %d) ", prev_score[j], prev_vertical[j]);
    }
    debug_print("%s", "\n");

    for (unsigned long i = 1; i <= (len1 +1)/2; i++) {
        int* current_score = malloc(sizeof(int) * (len2+1));
        // int* current_horizontal = malloc(sizeof(int) * (len2+1));
        int* current_vertical = malloc(sizeof(int) * (len2+1));
        current_score[0] = fixedTop ? verticalGapStart + (i-1) * GAP_EXTEND : 0;
        current_vertical[0] = verticalGapStart + (i-1) * GAP_EXTEND;
        current_horizontal[0] = verticalGapStart + (i-2) * GAP_EXTEND + GAP_START;

        for (unsigned long j = 1; j <= len2; j++) {
            current_vertical[j] = decide_gap(prev_score[j] + GAP_START, prev_vertical[j] + GAP_EXTEND).score;
            current_horizontal[j] = decide_gap(current_score[j - 1] + GAP_START,
                    current_horizontal[j - 1] + GAP_EXTEND).score;

            current_score[j] = (*decide)(
                    prev_score[j - 1] + match(seq1[i - 1], seq2[j - 1]),
                    current_vertical[j],
                    current_horizontal[j]
            ).score;

            if (current_score[j] > bestForwards.score) {
                bestForwards.score = current_score[j];
                bestForwards.i = i;
                bestForwards.j = j;
            }

            debug_print("(%d, %d, %d) ", current_score[j], current_horizontal[j], current_vertical[j]);
        }
        debug_print("%s", "\n");

        // Only keeping the current and previous score vectors
        free(prev_score);
        free(prev_vertical);
        prev_score = current_score;
        prev_vertical = current_vertical;
    }

    debug_print("%s", "back\n");

    int* midDownwardsScore = prev_score;
    int* midDownwardsGapScore = prev_vertical;
    BestCell bestBackwards = (BestCell) {0, 1, 1};
    decide = fixedBottom ? &decide_cell_nw : &decide_cell_sw;

    // Solve for the bottom half of the matrix going up
    prev_score = malloc(sizeof(int) * (len2 + 1));
    prev_vertical = malloc(sizeof(int) * (len2 + 1));

    verticalGapStart = gapBottom ? GAP_EXTEND : GAP_START;
    horizontalGapStart = gapRight ? GAP_EXTEND : GAP_START;
    prev_score[0] = 0;
    prev_vertical[0] = 0;
    prev_vertical[1] = verticalGapStart;
    // prev_horizontal[0] = 0;
    // prev_horizontal[1] = GAP_START;

    for (unsigned long j = 1; j <= len2; j++) {
        prev_score[j] = fixedBottom ? horizontalGapStart + (j-1) * GAP_EXTEND : 0;
        // prev_horizontal[j] = fixedTop ? GAP_START + (j-1) * GAP_EXTEND : 0;
        prev_vertical[j] = horizontalGapStart + (j-2) * GAP_EXTEND + GAP_START;
        debug_print("(%d, X, %d) ", prev_score[j], prev_vertical[j]);
    }
    debug_print("%s", "\n");

    for (unsigned long i = len1 - 1; i >= (len1 + 1)/2; i--) {
        int* current_score = malloc(sizeof(int) * (len2+1));
        int* current_vertical = malloc(sizeof(int) * (len2+1));
        current_score[0] = fixedBottom ? verticalGapStart + (len1-i-1) * GAP_EXTEND : 0;
        current_vertical[0] = verticalGapStart + (len1-i-1) * GAP_EXTEND;
        current_horizontal[0] = verticalGapStart + (len1-i-2) * GAP_EXTEND + GAP_START;

        for (unsigned long j = 1; j <= len2; j++) {
            current_vertical[j] = decide_gap(prev_score[j] + GAP_START,
                    prev_vertical[j] + GAP_EXTEND).score;
            current_horizontal[j] = decide_gap(current_score[j - 1] + GAP_START,
                    current_horizontal[j - 1] + GAP_EXTEND).score;

            current_score[j] = (*decide)(
                    prev_score[j - 1] + match(seq1[i], seq2[len2 - j]),
                    current_vertical[j],
                    current_horizontal[j]
            ).score;

            if (current_score[j] > bestBackwards.score) {
                bestBackwards.score = current_score[j];
                bestBackwards.i = i;
                bestBackwards.j = j;
            }

            debug_print("(%c%c, %d, %d, %d) ", seq1[i], seq2[len2 - j], current_score[j],
                    current_horizontal[j], current_vertical[j]);
        }
        debug_print("%s", "\n");

        // Only keeping the current and previous score vectors
        free(prev_score);
        free(prev_vertical);
        prev_score = current_score;
        prev_vertical = current_vertical;
    }

    free(current_horizontal);


    // Find the best point to cross the middle vector at
    int bestMiddleScore = INT_MIN;
    unsigned long bestPos = 0;
    int bestMiddleGapScore = INT_MIN;
    unsigned long bestGapPos = 0;
    // The maths here is a bit funky because of the clunky way I've indexed things
    for (unsigned long i = 1; i <= len2 + 1; i++) {
        debug_print("%d %d :: %d %d\n", prev_score[i - 1], midDownwardsScore[len2 - i + 1],
                prev_vertical[i - 1], midDownwardsGapScore[len2 - i + 1]);
        prev_score[i - 1] += midDownwardsScore[len2 - i + 1];
        prev_vertical[i - 1] += midDownwardsGapScore[len2 - i + 1] - GAP_START + GAP_EXTEND;
        if (prev_score[i - 1] > bestMiddleScore) {
            bestMiddleScore = prev_score[i - 1];
            bestPos = len2 + 1 - i;
        }
        if (prev_vertical[i - 1] > bestMiddleGapScore) {
            bestMiddleGapScore = prev_vertical[i - 1];
            bestGapPos = len2 + 1 - i;
        }
    }
    int overallMiddleBest = bestMiddleScore >= bestMiddleGapScore ? bestMiddleScore : bestMiddleGapScore;

    debug_print("Best %d %lu :: %d %lu\n", bestMiddleScore, bestPos, bestMiddleGapScore, bestGapPos);

    // Solve sub-matrices
    char **alignedPair;

    debug_print("Forwards: %d, middleScore: %d, middleGap: %d, backwards: %d\n",
            bestForwards.score, bestMiddleScore, bestMiddleGapScore, bestBackwards.score);
    debug_print("Forwards i, j: %lu %lu\n", bestForwards.i, bestForwards.j);
    debug_print("Middle pos: %lu :: Gap pos: %lu\n", bestPos, bestGapPos);
    debug_print("Backwards i, j: %lu %lu\n", bestBackwards.i, bestBackwards.j);

    if ((!fixedBottom && bestForwards.score >= overallMiddleBest) && (fixedTop || bestForwards.score >= bestBackwards.score)) {
        debug_print("%s", "choice1\n");
        alignedPair = sw_gotoh_linear(seq1, bestForwards.i, seq2, bestForwards.j,
                fixedTop, true, gapTop, false, gapLeft, false);
    }
    else if ((!fixedTop && bestBackwards.score >= overallMiddleBest) &&
            (fixedBottom || bestBackwards.score >= bestForwards.score)) {
        debug_print("%s", "choice2\n");
        alignedPair = sw_gotoh_linear(seq1 + bestBackwards.i, len1 - bestBackwards.i,
                               seq2 + len2 - bestBackwards.j, bestBackwards.j,
                               true, fixedBottom, false, gapBottom, false, gapRight);
    }
    else {
        debug_print("%s", "choice3 ");

        bool gapMiddle = bestMiddleGapScore > bestMiddleScore;
        debug_print("g%d\n", gapMiddle);
        bestPos = gapMiddle ? bestGapPos : bestPos;

        // Top left: solve from current top-left cell down to and including the 'best' crossing cell
        char** topPath = sw_gotoh_linear(seq1, (len1 + 1) / 2, seq2, bestPos,
                fixedTop, true, gapTop, gapMiddle, gapLeft, false);

        // Bottom right: solve from the bottom-right diagonal of the 'best' crossing cell,
        // exploiting NW which always goes to the absolute top-left to the current bottom-right cell
        char** bottomPath = sw_gotoh_linear(seq1 + (len1 + 1) / 2, len1 - (len1 + 1) / 2,seq2 + bestPos,
                len2 - bestPos, true, fixedBottom, gapMiddle, gapBottom, false, gapRight);

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

    free(prev_score);
    free(midDownwardsScore);
    free(prev_vertical);
    free(midDownwardsGapScore);

    debug_print("Top: %s\n", alignedPair[0]);
    debug_print("Bottom: %s\n", alignedPair[1]);
    debug_print("Was solving %.*s %.*s \n", (int)len1, seq1, (int)len2, seq2);

    return alignedPair;
}
