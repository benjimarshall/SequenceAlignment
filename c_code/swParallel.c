#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>

#include <pthread.h>
#include <semaphore.h>
#include <limits.h>

#include "nw.h"
#include "sw.h"
#include "swParallel.h"

void* swlForwards (void* args) {
    SWSequencePairWithSem sp = *((SWSequencePairWithSem*) args);

    sem_wait(sp.cores_free);

    CellDecision (*decide)(int, int, int) = sp.fixedTop ? &decide_cell_nw : &decide_cell_sw;
    BestCell bestCell = (BestCell) {0, 0, 0};

    // Solve for the top half of the matrix going down
    int* prev = malloc(sizeof(int) * (sp.len2+1));
    for (unsigned long j = 0; j <= sp.len2; j++) {
        prev[j] = sp.fixedTop ? j * GAP_PENALTY : 0;
    }

    for (unsigned long i = 1; i <= (sp.len1 +1)/2; i++) {
        int* current = malloc(sizeof(int) * (sp.len2+1));
        current[0] = sp.fixedTop ? i*GAP_PENALTY : 0;

        for (unsigned long j = 1; j <= sp.len2; j++) {
            current[j] = (*decide)(
                    prev[j - 1] + match(sp.seq1[i - 1], sp.seq2[j - 1]),
                    prev[j] + GAP_PENALTY,
                    current[j - 1] + GAP_PENALTY
            ).score;
            debug_print("%d ", current[j]);

            if (current[j] > bestCell.score) {
                bestCell.score = current[j];
                bestCell.i = i;
                bestCell.j = j;
            }
        }
        debug_print("%s", "\n");

        // Only keeping the current and previous score vectors
        free(prev);
        prev = current;
    }

    debug_print("%s", "back\n");

    sem_post(sp.cores_free);

    ScoresWithBest* ret = malloc(sizeof(ScoresWithBest));
    *ret = (ScoresWithBest) {prev, bestCell};
    return ret;
}

void* swlBackwards (void* args) {
    SWSequencePairWithSem sp = *((SWSequencePairWithSem*) args);

    sem_wait(sp.cores_free);
    CellDecision (*decide)(int, int, int) = sp.fixedBottom ? &decide_cell_nw : &decide_cell_sw;
    BestCell bestCell = (BestCell) {0, 0, 0};

    // Solve for the bottom half of the matrix going up
    int* prev = malloc(sizeof(int) * (sp.len2+1));
    // memset(prev, 0, sizeof(int) * (sp.len2+1));
    for (unsigned long j = 0; j <= sp.len2; j++) {
        prev[j] = sp.fixedBottom ? j * GAP_PENALTY : 0;
    }

    int k = 1;
    for (unsigned long i = sp.len1-1; i >= (sp.len1 + 1)/2; i--, k++) {
        int* current = malloc(sizeof(int) * (sp.len2+1));
        current[0] = sp.fixedBottom ? (sp.len1-i)*GAP_PENALTY : 0;

        for (unsigned long j = 1; j <= sp.len2; j++) {
            current[j] = (*decide)(
                    prev[j - 1] + match(sp.seq1[i], sp.seq2[sp.len2 - j]),
                    prev[j] + GAP_PENALTY,
                    current[j - 1] + GAP_PENALTY
            ).score;
            debug_print("%d ", current[j]);

            if (current[j] > bestCell.score) {
                bestCell.score = current[j];
                bestCell.i = i;
                bestCell.j = j;
            }
        }
        debug_print("%s", "\n");

        free(prev);
        prev = current;
    }

    debug_print("%s", "back\n");

    sem_post(sp.cores_free);

    ScoresWithBest* ret = malloc(sizeof(ScoresWithBest));
    *ret = (ScoresWithBest) {prev, bestCell};
    return ret;
}
void* sw_linear_parallel_runner(void* args) {

    SWSequencePairWithSem sp = *((SWSequencePairWithSem *) args);
    debug_print("Solving %.*s %.*s T%d B%d \n", (int)sp.len1, sp.seq1, (int)sp.len2, sp.seq2,
            sp.fixedTop, sp.fixedBottom);

    // If it's easy, just do it directly
    if ((sp.len1 < BOTH_MIN_LENGTH && sp.len2 < BOTH_MIN_LENGTH) ||
            sp.len1 < ABSOLUTE_MIN_LENGTH || sp.len2 < ABSOLUTE_MIN_LENGTH) {
        sem_wait(sp.cores_free);

        BestCell bc = (BestCell) {0, 0, 0};

        CellDecision **decisions;
        if (sp.fixedTop) {
            decisions = nw_best(sp.seq1, sp.len1, sp.seq2, sp.len2, &bc);
        } else {
            decisions = sw(sp.seq1, sp.len1, sp.seq2, sp.len2, &bc);
        }

        char **alignedPair = backtrace(sp.seq1, sp.len1, sp.seq2, sp.len2, decisions, &bc, sp.fixedBottom);
        debug_print("SW solve    top: %s\n", alignedPair[0]);
        debug_print("SW solve bottom: %s\n", alignedPair[1]);

        for (unsigned long i = 0; i < sp.len1 + 1; i++) {
            free(decisions[i]);
        }
        free(decisions);

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
    }

    pthread_t forward_thread;
    pthread_t backward_thread;

    pthread_create(&forward_thread, NULL, swlForwards, (void *) &sp);
    pthread_create(&backward_thread, NULL, swlBackwards, (void *) &sp);

    ScoresWithBest *topToMidScoresWithBest;
    pthread_join(forward_thread, (void **) &topToMidScoresWithBest);
    int *topToMidScores = topToMidScoresWithBest->scores;
    BestCell bestForwards = topToMidScoresWithBest->bestCell;
    free(topToMidScoresWithBest);

    ScoresWithBest *midToBottomScoresWithBest;
    pthread_join(backward_thread, (void **) &midToBottomScoresWithBest);

    int *midToBottomScores = midToBottomScoresWithBest->scores;
    BestCell bestBackwards = midToBottomScoresWithBest->bestCell;
    free(midToBottomScoresWithBest);

    // Find the best point to cross the middle vector at
    int bestMiddleScore = INT_MIN;
    unsigned long bestPos = 0;
    // The maths here is a bit funky because of the clunky way I've indexws things
    for (unsigned long i = 1; i <= sp.len2 + 1; i++) {
        debug_print("%d %d\n", midToBottomScores[i - 1], topToMidScores[sp.len2 - i + 1]);
        midToBottomScores[i - 1] += topToMidScores[sp.len2 - i + 1];
        if (midToBottomScores[i - 1] > bestMiddleScore) {
            bestMiddleScore = midToBottomScores[i - 1];
            bestPos = sp.len2 + 1 - i;
        }
    }

    debug_print("Best %d %lu\n", bestMiddleScore, bestPos);
    char **alignedPair;

    debug_print("Forwards: %d, middle: %d, backwards: %d\n", bestForwards.score, bestMiddleScore, bestBackwards.score);
    debug_print("Forwards i, j: %lu %lu\n", bestForwards.i, bestForwards.j);
    debug_print("Middle pos: %lu\n", bestPos);
    debug_print("Backwards i, j: %lu %lu\n", bestBackwards.i, bestBackwards.j);


    if ((!sp.fixedBottom && bestForwards.score >= bestMiddleScore) &&
            (sp.fixedTop || bestForwards.score >= bestBackwards.score)) {
        debug_print("%s", "choice1\n");
        SWSequencePairWithSem topOnlyArgs = {
                sp.seq1, bestForwards.i,
                sp.seq2, bestForwards.j,
                sp.fixedTop, true,
                sp.cores_free
        };

        alignedPair = sw_linear_parallel_runner(&topOnlyArgs);
    }
    else if ((!sp.fixedTop && bestBackwards.score >= bestMiddleScore) &&
            (sp.fixedBottom || bestBackwards.score >= bestForwards.score)) {
        debug_print("%s", "choice2\n");
        SWSequencePairWithSem bottomOnlyArgs = (SWSequencePairWithSem) {
            sp.seq1 + bestBackwards.i, sp.len1 - bestBackwards.i,
            sp.seq2 + sp.len2 - bestBackwards.j, bestBackwards.j,
            true, sp.fixedBottom,
            sp.cores_free
        };

        alignedPair = sw_linear_parallel_runner(&bottomOnlyArgs);
    }
    else {
        // Solve sub-matrices
        // Top left: solve from current top-left cell down to and including the 'best' crossing cell
        debug_print("%s", "choice3\n");
        pthread_t top_grid_thread;
        pthread_t bottom_grid_thread;

        SWSequencePairWithSem topSequences = (SWSequencePairWithSem) {
            sp.seq1, (sp.len1 + 1) / 2,
            sp.seq2, bestPos,
            sp.fixedTop, true,
            sp.cores_free
        };
        pthread_create(&top_grid_thread, NULL, sw_linear_parallel_runner, (void *) &topSequences);

        // Bottom right: solve from the bottom-right diagonal of the 'best' crossing cell,
        // exploiting NW which always goes to the absolute top-left to the current bottom-right cell
        SWSequencePairWithSem bottomSequences = (SWSequencePairWithSem) {
            sp.seq1 + (sp.len1 + 1) / 2, sp.len1 - (sp.len1 + 1) / 2,
            sp.seq2 + bestPos, sp.len2 - bestPos,
            true, sp.fixedBottom,
            sp.cores_free
        };

        pthread_create(&bottom_grid_thread, NULL, sw_linear_parallel_runner, (void *) &bottomSequences);

        char **topPath;
        pthread_join(top_grid_thread, (void **) &topPath);

        char **bottomPath;
        pthread_join(bottom_grid_thread, (void **) &bottomPath);

        // Append the two subsequences
        alignedPair = malloc(sizeof(char *) * 2);

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
    free(topToMidScores);

    return alignedPair;
}

char **sw_linear_parallel(SWSequencePairWithSem sp) {
    // Set up the semaphore to prevent overutilisation
    sem_t cores_free;
    sp.cores_free = &cores_free;
    sem_init(sp.cores_free, 0, CORE_COUNT);

    char** alignedPair = sw_linear_parallel_runner(&sp);

    sem_destroy(sp.cores_free);

    return alignedPair;
}
