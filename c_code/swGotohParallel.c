#include <limits.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <pthread.h>

#include "swGotoh.h"
#include "sw.h"
#include "nw.h"
#include "swGotohParallel.h"
#include "swParallel.h"

void* swlGotohForwards(void* args) {
    SWGotohSequencePairWithSem sp = *((SWGotohSequencePairWithSem*) args);

    sem_wait(sp.cores_free);

    // Solve for the top half of the matrix going down
    BestCell bestForwards = (BestCell) {0, 0, 0};
    CellDecision (*decide)(int, int, int) = sp.fixedTop ? &decide_cell_nw : &decide_cell_sw;
    int* prev_score = malloc(sizeof(int) * (sp.len2 + 1));
    int* prev_vertical = malloc(sizeof(int) * (sp.len2 + 1));
    int verticalGapStart = sp.gapTop ? GAP_EXTEND : GAP_START;
    int horizontalGapStart = sp.gapLeft ? GAP_EXTEND : GAP_START;
    prev_score[0] = 0;
    prev_vertical[0] = 0;
    prev_vertical[1] = verticalGapStart;

    for (unsigned long j = 1; j <= sp.len2; j++) {
        prev_score[j] = sp.fixedTop ? horizontalGapStart + (j-1) * GAP_EXTEND : 0;
        prev_vertical[j] = horizontalGapStart + (j-2) * GAP_EXTEND + GAP_START;
        debug_print("(%d, X, %d) ", prev_score[j], prev_vertical[j]);
    }
    debug_print("%s", "\n");

    int* current_horizontal = malloc(sizeof(int) * (sp.len2+1));

    for (unsigned long i = 1; i <= (sp.len1 +1)/2; i++) {
        int* current_score = malloc(sizeof(int) * (sp.len2+1));
        int* current_vertical = malloc(sizeof(int) * (sp.len2+1));
        current_score[0] = sp.fixedTop ? verticalGapStart + (i-1) * GAP_EXTEND : 0;
        current_vertical[0] = verticalGapStart + (i-1) * GAP_EXTEND;
        current_horizontal[0] = verticalGapStart + (i-2) * GAP_EXTEND + GAP_START;

        for (unsigned long j = 1; j <= sp.len2; j++) {
            current_vertical[j] = decide_gap(prev_score[j] + GAP_START, prev_vertical[j] + GAP_EXTEND).score;
            current_horizontal[j] = decide_gap(current_score[j - 1] + GAP_START,
                    current_horizontal[j - 1] + GAP_EXTEND).score;

            current_score[j] = (*decide)(
                    prev_score[j - 1] + match(sp.seq1[i - 1], sp.seq2[j - 1]),
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
    free(current_horizontal);

    sem_post(sp.cores_free);

    GotohScoresWithBest* ret = malloc(sizeof(GotohScoresWithBest));
    *ret = (GotohScoresWithBest) {prev_score, prev_vertical, bestForwards};
    return ret;
}

void* swlGotohBackwards(void* args) {
    SWGotohSequencePairWithSem sp = *((SWGotohSequencePairWithSem*) args);

    sem_wait(sp.cores_free);

    BestCell bestBackwards = (BestCell) {0, 1, 1};
    CellDecision (*decide)(int, int, int) = sp.fixedBottom ? &decide_cell_nw : &decide_cell_sw;

    // Solve for the bottom half of the matrix going up
    int* prev_score = malloc(sizeof(int) * (sp.len2 + 1));
    int* prev_vertical = malloc(sizeof(int) * (sp.len2 + 1));
    int* prev_horizontal = malloc(sizeof(int) * (sp.len2 + 1));

    int verticalGapStart = sp.gapBottom ? GAP_EXTEND : GAP_START;
    int horizontalGapStart = sp.gapRight ? GAP_EXTEND : GAP_START;
    prev_score[0] = 0;
    prev_vertical[0] = 0;
    prev_vertical[1] = verticalGapStart;
    prev_horizontal[0] = 0;
    prev_horizontal[1] = GAP_START;

    for (unsigned long j = 1; j <= sp.len2; j++) {
        prev_score[j] = sp.fixedBottom ? horizontalGapStart + (j-1) * GAP_EXTEND : 0;
        // prev_horizontal[j] = sp.fixedTop ? GAP_START + (j-1) * GAP_EXTEND : 0;
        prev_vertical[j] = horizontalGapStart + (j-2) * GAP_EXTEND + GAP_START;
        debug_print("(%d, X, %d) ", prev_score[j], prev_vertical[j]);
    }
    debug_print("%s", "\n");

    for (unsigned long i = sp.len1 - 1; i >= (sp.len1 + 1)/2; i--) {
        int* current_score = malloc(sizeof(int) * (sp.len2+1));
        int* current_horizontal = malloc(sizeof(int) * (sp.len2+1));
        int* current_vertical = malloc(sizeof(int) * (sp.len2+1));
        current_score[0] = sp.fixedBottom ? verticalGapStart + (sp.len1-i-1) * GAP_EXTEND : 0;
        current_vertical[0] = verticalGapStart + (sp.len1-i-1) * GAP_EXTEND;
        current_horizontal[0] = verticalGapStart + (sp.len1-i-2) * GAP_EXTEND + GAP_START;

        for (unsigned long j = 1; j <= sp.len2; j++) {
            current_vertical[j] = decide_gap(prev_score[j] + GAP_START, prev_vertical[j] + GAP_EXTEND).score;
            current_horizontal[j] = decide_gap(current_score[j - 1] + GAP_START,
                    current_horizontal[j - 1] + GAP_EXTEND).score;

            current_score[j] = (*decide)(
                    prev_score[j - 1] + match(sp.seq1[i], sp.seq2[sp.len2 - j]),
                    current_vertical[j],
                    current_horizontal[j]
            ).score;

            if (current_score[j] > bestBackwards.score) {
                bestBackwards.score = current_score[j];
                bestBackwards.i = i;
                bestBackwards.j = j;
            }

            debug_print("(%c%c, %d, %d, %d) ", sp.seq1[i], sp.seq2[sp.len2 - j],
                    current_score[j], current_horizontal[j], current_vertical[j]);
        }
        debug_print("%s", "\n");

        // Only keeping the current and previous score vectors
        free(prev_score);
        free(prev_vertical);
        free(prev_horizontal);
        prev_score = current_score;
        prev_horizontal = current_horizontal;
        prev_vertical = current_vertical;
    }

    free(prev_horizontal);

    sem_post(sp.cores_free);

    GotohScoresWithBest* ret = malloc(sizeof(GotohScoresWithBest));
    *ret = (GotohScoresWithBest) {prev_score, prev_vertical, bestBackwards};
    return ret;
}

void* sw_gotoh_linear_parallel_runner(void* args) {
    // if (sp.fixedTop) we must start from the top left cell
    // if (sp.fixedBottom) we must finish in the bottom right cell
    SWGotohSequencePairWithSem sp = *((SWGotohSequencePairWithSem*) args);

    debug_print("Solving %.*s %.*s T%d B%d TG%d BG%d \n", (int)sp.len1, sp.seq1, (int)sp.len2, sp.seq2,
            sp.fixedTop, sp.fixedBottom, sp.gapTop, sp.gapBottom);
    // If it's easy, just do it directly
    if ((sp.len1 < BOTH_MIN_LENGTH && sp.len2 < BOTH_MIN_LENGTH) || sp.len1 < ABSOLUTE_MIN_LENGTH
            || sp.len2 < ABSOLUTE_MIN_LENGTH) {
        sem_wait(sp.cores_free);

        BestCell bc = (BestCell) {0, 0, 0};
        GotohGrids grids;
        if (sp.fixedTop) {
            grids = nw_gotoh(sp.seq1, sp.len1, sp.seq2, sp.len2, &bc, sp.gapTop, sp.gapLeft);
        }
        else {
            grids = sw_gotoh(sp.seq1, sp.len1, sp.seq2, sp.len2, &bc);
        }

        char** alignedPair = backtrace_gotoh(sp.seq1, sp.len1, sp.seq2, sp.len2, grids, &bc,
                sp.fixedBottom, sp.gapBottom, sp.gapRight);
        debug_print("SW solve    top: %s\n", alignedPair[0]);
        debug_print("SW solve bottom: %s\n", alignedPair[1]);

        for (unsigned long i = 0; i < sp.len1 + 1; i++) {
            free(grids.decisions[i]);
            free(grids.vertical[i]);
            free(grids.horizontal[i]);
        }
        free(grids.decisions);
        free(grids.vertical);
        free(grids.horizontal);

        sem_post(sp.cores_free);

        return alignedPair;
    }


    bool stringsSwapped = sp.len1 < sp.len2;
    if (stringsSwapped) {
        char* tmp_s = sp.seq1;
        sp.seq1 = sp.seq2;
        sp.seq2 = tmp_s;

        unsigned long tmp_l = sp.len1;
        sp.len1 = sp.len2;
        sp.len2 = tmp_l;

        bool temp_b = sp.gapTop;
        sp.gapTop = sp.gapLeft;
        sp.gapLeft = temp_b;

        temp_b = sp.gapBottom;
        sp.gapBottom = sp.gapRight;
        sp.gapRight = temp_b;
    }

    pthread_t forward_thread;
    pthread_t backward_thread;

    pthread_create(&forward_thread, NULL, swlGotohForwards, (void *) &sp);
    pthread_create(&backward_thread, NULL, swlGotohBackwards, (void *) &sp);

    GotohScoresWithBest *topToMidScoresWithBest;
    pthread_join(forward_thread, (void **) &topToMidScoresWithBest);
    int* midDownwardsScore = topToMidScoresWithBest->scores;
    int* midDownwardsGapScore = topToMidScoresWithBest->vertical;
    BestCell bestForwards = topToMidScoresWithBest->bestCell;
    free(topToMidScoresWithBest);

    GotohScoresWithBest* midToBottomScoresWithBest;
    pthread_join(backward_thread, (void **) &midToBottomScoresWithBest);

    int *midToBottomScores = midToBottomScoresWithBest->scores;
    int *midToBottomGapScore = midToBottomScoresWithBest->vertical;
    BestCell bestBackwards = midToBottomScoresWithBest->bestCell;
    free(midToBottomScoresWithBest);


    // Find the best point to cross the middle vector at
    int bestMiddleScore = INT_MIN;
    unsigned long bestPos = 0;
    int bestMiddleGapScore = INT_MIN;
    unsigned long bestGapPos = 0;
    // The maths here is a bit funky because of the clunky way I've indexed things
    for (unsigned long i = 1; i <= sp.len2 + 1; i++) {
        debug_print("%d %d :: %d %d\n", midToBottomScores[i - 1], midDownwardsScore[sp.len2 - i + 1],
                midToBottomGapScore[i - 1], midDownwardsGapScore[sp.len2 - i + 1]);
        midToBottomScores[i - 1] += midDownwardsScore[sp.len2 - i + 1];
        midToBottomGapScore[i - 1] += midDownwardsGapScore[sp.len2 - i + 1] - GAP_START + GAP_EXTEND;
        if (midToBottomScores[i - 1] > bestMiddleScore) {
            bestMiddleScore = midToBottomScores[i - 1];
            bestPos = sp.len2 + 1 - i;
        }
        if (midToBottomGapScore[i - 1] > bestMiddleGapScore) {
            bestMiddleGapScore = midToBottomGapScore[i - 1];
            bestGapPos = sp.len2 + 1 - i;
        }
    }
    int overallMiddleBest = bestMiddleScore >= bestMiddleGapScore ? bestMiddleScore : bestMiddleGapScore;

    debug_print("Best %d %lu :: %d %lu\n", bestMiddleScore, bestPos, bestMiddleGapScore, bestGapPos);

    // Solve sub-matrices
    char **alignedPair;

    debug_print("Forwards: %d, middleScore: %d, middleGap: %d, backwards: %d\n", bestForwards.score, bestMiddleScore,
            bestMiddleGapScore, bestBackwards.score);
    debug_print("Forwards i, j: %lu %lu\n", bestForwards.i, bestForwards.j);
    debug_print("Middle pos: %lu :: Gap pos: %lu\n", bestPos, bestGapPos);
    debug_print("Backwards i, j: %lu %lu\n", bestBackwards.i, bestBackwards.j);

    if ((!sp.fixedBottom && bestForwards.score >= overallMiddleBest) &&
    (sp.fixedTop || bestForwards.score >= bestBackwards.score)) {
        debug_print("%s", "choice1\n");
        SWGotohSequencePairWithSem sp_top = (SWGotohSequencePairWithSem) {
            sp.seq1, bestForwards.i,
            sp.seq2, bestForwards.j,
            sp.fixedTop, true, sp.gapTop, false, sp.gapLeft, false,
            sp.cores_free
        };
        alignedPair = sw_gotoh_linear_parallel_runner(&sp_top);
    }
    else if ((!sp.fixedTop && bestBackwards.score >= overallMiddleBest) &&
            (sp.fixedBottom || bestBackwards.score >= bestForwards.score)) {
        debug_print("%s", "choice2\n");
        SWGotohSequencePairWithSem sp_bottom = (SWGotohSequencePairWithSem) {
                sp.seq1 + bestBackwards.i,
                sp.len1 - bestBackwards.i,
                sp.seq2 + sp.len2 - bestBackwards.j,
                bestBackwards.j,
                true, sp.fixedBottom, false, sp.gapBottom, false, sp.gapRight,
                sp.cores_free
        };
        alignedPair = sw_gotoh_linear_parallel_runner(&sp_bottom);
    }
    else {
        debug_print("%s", "choice3 ");
        pthread_t top_grid_thread;
        pthread_t bottom_grid_thread;

        bool gapMiddle = bestMiddleGapScore > bestMiddleScore;
        debug_print("g%d\n", gapMiddle);
        bestPos = gapMiddle ? bestGapPos : bestPos;

        // Top left: solve from current top-left cell down to and including the 'best' crossing cell
        SWGotohSequencePairWithSem sp_top = (SWGotohSequencePairWithSem) {
                sp.seq1, (sp.len1 + 1) / 2,
                sp.seq2, bestPos,
                sp.fixedTop, true, sp.gapTop, gapMiddle, sp.gapLeft, false,
                sp.cores_free
        };
        // char** topPath = sw_gotoh_linear_parallel_runner(&sp_top);
        pthread_create(&top_grid_thread, NULL, sw_gotoh_linear_parallel_runner, (void *) &sp_top);

        // Bottom right: solve from the bottom-right diagonal of the 'best' crossing cell,
        // exploiting NW which always goes to the absolute top-left to the current bottom-right cell
        SWGotohSequencePairWithSem sp_bottom = (SWGotohSequencePairWithSem) {
                sp.seq1 + (sp.len1 + 1) / 2,
                sp.len1 - (sp.len1 + 1) / 2,
                sp.seq2 + bestPos,
                sp.len2 - bestPos,
                true, sp.fixedBottom, gapMiddle, sp.gapBottom, false, sp.gapRight,
                sp.cores_free
        };
        //char** bottomPath = sw_gotoh_linear_parallel_runner(&sp_bottom);
        pthread_create(&bottom_grid_thread, NULL, sw_gotoh_linear_parallel_runner, (void *) &sp_bottom);

        char** topPath;
        pthread_join(top_grid_thread, (void **) &topPath);
        char** bottomPath;
        pthread_join(bottom_grid_thread, (void **) &bottomPath);


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

    free(midToBottomScores);
    free(midDownwardsScore);
    free(midToBottomGapScore);
    free(midDownwardsGapScore);

    debug_print("Top: %s\n", alignedPair[0]);
    debug_print("Bottom: %s\n", alignedPair[1]);
    debug_print("Was solving %.*s %.*s \n", (int)sp.len1, sp.seq1, (int)sp.len2, sp.seq2);

    return alignedPair;
}

char **sw_gotoh_linear_parallel(SWGotohSequencePairWithSem sp) {
    // Set up the semaphore to prevent overutilisation
    sem_t cores_free;
    sp.cores_free = &cores_free;
    sem_init(sp.cores_free, 0, CORE_COUNT);

    char** alignedPair = sw_gotoh_linear_parallel_runner(&sp);

    sem_destroy(sp.cores_free);

    return alignedPair;
}
