#include <stdio.h>
#include <pthread.h>

#include "helpers.cuh"
#include "sw.cuh"

using namespace std;

typedef struct {
    int* scores;
    BestCell bestCell;
} ScoresWithBest;

__device__
CellDecision decideCellSW(int diagonalScore, int aboveScore, int leftScore) {
    int maxScore = max(max(0, diagonalScore), max(aboveScore, leftScore));
    if (maxScore == aboveScore)
        return (CellDecision) {aboveScore, Above};
    else if (maxScore == leftScore)
        return (CellDecision) {leftScore, Left};
    else if (maxScore == diagonalScore)
        return (CellDecision) {diagonalScore, Diagonal};
    else
        return (CellDecision) {0, Nil};
}

__device__
CellDecision decideCellNW(int diagonalScore, int aboveScore, int leftScore) {
    int maxScore = max(diagonalScore, max(aboveScore, leftScore));
    if (maxScore == aboveScore)
        return (CellDecision) {aboveScore, Above};
    else if (maxScore == leftScore)
        return (CellDecision) {leftScore, Left};
    else // if (maxScore == aboveScore)
        return (CellDecision) {diagonalScore, Diagonal};
}

template<bool fixedTop>
__global__
void sw_device(CellDecision* decisions, int* bestScores, int* bestI, int* bestJ,
    int gridK, char *seq1, unsigned long len1, char *seq2, unsigned long len2) {

    // Len1 (i) rows by Len2 (j) columns
    int gridRow = blockIdx.x;
    int i = threadIdx.x + gridRow * blockDim.x;
    int jStart = (gridK - gridRow) * blockDim.x;

    if (jStart < 0 || jStart >= len2) {
        return;
    }

    if (gridRow == 0) {
        if(threadIdx.x == 0)
        decisions[0] = (CellDecision) {0, Nil};

        if (jStart + threadIdx.x < len2) {
            decisions[jStart + threadIdx.x + 1] =
                fixedTop
                ? (CellDecision) {(jStart + (int)threadIdx.x + 1) * GAP_PENALTY, Left}
                : (CellDecision) {0, Nil};
        }
    }

    if (jStart == 0 && i < len1) {
        bestI[i] = i + 1;
        decisions[(i+1) * (len2+1)] =
            fixedTop
            ? (CellDecision) {(i+1) * GAP_PENALTY, Above}
            : (CellDecision) {0, Nil};
    }
    __syncthreads();

    char seq1_symbol = '\0';
    if (i < len1)
        seq1_symbol = seq1[i];

    // Fill in this block
    for (unsigned long k = 0; k < 2*blockDim.x - 1; k++) {
        int j = jStart + k - threadIdx.x;
        if (jStart <= j && j < jStart + blockDim.x && i < len1 && j < len2) {

            CellDecision current;
            if (fixedTop) {
                current = decideCellNW(
                    decisions[i*(len2+1) + j].score + match(seq1_symbol, seq2[j]),
                    decisions[i*(len2+1) + (j+1)].score + GAP_PENALTY,
                    decisions[(i+1)*(len2+1) + j].score + GAP_PENALTY
                );
            }
            else {
                current = decideCellSW(
                    decisions[i*(len2+1) + j].score + match(seq1_symbol, seq2[j]),
                    decisions[i*(len2+1) + (j+1)].score + GAP_PENALTY,
                    decisions[(i+1)*(len2+1) + j].score + GAP_PENALTY
                );
            }
            decisions[(i+1)*(len2+1) + (j+1)] = current;

            if (current.score > bestScores[i]) {
                bestScores[i] = current.score;
                bestJ[i] = j + 1;
            }
        }
        __syncthreads();
    }

    // Find maximum score from this block, if this is rightmost block
    // Using tricks from https://developer.download.nvidia.com/assets/cuda/files/reduction.pdf
    if (jStart + blockDim.x >= len2) {
        // Pull in previous best
        if (threadIdx.x == 0 && i != 0) {
            if (bestScores[i] < bestScores[i - blockDim.x]) {
                bestScores[i] = bestScores[i - blockDim.x];
                bestI[i] = bestI[i - blockDim.x];
                bestJ[i] = bestJ[i - blockDim.x];
            }
        }

        // Find best in this block
        for (unsigned int s= blockDim.x / 2; s > 0; s >>= 1) {
            if (threadIdx.x < s && i + s < len1) {
                if (bestScores[i] < bestScores[i + s]) {
                    bestScores[i] = bestScores[i + s];
                    bestI[i] = bestI[i + s];
                    bestJ[i] = bestJ[i + s];
                }
            }
            __syncthreads();
        }
    }

    // Bring best values to front of array, if last block
    if (threadIdx.x == 0 && i + blockDim.x >= len1) {
        bestScores[0] = bestScores[i];
        bestScores[1] = bestI[i];
        bestScores[2] = bestJ[i];
    }
}

AlignedPair* sw(cudaStream_t stream, char *seq1, unsigned long len1, char *seq2, unsigned long len2,
    bool fixedTop, bool fixedBottom) {

    unsigned long gridSpace = (len1+1) * (len2+1) * sizeof(CellDecision);

    AlignedPair* alignedPair;
    cudaMallocManaged(&alignedPair, sizeof(AlignedPair));
    char* aligned1;
    cudaMallocManaged(&aligned1, (len1 + len2 + 1) * sizeof(char));
    alignedPair->seq1 = aligned1;
    char* aligned2;
    cudaMallocManaged(&aligned2, (len1 + len2 + 1) * sizeof(char));
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

    CellDecision* decisions;
    cudaMalloc(&decisions, gridSpace);

    int* bestScores;
    cudaMalloc(&bestScores, max(len1, 3L) * sizeof(int));
    cudaMemset(bestScores, 0, max(len1, 3L) * sizeof(int));
    int* bestI;
    cudaMalloc(&bestI, len1 * sizeof(int));
    int* bestJ;
    cudaMalloc(&bestJ, len1 * sizeof(int));

    int threadCount = MAX_THREADS;
    int blockCount = (len1 - 1)/threadCount + 1;
    int gridWidth = (len2 - 1)/threadCount + 1;

    // Using abitrary number of threads, ideally len1 >= len2

    if (fixedTop) {
        for (unsigned long gridK = 0; gridK < blockCount + gridWidth - 1; gridK++) {
            sw_device<true><<<blockCount, threadCount, 0, stream>>>(
                decisions, bestScores, bestI, bestJ, gridK,
                seq1, len1, seq2, len2
            );

            cudaStreamSynchronize(stream);
        }
    }
    else {
        for (unsigned long gridK = 0; gridK < blockCount + gridWidth - 1; gridK++) {
            sw_device<false><<<blockCount, threadCount, 0, stream>>>(
                decisions, bestScores, bestI, bestJ, gridK,
                seq1, len1, seq2, len2
            );

            cudaStreamSynchronize(stream);
        }
    }

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

template<bool fixedEnd>
__global__
void swlSolve_MultiBlock_device(bool backwards, int* previousLefts, int* previousTops,
    int* lastDiags, int gridK,
    char *seq1, unsigned long len1, char *seq2, unsigned long len2, int* bestScores, int* bestI, int* bestJ) {

    // halvedLen1 (i) rows by Len2 (j) columns
    extern __shared__ int previous [];

    int halvedLen1 = (len1+1) / 2;

    int gridRow = blockIdx.x;
    // Forwards and backwards in the same kernel but they are unrelated and work on different memory
    int gridColTarget = backwards ? len1 - halvedLen1 : halvedLen1;

    int j = threadIdx.x + gridRow * blockDim.x;
    int iStart = (gridK - gridRow) * blockDim.x;

    if (iStart < 0 || iStart >= gridColTarget) {
        return;
    }

    int* lastTop = previousTops + iStart;

    if (iStart == 0 && j < len2) {
        bestJ[j] = j + 1;
        if(threadIdx.x == 0) lastDiags[gridRow] = fixedEnd ? j * GAP_PENALTY : 0;
        previousLefts[j] = fixedEnd ? (j+1) * GAP_PENALTY : 0;
    }
    __syncthreads();

    int prevDiag;

    // Initialise top row if this is top of grid
    // If len2 < halvedLen1 this may be the only useful work a thread does on an boundary grid cell
    if (gridRow == 0 && j + iStart < gridColTarget) {
        previousTops[j + iStart] = fixedEnd ? (iStart + j + 1) * GAP_PENALTY : 0;
    }

    char seq2_symbol = '\0';
    if (j < len2) {
        seq2_symbol = backwards ? seq2[len2 - 1 - j] : seq2[j];

        if (gridRow == 0) {
            prevDiag = threadIdx.x == 0 ? (fixedEnd ? iStart * GAP_PENALTY : 0) : previousLefts[j-1];
        }
        else if (threadIdx.x == 0) { // Top of a block
            prevDiag = lastDiags[gridRow];
            if (((gridK - gridRow) +1) * blockDim.x < gridColTarget)
                lastDiags[gridRow] = lastTop[blockDim.x - 1];
        }
        else {
            prevDiag = previousLefts[j-1];
        }

        if (threadIdx.x == 0) {
            previous[0] = lastTop[0];
            previous[1] = previousLefts[j];
        }

    }
    __syncthreads();

    int current = 0;
    for (unsigned long k = 0; k < 2*blockDim.x - 1; k++) {
        int i = iStart + k - threadIdx.x;

        if (iStart <= i && i < iStart + blockDim.x &&
            j < len2 && i < gridColTarget) {

            if (i == iStart)
                previous[threadIdx.x+1] = previousLefts[j];

            int matchScore = backwards ? match(seq1[len1 - 1 - i], seq2_symbol)
                                       : match(seq1[i], seq2_symbol);
            if (fixedEnd) {
                current = decideCellNW(
                    prevDiag + matchScore,
                    previous[threadIdx.x+1] + GAP_PENALTY,
                    previous[threadIdx.x] + GAP_PENALTY
                ).score;
            }
            else {
                current = decideCellSW(
                    prevDiag + matchScore,
                    previous[threadIdx.x+1] + GAP_PENALTY,
                    previous[threadIdx.x] + GAP_PENALTY
                ).score;
            }

            if (current > bestScores[j]) {
                bestScores[j] = current;
                bestI[j] = backwards ? len1 - 1 - i : i + 1;
            }

            if (threadIdx.x == blockDim.x - 1) {
                previousTops[i] = current;
            }
            prevDiag = previous[threadIdx.x];

        }
        __syncthreads();
        previous[threadIdx.x + 1] = current;
        if (threadIdx.x == 0 && iStart <= i && i < iStart + blockDim.x - 1 && j < len2 && i < gridColTarget -1) {
            previous[0] = lastTop[k+1];
        }
        __syncthreads();
    }

    if (j <= len2) previousLefts[j] = current;

    // Find maximum score from this block, if this is rightmost block
    // Using tricks from https://developer.download.nvidia.com/assets/cuda/files/reduction.pdf
    if (iStart + blockDim.x >= gridColTarget) {
        // Pull in previous best
        if (threadIdx.x == 0 && j != 0) {
            if (bestScores[j] < bestScores[j - blockDim.x]) {
                bestScores[j] = bestScores[j - blockDim.x];
                bestI[j] = bestI[j - blockDim.x];
                bestJ[j] = bestJ[j - blockDim.x];
            }
        }

        // Find best in this block
        for (unsigned int s= blockDim.x / 2; s > 0; s >>= 1) {
            if (threadIdx.x < s && j + s < len2) {
                if (bestScores[j] < bestScores[j + s]) {
                    bestScores[j] = bestScores[j + s];
                    bestI[j] = bestI[j + s];
                    bestJ[j] = bestJ[j + s];
                }
            }
            __syncthreads();
        }
    }

    // Bring best values to front of array, if last block
    if (threadIdx.x == 0 && j + blockDim.x >= len2) {
        bestScores[0] = bestScores[j];
        bestScores[1] = bestI[j];
        bestScores[2] = bestJ[j];

        previousLefts[-1] = fixedEnd ? halvedLen1 * GAP_PENALTY : 0;
    }

    __syncthreads();
}

template <bool fixedEnd>
void* swlSolve_MultiBlock(void* swlSolveArgs) {
    SwlSolveArgs args = *((SwlSolveArgs *) swlSolveArgs);

    // blockIdx.x = 0 ==> forwards; 1 ==> backwards

    int halvedLen1 = (args.len1 +1)/2;
    halvedLen1 = args.backwards ? args.len1 - halvedLen1 : halvedLen1;

    int threadCount = MAX_THREADS;
    int blockCount = (args.len2 - 1)/threadCount + 1;
    int gridWidth = (halvedLen1 - 1)/threadCount + 1;

    // // Indexed by it's column
    int* previousLefts;
    cudaMalloc(&previousLefts, sizeof(int) * (args.len2 +2));
    int* previousTops;
    cudaMalloc(&previousTops, sizeof(int) * halvedLen1);
    int* lastDiags;
    cudaMalloc(&lastDiags, sizeof(int) * blockCount); // bit of an over estimate len2 > len1/2

    int* bestScores;
    cudaMalloc(&bestScores, args.len1 * sizeof(int));
    cudaMemset(bestScores, 0, args.len1 * sizeof(int));
    int* bestI;
    cudaMalloc(&bestI, args.len1 * sizeof(int));
    int* bestJ;
    cudaMalloc(&bestJ, args.len1 * sizeof(int));


    for (unsigned long gridK = 0; gridK < blockCount + gridWidth - 1; gridK++) {
        swlSolve_MultiBlock_device<fixedEnd><<<blockCount, threadCount, (threadCount+1)*sizeof(int), args.stream>>>(
            args.backwards,
            previousLefts+1, previousTops, lastDiags, gridK,
            args.seq1, args.len1, args.seq2, args.len2,
            bestScores, bestI, bestJ
        );

        cudaStreamSynchronize(args.stream);
    }


    BestCell bestCell = (BestCell){0, 0, 0};
    cudaMemcpy(&bestCell, bestScores, 3 * sizeof(int), cudaMemcpyDeviceToHost);

    cudaFree(previousTops);
    cudaFree(lastDiags);
    cudaFree(bestScores);
    cudaFree(bestI);
    cudaFree(bestJ);

    ScoresWithBest* ret = (ScoresWithBest*) malloc(sizeof(ScoresWithBest));
    *ret = (ScoresWithBest) {previousLefts, bestCell};
    return ret;
}

__global__
void add_and_maximise(int* topToMidScores, int* midToBottomScores, int len,
    int* bestScore, int* bestPos
) {

    extern __shared__ int bestScores [];
    int* bestPoses = bestScores + blockDim.x;

    bestScores[threadIdx.x] = INT_MIN;
    bestPoses[threadIdx.x] = 0;
    // The maths here is a bit funky because of the clunky way I've indexed things
    for (unsigned long i = threadIdx.x; i <= len; i += blockDim.x) {
        midToBottomScores[i] += topToMidScores[len - i];
        if (midToBottomScores[i] > bestScores[threadIdx.x]) {
            bestScores[threadIdx.x] = midToBottomScores[i];
            bestPoses[threadIdx.x] = len - i;
        }
    }

    __syncthreads();

    // Find best in this block
    for (unsigned int s= blockDim.x / 2; s > 0; s >>= 1) {
        if (threadIdx.x < s && threadIdx.x + s <= len) {
            if (bestScores[threadIdx.x] < bestScores[threadIdx.x + s]) {
                bestScores[threadIdx.x] = bestScores[threadIdx.x + s];
                bestPoses[threadIdx.x] = bestPoses[threadIdx.x + s];
            }
        }
        __syncthreads();
    }

    // Bring best values to front of array, if last block
    if (threadIdx.x == 0) {
        *bestScore = bestScores[0];
        *bestPos = bestPoses[0];
    }
}

void* swLinear(void* args) {
    SWSequencePairWithStream sp = *((SWSequencePairWithStream *) args);
    cudaStreamSynchronize(sp.stream);

    // If it's easy, just do it directly
    // Also dodges nasty edge cases like trying to halve 1
    if ((sp.len1 < BOTH_MIN_LENGTH && sp.len2 < BOTH_MIN_LENGTH)
            || sp.len1 < ABSOLUTE_MIN_LENGTH || sp.len2 < ABSOLUTE_MIN_LENGTH) {
        return sw(sp.stream, sp.seq1, sp.len1, sp.seq2, sp.len2, sp.fixedTop, sp.fixedBottom);
    }

    bool stringsSwapped = sp.len1 < sp.len2;
    if (stringsSwapped) {
        char* tmp_s = sp.seq1;
        sp.seq1 = sp.seq2;
        sp.seq2 = tmp_s;

        unsigned long tmp_l = sp.len1;
        sp.len1 = sp.len2;
        sp.len2 = tmp_l;
    }

    pthread_t top_grid_thread;
    cudaStream_t stream;
    cudaStreamCreate(&stream);
    pthread_t bottom_grid_thread;

    SwlSolveArgs topToMidArgs = {sp.stream, false, sp.seq1, sp.len1, sp.seq2, sp.len2};
    ScoresWithBest* topToMidResult;
    if (sp.fixedTop) {
        pthread_create(&top_grid_thread, NULL, swlSolve_MultiBlock<true>, (void *)&topToMidArgs);
    }
    else {
        pthread_create(&top_grid_thread, NULL, swlSolve_MultiBlock<false>, (void *)&topToMidArgs);
    }
    pthread_join(top_grid_thread, (void **) &topToMidResult);


    SwlSolveArgs midToBottomArgs = {stream, true, sp.seq1, sp.len1, sp.seq2, sp.len2};
    ScoresWithBest* midToBottomResult;
    if (sp.fixedBottom) {
        pthread_create(&bottom_grid_thread, NULL, swlSolve_MultiBlock<true>, (void *)&midToBottomArgs);
    }
    else {
        pthread_create(&bottom_grid_thread, NULL, swlSolve_MultiBlock<false>, (void *)&midToBottomArgs);
    }
    pthread_join(bottom_grid_thread, (void **) &midToBottomResult);


    int* topToMidScores = topToMidResult->scores;
    int* midToBottomScores = midToBottomResult->scores;
    BestCell bestForwards = topToMidResult->bestCell;
    BestCell bestBackwards = midToBottomResult->bestCell;

    free(topToMidResult);
    free(midToBottomResult);

    // Find the best point to cross the middle vector at

    int* bestMiddleScorePtr;
    cudaMallocManaged(&bestMiddleScorePtr, sizeof(int));
    int* bestPosPtr;
    cudaMallocManaged(&bestPosPtr, sizeof(int));

    add_and_maximise<<<1, MAX_THREADS, (MAX_THREADS)*sizeof(int)*2, sp.stream>>>(
        topToMidScores, midToBottomScores, sp.len2,
        bestMiddleScorePtr, bestPosPtr
    );
    cudaStreamSynchronize(sp.stream);

    int bestMiddleScore = *bestMiddleScorePtr;
    int bestPos = *bestPosPtr;
    cudaFree(bestMiddleScorePtr);
    cudaFree(bestPosPtr);
    cudaFree(topToMidScores);
    cudaFree(midToBottomScores);

    AlignedPair* alignedPair;
    if ((!sp.fixedBottom && bestForwards.score >= bestMiddleScore) && (sp.fixedTop || bestForwards.score >= bestBackwards.score)) {
        SWSequencePairWithStream topOnlyArgs = (SWSequencePairWithStream) {
            sp.seq1, bestForwards.i,
            sp.seq2, bestForwards.j,
            sp.fixedTop, true,
            sp.stream
        };

        alignedPair = (AlignedPair*) swLinear(&topOnlyArgs);
    }
    else if ((!sp.fixedTop && bestBackwards.score >= bestMiddleScore) && (sp.fixedBottom || bestBackwards.score >= bestForwards.score)) {
        SWSequencePairWithStream bottomOnlyArgs = (SWSequencePairWithStream) {
            sp.seq1 + bestBackwards.i, sp.len1 - bestBackwards.i,
            sp.seq2 + sp.len2 - bestBackwards.j, bestBackwards.j,
            true, sp.fixedBottom,
            sp.stream
        };

        alignedPair = (AlignedPair*) swLinear(&bottomOnlyArgs);
    }
    else {
        // Solve sub-matrices
        // Top left: solve from current top-left cell down to and including the 'best' crossing cell
        // Reusing this stream
        SWSequencePairWithStream topSequences = (SWSequencePairWithStream) {
            sp.seq1, (sp.len1 + 1)/2,
            sp.seq2, (unsigned long)bestPos,
            sp.fixedTop, true,
            sp.stream
        };

        AlignedPair* topPath;
        pthread_create(&top_grid_thread, NULL, swLinear, (void *)&topSequences);

        // New stream for other segment

        // Bottom right: solve from the bottom-right diagonal of the 'best' crossing cell,
        // exploiting NW which always goes to the absolute top-left to the current bottom-right cell
        SWSequencePairWithStream bottomSequences = (SWSequencePairWithStream) {
            sp.seq1 + (sp.len1 + 1) / 2, sp.len1 - (sp.len1 + 1) / 2,
            sp.seq2 + bestPos, sp.len2 - bestPos,
            true, sp.fixedBottom,
            stream
        };

        AlignedPair* bottomPath;
        pthread_create(&bottom_grid_thread, NULL, swLinear, (void *)&bottomSequences);

        pthread_join(top_grid_thread, (void **) &topPath);
        pthread_join(bottom_grid_thread, (void **) &bottomPath);

        cudaMallocManaged(&alignedPair, sizeof(AlignedPair));
        char* aligned1;
        cudaMallocManaged(&aligned1, (topPath->len + bottomPath->len + 1) * sizeof(char));
        alignedPair->seq1 = aligned1;
        char* aligned2;
        cudaMallocManaged(&aligned2, (topPath->len + bottomPath->len + 1) * sizeof(char));
        alignedPair->seq2 = aligned2;

        aligned1[0] = '\0';
        aligned2[0] = '\0';

        alignedPair->len = topPath->len + bottomPath->len;

        strcat(alignedPair->seq1, topPath->seq1);
        strcat(alignedPair->seq1, bottomPath->seq1);

        strcat(alignedPair->seq2, topPath->seq2);
        strcat(alignedPair->seq2, bottomPath->seq2);

        cudaFree(topPath->seq1);
        cudaFree(topPath->seq2);
        cudaFree(topPath);
        cudaFree(bottomPath->seq1);
        cudaFree(bottomPath->seq2);
        cudaFree(bottomPath);
    }

    cudaStreamDestroy(stream);

    if (stringsSwapped) {
        char* tmp_s = alignedPair->seq1;
        alignedPair->seq1 = alignedPair->seq2;
        alignedPair->seq2 = tmp_s;
    }

    return alignedPair;
}
