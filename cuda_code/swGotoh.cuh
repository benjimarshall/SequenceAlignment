#ifndef CUDA_SW_GOTOH_H
#define CUDA_SW_GOTOH_H

typedef struct {
    char* seq1;
    unsigned long len1;
    char* seq2;
    unsigned long len2;
    bool fixedTop;
    bool fixedBottom;
    bool gapTop;
    bool gapBottom;
    bool gapLeft;
    bool gapRight;
    cudaStream_t stream;
} SWGotohSequencePairWithStream;

typedef struct {
    cudaStream_t stream;
    bool backwards;
    bool gapTop;
    bool gapBottom;
    bool gapLeft;
    bool gapRight;
    char *seq1;
    unsigned long len1;
    char *seq2;
    unsigned long len2;
} SwlGotohSolveArgs;

AlignedPair* sw_gotoh(cudaStream_t stream, char *seq1, unsigned long len1, char *seq2, unsigned long len2,
    bool fixedTop, bool fixedBottom, bool verticalGapStarted, bool horizontalGapStarted,
    bool forceBottomVerticalGap, bool forceBottomHorizontalGap);

void* swGotohLinear(void* args);

#endif // CUDA_SW_GOTOH_H