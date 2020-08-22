#ifndef PARTIIPROJECT_HELPERS_H
#define PARTIIPROJECT_HELPERS_H

#include <stdbool.h>

#define ALIGN_GAIN (5)
#define MISALIGN_PENALTY (-4)
#define GAP_PENALTY (-1)
#define GAP_START (-10)
#define GAP_EXTEND (-1)

#define DEBUG 0
#define debug_print(fmt, ...) \
            do { if (DEBUG) fprintf(stderr, fmt, __VA_ARGS__); } while (0)

#define match match_blosum50

typedef enum {Above=1, Left=2, Diagonal=3, Nil=0} Direction;
typedef enum {GapStart, GapExtend} Gap;
typedef struct {
    int score;
    Direction direction;
} CellDecision;
typedef struct {
    int score;
    Gap gap;
} GapDecision;
typedef struct {
    int score;
    unsigned long i;
    unsigned long j;
} BestCell;
typedef struct {
    CellDecision** decisions;
    GapDecision** horizontal;
    GapDecision** vertical;
} GotohGrids;

int match_constant(char a, char b);

int match_blosum50(char a, char b);

int min(int v1, int v2);

int max(int v1, int v2);

char** backtrace(const char* seq1, unsigned long len1, const char* seq2, unsigned long len2,
                 CellDecision** decisions,
                 BestCell* bestCell, bool fromBottomRight);

char** backtrace_gotoh(const char* seq1, unsigned long len1, const char* seq2, unsigned long len2,
                 GotohGrids grids,
                 BestCell* bestCell, bool fromBottomRight, bool forceBottomVerticalGap, bool forceBottomHorizontalGap);

int score_aligned_pair(char* seq1, char* seq2);

int score_gotoh(char* seq1, char* seq2);

bool is_valid_pair(char* original1, unsigned long lenOriginal1, char* original2, unsigned long lenOriginal2,
                   char* aligned1, unsigned long lenAligned1, char* aligned2, unsigned long lenAligned2);

#endif //PARTIIPROJECT_HELPERS_H
