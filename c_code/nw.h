#ifndef PARTIIPROJECT_NW_H
#define PARTIIPROJECT_NW_H

#include "helpers.h"

CellDecision decide_cell_nw (int diagonalScore, int aboveScore, int leftScore);

CellDecision** nw(char* seq1, unsigned long len1, char* seq2, unsigned long len2);

char** nw_linear(char* seq1, unsigned long len1, char* seq2, unsigned long len2);

#endif //PARTIIPROJECT_NW_H
