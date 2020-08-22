#ifndef PARTIIPROJECT_SWGOTOHPARALLEL_H
#define PARTIIPROJECT_SWGOTOHPARALLEL_H

#include <semaphore.h>

typedef struct {
    char *seq1;
    unsigned long len1;
    char *seq2;
    unsigned long len2;
    bool fixedTop;
    bool fixedBottom;
    bool gapTop;
    bool gapBottom;
    bool gapLeft;
    bool gapRight;
    sem_t* cores_free;
} SWGotohSequencePairWithSem;

typedef struct {
    int* scores;
    int* vertical;
    BestCell bestCell;
} GotohScoresWithBest;

void* sw_gotoh_linear_parallel_runner(void* args);

char** sw_gotoh_linear_parallel(SWGotohSequencePairWithSem sp);

#endif //PARTIIPROJECT_SWGOTOHPARALLEL_H
