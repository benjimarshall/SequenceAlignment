#ifndef PARTIIPROJECT_SWGOTOH_H
#define PARTIIPROJECT_SWGOTOH_H

#include "helpers.h"

GotohGrids sw_gotoh(char* seq1, unsigned long len1, char* seq2, unsigned long len2, BestCell* bestCell);

GotohGrids nw_gotoh(char *seq1, unsigned long len1, char *seq2, unsigned long len2, BestCell *bestCell, bool verticalGapStarted, bool horizontalGapStarted);

char **sw_gotoh_linear(char *seq1, unsigned long len1, char *seq2, unsigned long len2,
                       bool fixedTop, bool fixedBottom,bool gapTop, bool gapBottom, bool gapLeft, bool gapRight);

#endif //PARTIIPROJECT_SWGOTOH_H
