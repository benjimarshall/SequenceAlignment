#ifndef CUDA_SW_SINGLEBLOCK_H
#define CUDA_SW_SINGLEBLOCK_H

AlignedPair* sw_single_block(cudaStream_t stream, char *seq1, unsigned long len1, char *seq2, unsigned long len2,
                             bool fixedTop, bool fixedBottom);

#endif // CUDA_SW_SINGLEBLOCK_H