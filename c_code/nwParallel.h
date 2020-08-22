#ifndef PARTIIPROJECT_NWPARALLEL_H
#define PARTIIPROJECT_NWPARALLEL_H

#include <semaphore.h>
#include "helpers.h"

sem_t sem_cores_free;

typedef struct {
    char *seq1;
    unsigned long len1;
    char *seq2;
    unsigned long len2;
    sem_t* cores_free;
} SequencePairWithSem;

char **nw_linear_parallel(SequencePairWithSem sp);

#endif //PARTIIPROJECT_NWPARALLEL_H
