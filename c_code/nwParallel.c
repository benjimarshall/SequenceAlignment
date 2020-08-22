#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

#include <pthread.h>
#include <semaphore.h>

#include "nwParallel.h"
#include "nw.h"
#include "swParallel.h"

void* nwlForwards (void* args) {
    SequencePairWithSem sp = *((SequencePairWithSem*) args);

    sem_wait(sp.cores_free);

    // Solve for the top half of the matrix going down
    int* prev = malloc(sizeof(int) * (sp.len2+1));
    prev[0] = 0;
    for(unsigned long i = 1; i <= sp.len2; i++) {
        prev[i] = i * GAP_PENALTY;
    }
    for (unsigned long i = 1; i <= (sp.len1 +1)/2; i++) {
        int* current = malloc(sizeof(int) * (sp.len2+1));
        current[0] = i * GAP_PENALTY;

        for (unsigned long j = 1; j <= sp.len2; j++) {
            current[j] = decide_cell_nw(
                    prev[j - 1] + match(sp.seq1[i - 1], sp.seq2[j - 1]),
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

    sem_post(sp.cores_free);

    return prev;
}

void* nwlBackwards (void* args) {
    SequencePairWithSem sp = *((SequencePairWithSem*) args);

    sem_wait(sp.cores_free);

    // Solve for the bottom half of the matrix going up
    int* prev = malloc(sizeof(int) * (sp.len2+1));
    prev[0] = 0;
    for (unsigned long i = 1; i <= sp.len2; i++) {
        prev[i] = i * GAP_PENALTY;
    }
    int k = 1;
    for (unsigned long i = sp.len1-1; i >= (sp.len1 + 1)/2; i--, k++) {
        int* current = malloc(sizeof(int) * (sp.len2+1));
        current[0] = k * GAP_PENALTY;

        for (unsigned long j = 1; j <= sp.len2; j++) {
            current[j] = decide_cell_nw(
                    prev[j - 1] + match(sp.seq1[i], sp.seq2[sp.len2 - j]),
                    prev[j] + GAP_PENALTY,
                    current[j - 1] + GAP_PENALTY
            ).score;
            // printf("%d ", current[j].score);
        }
        // printf("\n");

        free(prev);
        prev = current;
    }

    // printf("back\n");

    sem_post(sp.cores_free);

    return prev;
}

void* nwLinearParallelRunner(void* args) {

    SequencePairWithSem sp = *((SequencePairWithSem *) args);
    // printf("Solving %.*s %.*s \n", len1, seq1, len2, seq2);

    // If it's easy, just do it directly
    if ((sp.len1 < 20 && sp.len2 < 20) || sp.len1 < 4 || sp.len2 < 4) {
        BestCell bestCell = (BestCell) {0, 1, 1};

        CellDecision** decisions = nw(sp.seq1, sp.len1, sp.seq2, sp.len2);

        char** alignedPair = backtrace(sp.seq1, sp.len1, sp.seq2, sp.len2, decisions, &bestCell, true);
        // printf("SW solve    top: %s\n", alignedPair[0]);
        // printf("SW solve bottom: %s\n", alignedPair[1]);

        for (unsigned long i = 0; i < sp.len1 + 1; i++) {
            free(decisions[i]);
        }
        free(decisions);

        return alignedPair;
    }

    pthread_t forward_thread;
    pthread_t backward_thread;

    pthread_create(&forward_thread, NULL, nwlForwards, (void *)&sp);
    pthread_create(&backward_thread, NULL, nwlBackwards, (void *)&sp);

    int* topToMidScores;
    pthread_join(forward_thread, (void **) &topToMidScores);

    int* midToBottomScores;
    pthread_join(backward_thread, (void **) &midToBottomScores);

    // Find the best point to cross the middle vector at
    int bestScore = 0;
    unsigned long bestPos = 0;
    // The maths here is a bit funky because of the clunky way I've indexed things
    for (unsigned long i = 1; i <= sp.len2; i++) {
        // printf("%d %d\n", midToBottomScores[i - 1], topToMidScores[sp.len2 - i + 1]);
        midToBottomScores[i - 1] += topToMidScores[sp.len2 - i + 1];
        if (midToBottomScores[i - 1] > bestScore) {
            bestScore = midToBottomScores[i - 1];
            bestPos = sp.len2 - i;
        }
    }

    // printf("Best %d %lu\n", bestScore, bestPos);

    // Solve sub-matrices
    // Top left: solve from current top-left cell down to and including the 'best' crossing cell
    pthread_t top_grid_thread;
    pthread_t bottom_grid_thread;

    SequencePairWithSem topSequences = (SequencePairWithSem) {sp.seq1, (sp.len1 + 1)/2,
                                                sp.seq2, bestPos + 1, sp.cores_free};
    pthread_create(&top_grid_thread, NULL, nwLinearParallelRunner, (void *)&topSequences);

    // Bottom right: solve from the bottom-right diagonal of the 'best' crossing cell,
    // exploiting NW which always goes to the absolute top-left to the current bottom-right cell
    SequencePairWithSem bottomSequences = (SequencePairWithSem) {
        sp.seq1 + (sp.len1 + 1) / 2,
        sp.len1 - (sp.len1 + 1) / 2,
        sp.seq2 + bestPos + 1,
        sp.len2 - bestPos - 1,
        sp.cores_free
    };

    pthread_create(&bottom_grid_thread, NULL, nwLinearParallelRunner, (void *)&bottomSequences);

    char** topPath;
    pthread_join(top_grid_thread, (void **) &topPath);

    char** bottomPath;
    pthread_join(bottom_grid_thread, (void **) &bottomPath);

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

    free(midToBottomScores);
    free(topToMidScores);

    free(topPath[0]);
    free(topPath[1]);
    free(topPath);
    free(bottomPath[0]);
    free(bottomPath[1]);
    free(bottomPath);

    return alignedPair;
}

char **nw_linear_parallel(SequencePairWithSem sp) {
    // Set up the semaphore to prevent overutilisation
    sem_t cores_free;
    sp.cores_free = &cores_free;
    sem_init(sp.cores_free, 0, CORE_COUNT);

    char** alignedPair = nwLinearParallelRunner(&sp);

    sem_destroy(sp.cores_free);

    return alignedPair;
}
