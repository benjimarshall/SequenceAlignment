#ifndef PARTIIPROJECT_SWPARALLEL_H
#define PARTIIPROJECT_SWPARALLEL_H

#include <semaphore.h>
#include "helpers.h"

#define CORE_COUNT 12

typedef struct {
    char *seq1;
    unsigned long len1;
    char *seq2;
    unsigned long len2;
    bool fixedTop;
    bool fixedBottom;
    sem_t* cores_free;
} SWSequencePairWithSem;

typedef struct {
    int* scores;
    BestCell bestCell;
} ScoresWithBest;

void* sw_linear_parallel_runner(void* args);

char **sw_linear_parallel(SWSequencePairWithSem sp);

#endif //PARTIIPROJECT_SWPARALLEL_H
