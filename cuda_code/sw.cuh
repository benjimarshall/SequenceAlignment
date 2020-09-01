#ifndef CUDA_SW_H
#define CUDA_SW_H

typedef struct {
    char* seq1;
    unsigned long len1;
    char* seq2;
    unsigned long len2;
    bool fixedTop;
    bool fixedBottom;
    cudaStream_t stream;
} SWSequencePairWithStream;

typedef struct {
    cudaStream_t stream;
    bool backwards;
    char *seq1;
    unsigned long len1;
    char *seq2;
    unsigned long len2;
} SwlSolveArgs;

AlignedPair* sw(cudaStream_t stream, char *seq1, unsigned long len1, char *seq2, unsigned long len2, bool fixedTop,
                bool fixedBottom);

__device__
CellDecision decideCellSW(int diagonalScore, int aboveScore, int leftScore);

__device__
CellDecision decideCellNW(int diagonalScore, int aboveScore, int leftScore);

__global__
void add_and_maximise(int* topToMidScores, int* midToBottomScores, int len, int* bestScore, int* bestPos) ;

void* swLinear(void* args);

#endif // CUDA_SW_H