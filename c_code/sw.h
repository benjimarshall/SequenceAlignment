#ifndef PARTIIPROJECT_SW_H
#define PARTIIPROJECT_SW_H

#include "helpers.h"

#define ABSOLUTE_MIN_LENGTH 64
#define BOTH_MIN_LENGTH 1024

CellDecision decide_cell_sw (int diagonalScore, int aboveScore, int leftScore);

GapDecision decide_gap(int startScore, int extendScore);

CellDecision** sw(char* seq1, unsigned long len1, char* seq2, unsigned long len2, BestCell* bestCell);

char **sw_linear(char *seq1, unsigned long len1, char *seq2, unsigned long len2,
                 bool fixedTop, bool fixedBottom);

CellDecision **nw_best(char *seq1, unsigned long len1, char *seq2, unsigned long len2, BestCell *bestCell);

#endif //PARTIIPROJECT_SW_H
