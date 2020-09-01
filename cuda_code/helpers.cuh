#ifndef CUDA_HELPERS_H
#define CUDA_HELPERS_H

#define ALIGN_GAIN (5)
#define MISALIGN_PENALTY (-4)
#define GAP_PENALTY (-1)
#define GAP_START (-10)
#define GAP_EXTEND (-1)

#define MAX_THREADS (1024)
#define SHARED_MEMORY_LIMIT (49152)

#define ABSOLUTE_MIN_LENGTH 64
#define BOTH_MIN_LENGTH 5120

#define match match_direct
#define match_host match_direct_host
// #define match match_blosum
// #define match_host match_blosum_host

typedef enum {Above, Left, Diagonal, Nil, Undef} Direction;
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
    char* seq1;
    char* seq2;
    unsigned long len;
} AlignedPair;

__device__
int match_direct(char a, char b);

int match_direct_host(char a, char b);

__device__
int match_blosum(char a, char b);

int match_blosum_host(char a, char b);

__global__
void backtraceRunner(const char *seq1, unsigned long len1, const char *seq2, unsigned long len2,
    CellDecision *decisions, BestCell bestCell, bool globalAlign, AlignedPair* alignedPair);

__global__
void backtraceGotohRunner(
    const char *seq1, unsigned long len1, const char *seq2, unsigned long len2,
    CellDecision *decisions, GapDecision *vertical, GapDecision *horizontal,
    BestCell bestCell,
    bool globalAlign, bool forceBottomVerticalGap, bool forceBottomHorizontalGap,
    AlignedPair* alignedPair
);

__global__
void printSeqs(char *d_seq1, unsigned long len1, char *d_seq2, unsigned long len2);

int score_aligned_pair(char* seq1, char* seq2);

int score_gotoh(char* seq1, char* seq2);

#endif // CUDA_HELPERS_H