#include <stdio.h>
#include <pthread.h>

#include "helpers.cuh"
#include "sw.cuh"

template<bool fixedTop>
__global__
void sw_single_block_global(CellDecision* decisions, int* bestScores, int* bestI, int* bestJ,
    char *seq1, unsigned long len1, char *seq2, unsigned long len2) {
    // Using abitrary threads, ideally len1 <= len2

    if (threadIdx.x == 0)
        decisions[0] = (CellDecision) {0, Nil};

    for (int gridRow = 0; gridRow * blockDim.x < len2; gridRow++) {
        int j = threadIdx.x + gridRow * blockDim.x;

        if (j < len2) {
            decisions[j + 1] = fixedTop ? (CellDecision) {(j + 1) * GAP_PENALTY, Left}
                                        : (CellDecision) {0, Nil};
        }
        for (int gridCol = 0; gridCol * blockDim.x < len1; gridCol++) {
            int iStart = gridCol * blockDim.x;

            if (iStart + threadIdx.x + 1 <= len1) {
                decisions[(iStart + threadIdx.x + 1) * (len2+1)] =
                    fixedTop
                    ? (CellDecision) {(iStart + (int)threadIdx.x + 1) * GAP_PENALTY, Above}
                    : (CellDecision) {0, Nil};
            }
            __syncthreads();

            char seq2_symbol = '\0';
            if (j < len2)
                seq2_symbol = seq2[j];

            for (unsigned long k = 0; k < 2*blockDim.x - 1; k++) {
                int i = iStart + k - threadIdx.x;
                if (iStart <= i && i < iStart + blockDim.x &&
                    i < len1 && j < len2) {

                    CellDecision current;
                    if (fixedTop) {
                        current = decideCellNW(
                            decisions[i*(len2+1) + j].score + match(seq1[i], seq2_symbol),
                            decisions[i*(len2+1) + (j+1)].score + GAP_PENALTY,
                            decisions[(i+1)*(len2+1) + j].score + GAP_PENALTY
                        );
                    }
                    else {
                        current = decideCellSW(
                            decisions[i*(len2+1) + j].score + match(seq1[i], seq2_symbol),
                            decisions[i*(len2+1) + (j+1)].score + GAP_PENALTY,
                            decisions[(i+1)*(len2+1) + j].score + GAP_PENALTY
                        );
                    }
                    decisions[(i+1)*(len2+1) + (j+1)] = current;

                    if (current.score > bestScores[threadIdx.x]) {
                        bestScores[threadIdx.x] = current.score;
                        bestI[threadIdx.x] = i + 1;
                        bestJ[threadIdx.x] = j + 1;
                    }
                }
                __syncthreads();
            }
        }
    }

    for (unsigned int s= blockDim.x / 2; s > 0; s >>= 1) {
        if (threadIdx.x < s && threadIdx.x + s < blockDim.x && threadIdx.x + s < len2) {
            if (bestScores[threadIdx.x] < bestScores[threadIdx.x + s]) {
                bestScores[threadIdx.x] = bestScores[threadIdx.x + s];
                bestI[threadIdx.x] = bestI[threadIdx.x + s];
                bestJ[threadIdx.x] = bestJ[threadIdx.x + s];
            }
        }
        __syncthreads();
    }

    // Bring best values to front of array, if last block
    if (threadIdx.x == 0) {
        bestScores[0] = bestScores[0];
        bestScores[1] = bestI[0];
        bestScores[2] = bestJ[0];
    }
}

AlignedPair* sw_single_block(cudaStream_t stream, char *seq1, unsigned long len1, char *seq2, unsigned long len2, bool fixedTop, bool fixedBottom) {
    AlignedPair* alignedPair;
    cudaMallocManaged(&alignedPair, sizeof(AlignedPair));
    char* aligned1;
    cudaMallocManaged(&aligned1, (len1 + len2 +1) * sizeof(char));
    alignedPair->seq1 = aligned1;
    char* aligned2;
    cudaMallocManaged(&aligned2, (len1 + len2 +1) * sizeof(char));
    alignedPair->seq2 = aligned2;

    if (len1 == 0 || len2 == 0) {
        if (fixedTop && fixedBottom) {
            if (len1 == 0) {
                cudaMemcpy(aligned2, seq2, len2 * sizeof(char), cudaMemcpyDeviceToHost);
                cudaMemset(aligned1, '-', len2*sizeof(char));
                aligned1[len2] = '\0';
                aligned2[len2] = '\0';
            }
            else {
                cudaMemcpy(aligned1, seq1, len1 * sizeof(char), cudaMemcpyDeviceToHost);
                cudaMemset(aligned2, '-', len1*sizeof(char));
                aligned1[len1] = '\0';
                aligned2[len1] = '\0';
            }
        }
        else {
            aligned1[0] = '\0';
            aligned2[0] = '\0';
        }

        // printf("%s\n", aligned1);
        // printf("%s\n", aligned2);

        return alignedPair;
    }


    unsigned int spaceNeeded = (len1+1) * (len2+1) * sizeof(CellDecision);

    CellDecision* decisions;
    cudaMalloc(&decisions, spaceNeeded);

    int* bestScores;
    cudaMalloc(&bestScores, max(len2, 3L) * sizeof(int));
    cudaMemset(bestScores, 0, max(len2, 3L) * sizeof(int));
    int* bestI;
    cudaMalloc(&bestI, len2 * sizeof(int));
    int* bestJ;
    cudaMalloc(&bestJ, len2 * sizeof(int));

    if (fixedTop)
        sw_single_block_global<true><<<1, MAX_THREADS, 0, stream>>>(decisions, bestScores, bestI, bestJ, seq1, len1, seq2, len2);
    else
        sw_single_block_global<false><<<1, MAX_THREADS, 0, stream>>>(decisions, bestScores, bestI, bestJ, seq1, len1, seq2, len2);
    cudaStreamSynchronize(stream);

    BestCell bestCell = (BestCell){0, 0, 0};
    cudaMemcpy(&(bestCell.score), bestScores, sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(&(bestCell.i), bestScores+1, sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(&(bestCell.j), bestScores+2, sizeof(int), cudaMemcpyDeviceToHost);

    backtraceRunner<<<1,1,0,stream>>>(seq1, len1, seq2, len2, decisions, bestCell, fixedBottom, alignedPair);
    cudaStreamSynchronize(stream);

    // printf("%s\n", aligned1);
    // printf("%s\n", aligned2);

    cudaFree(decisions);
    cudaFree(bestScores);
    cudaFree(bestI);
    cudaFree(bestJ);

    return alignedPair;
}
