#include <stdio.h>
#include <pthread.h>

#include "helpers.cuh"
#include "sw.cuh"
#include "swGotoh.cuh"

using namespace std;

typedef struct {
    int* scores;
    int* vertical;
    BestCell bestCell;
} GotohScoresWithBest;

typedef struct {
    CellDecision** decisions;
    GapDecision** horizontal;
    GapDecision** vertical;
} GotohGrids;

__device__
GapDecision decideGap(int startScore, int extendScore) {
    if (startScore <= extendScore) {
        return (GapDecision) {extendScore, GapExtend};
    }
    else {
        return (GapDecision) {startScore, GapStart};
    }
}

template<bool fixedTop>
__global__
void sw_gotoh_device(CellDecision* decisions, GapDecision* vertical, GapDecision* horizontal,
    bool verticalGapStarted, bool horizontalGapStarted,
    int* bestScores, int* bestI, int* bestJ,
    int gridK,
    char *seq1, unsigned long len1, char *seq2, unsigned long len2) {


    // Len1 (i) rows by Len2 (j) columns
    int gridRow = blockIdx.x;
    int i = threadIdx.x + gridRow * blockDim.x;
    int jStart = (gridK - gridRow) * blockDim.x;

    if (jStart < 0 || jStart >= len2) {
        return;
    }

    if (gridRow == 0) {
        if (jStart + threadIdx.x < len2) {
            if (fixedTop) {
                int thisGapValue = (jStart + (int)threadIdx.x) * GAP_EXTEND;
                thisGapValue += horizontalGapStarted ? GAP_EXTEND : GAP_START;

                decisions[jStart + threadIdx.x + 1] = (CellDecision) {thisGapValue, Left};
                horizontal[jStart + threadIdx.x + 1] = (GapDecision) {thisGapValue, GapExtend};
                vertical[jStart + threadIdx.x + 1] = (GapDecision) {thisGapValue + GAP_START, GapStart};
            }
            else {
                decisions[jStart + threadIdx.x + 1] = (CellDecision) {0, Nil};
                horizontal[jStart + threadIdx.x + 1] = (GapDecision) {GAP_START, GapStart};
                vertical[jStart + threadIdx.x + 1] = (GapDecision) {GAP_START, GapStart};
            }
        }
    }

    if (jStart == 0 && i < len1) {
        bestI[i] = i + 1;
        if (fixedTop) {
            int thisGapValue = i * GAP_EXTEND;
            thisGapValue += verticalGapStarted ? GAP_EXTEND : GAP_START;

            decisions[(i+1) * (len2+1)] = (CellDecision) {thisGapValue, Above};
            vertical[(i+1) * (len2+1)] = (GapDecision) {thisGapValue, GapExtend};
            horizontal[(i+1) * (len2+1)] = (GapDecision) {thisGapValue + GAP_START, GapExtend};
        }
        else {
            decisions[(i+1) * (len2+1)] = (CellDecision) {0, Nil};
            vertical[(i+1) * (len2+1)] = (GapDecision) {GAP_START, GapStart};
            horizontal[(i+1) * (len2+1)] = (GapDecision) {GAP_START, GapStart};
        }
    }

    if(threadIdx.x == 0 && jStart == 0) {
        decisions[0] = (CellDecision) {0, Nil};
        horizontal[1].gap = GapStart;
        vertical[(len2+1)].gap = GapStart;
    }

    __syncthreads();

    char seq1_symbol = '\0';
    if (i < len1)
        seq1_symbol = seq1[i];

    // Fill in this block
    for (unsigned long k = 0; k < 2*blockDim.x - 1; k++) {
        int j = jStart + k - threadIdx.x;
        if (jStart <= j && j < jStart + blockDim.x && i < len1 && j < len2) {
            GapDecision currentVertical = decideGap(
                decisions[i*(len2+1) + (j+1)].score + GAP_START,
                vertical[i*(len2+1) + (j+1)].score + GAP_EXTEND
            );
            GapDecision currentHorizontal = decideGap(
                decisions[(i+1)*(len2+1) + j].score + GAP_START,
                horizontal[(i+1)*(len2+1) + j].score + GAP_EXTEND
            );

            CellDecision currentScore;
            if (fixedTop) {
                currentScore = decideCellNW(
                    decisions[i*(len2+1) + j].score + match(seq1_symbol, seq2[j]),
                    currentVertical.score,
                    currentHorizontal.score
                );
            }
            else {
                currentScore = decideCellSW(
                    decisions[i*(len2+1) + j].score + match(seq1_symbol, seq2[j]),
                    currentVertical.score,
                    currentHorizontal.score
                );
            }
            decisions[(i+1)*(len2+1) + (j+1)] = currentScore;
            vertical[(i+1)*(len2+1) + (j+1)] = currentVertical;
            horizontal[(i+1)*(len2+1) + (j+1)] = currentHorizontal;

            if (currentScore.score > bestScores[i]) {
                bestScores[i] = currentScore.score;
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

AlignedPair* sw_gotoh(cudaStream_t stream, char *seq1, unsigned long len1, char *seq2, unsigned long len2,
    bool fixedTop, bool fixedBottom, bool verticalGapStarted, bool horizontalGapStarted,
    bool forceBottomVerticalGap, bool forceBottomHorizontalGap) {

    unsigned long gridSpace = (len1+1) * (len2+1) * sizeof(CellDecision);
    unsigned long gridSpaceGap = (len1+1) * (len2+1) * sizeof(GapDecision);

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
    GapDecision* vertical;
    cudaMalloc(&vertical, gridSpaceGap);
    GapDecision* horizontal;
    cudaMalloc(&horizontal, gridSpaceGap);

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

    // Using abitrary threads, ideally len1 >= len2

    if (fixedTop) {
        for (unsigned long gridK = 0; gridK < blockCount + gridWidth - 1; gridK++) {
            sw_gotoh_device<true><<<blockCount, threadCount, 0, stream>>>(
                decisions, vertical, horizontal,verticalGapStarted, horizontalGapStarted,
                bestScores, bestI, bestJ, gridK,
                seq1, len1, seq2, len2
            );

            cudaStreamSynchronize(stream);
        }
    }
    else {
        for (unsigned long gridK = 0; gridK < blockCount + gridWidth - 1; gridK++) {
            sw_gotoh_device<false><<<blockCount, threadCount, 0, stream>>>(
                decisions, vertical, horizontal,verticalGapStarted, horizontalGapStarted,
                bestScores, bestI, bestJ, gridK,
                seq1, len1, seq2, len2
            );

            cudaStreamSynchronize(stream);
        }
    }

    BestCell bestCell = (BestCell){0, 0, 0};
    cudaMemcpy(&(bestCell.score), bestScores, sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(&(bestCell.i), bestScores+1, sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(&(bestCell.j), bestScores+2, sizeof(int), cudaMemcpyDeviceToHost);

    backtraceGotohRunner<<<1,1,0,stream>>>(seq1, len1, seq2, len2,
        decisions, vertical, horizontal,
        bestCell, fixedBottom, forceBottomVerticalGap, forceBottomHorizontalGap,
        alignedPair
    );
    cudaStreamSynchronize(stream);

    // printf("%s\n", aligned1);
    // printf("%s\n", aligned2);

    cudaFree(decisions);
    cudaFree(vertical);
    cudaFree(horizontal);
    cudaFree(bestScores);
    cudaFree(bestI);
    cudaFree(bestJ);

    return alignedPair;
}

template<bool fixedEnd>
__global__
void swl_gotoh_Solve_MultiBlock_device(bool shared, bool backwards,
    bool verticalGapStarted, bool horizontalGapStarted,
    int* previousLeftScores, int* previousTopScores,
    int* prevVertical, int* prevHorizontal,
    int* horizontal, int* lastDiagScores,
    int gridK,
    char *seq1, unsigned long len1, char *seq2, unsigned long len2, int* bestScores, int* bestI, int* bestJ) {

    // halvedLen1 (i) rows by Len2 (j) columns
    extern __shared__ int previous [];
    if (shared) horizontal = previous + blockDim.x + 1;

    int halvedLen1 = (len1+1) / 2;

    // gridCol2 = (gridK - blockIdx.x)
    int gridRow = blockIdx.x;
    // Forwards and backwards in the same kernel but they are unrelated and work on different memory
    int gridColTarget = backwards ? len1 - halvedLen1 : halvedLen1;

    int j = threadIdx.x + gridRow * blockDim.x;
    int iStart = (gridK - gridRow) * blockDim.x;

    if (iStart < 0 || iStart >= gridColTarget) {
        return;
    }

    int* lastTopScore = previousTopScores + iStart;
    // int* lastTopVertical = previousTopVerticals + iStart;
    int* lastHorizontal = prevHorizontal + iStart;

    //for (int gridRow2 = 0; gridRow2 * blockDim.x < len2; gridRow2++) {

    if (iStart == 0 && j < len2) {
        bestJ[j] = j + 1;

        if (fixedEnd) {
            int thisGapValue = (j-1)*GAP_EXTEND;
            thisGapValue += horizontalGapStarted ? GAP_EXTEND : GAP_START;
            if(threadIdx.x == 0) {
                lastDiagScores[gridRow] = (j == 0) ? 0 : thisGapValue;
            }
            previousLeftScores[j] = thisGapValue + GAP_EXTEND;
            prevVertical[j] = thisGapValue + GAP_START;
        }
        else {
            if(threadIdx.x == 0) {
                lastDiagScores[gridRow] = 0;
            }
            previousLeftScores[j] = 0;
            prevVertical[j] = GAP_START;
        }
    }
    __syncthreads();

    int prevDiag;

    // Initialise top row if this is top of grid
    // If len2 < halvedLen1 this may be the only useful work a thread does on an boundary grid cell
    if (j + iStart < gridColTarget) {
        if (gridRow == 0) {
            int thisGapValue = (iStart + j + 1)*GAP_EXTEND;
            thisGapValue += verticalGapStarted ? GAP_EXTEND : GAP_START;
            if (fixedEnd) {
                previousTopScores[j + iStart] = thisGapValue;
                prevHorizontal[j + iStart] = thisGapValue + GAP_START;
            }
            else {
                previousTopScores[j + iStart] = 0;
                prevHorizontal[j + iStart] = GAP_START;
            }
        }
    }

    char seq2_symbol = '\0';
    if (j < len2) {
        seq2_symbol = backwards ? seq2[len2 - 1 - j] : seq2[j];

        if (threadIdx.x == 0) { // Top of a block
            prevDiag = lastDiagScores[gridRow];
            if (((gridK - gridRow) +1) * blockDim.x < gridColTarget)
                lastDiagScores[gridRow] = lastTopScore[blockDim.x - 1];
        }
        else {
            prevDiag = previousLeftScores[j-1];
        }

        if (threadIdx.x == 0) {
            previous[0] = lastTopScore[0];
            previous[1] = previousLeftScores[j];
            horizontal[0] = lastHorizontal[0];
        }
    }
    __syncthreads();

    int current = 0;
    int currentVertical = 0;
    int currentHorizontal = 0;
    for (unsigned long k = 0; k < 2*blockDim.x - 1; k++) {
        int i = iStart + k - threadIdx.x;

        if (iStart <= i && i < iStart + blockDim.x &&
            j < len2 && i < gridColTarget) {

                if (i == iStart) {
                    previous[threadIdx.x+1] = previousLeftScores[j];
                    currentVertical = prevVertical[j];
                }
                currentVertical = decideGap(
                    previous[threadIdx.x+1] + GAP_START,
                    currentVertical + GAP_EXTEND
                ).score;
                currentHorizontal = decideGap(
                    previous[threadIdx.x] + GAP_START,
                    horizontal[threadIdx.x] + GAP_EXTEND
                ).score;

                int matchScore = backwards ? match(seq1[len1 - 1 - i], seq2_symbol)
                : match(seq1[i], seq2_symbol);
                if (fixedEnd) {
                    current = decideCellNW(
                        prevDiag + matchScore,
                        currentVertical,
                        currentHorizontal
                    ).score;
                }
                else {
                    current = decideCellSW(
                        prevDiag + matchScore,
                        currentVertical,
                        currentHorizontal
                    ).score;
                }
            if (current > bestScores[j]) {
                bestScores[j] = current;
                bestI[j] = backwards ? len1 - 1 - i : i + 1;
            }

            if (threadIdx.x == blockDim.x - 1) {
                previousTopScores[i] = current;
            }
            prevDiag = previous[threadIdx.x];
        }
        __syncthreads();
        previous[threadIdx.x + 1] = current;
        horizontal[threadIdx.x + 1] = currentHorizontal;

        if (threadIdx.x == 0 && iStart <= i && i < iStart + blockDim.x - 1 && j < len2 && i < gridColTarget -1) {
            previous[0] = lastTopScore[k+1];
            horizontal[threadIdx.x] = lastHorizontal[k+1];
        }
        __syncthreads();
    }

    if (j <= len2) {
        previousLeftScores[j] = current;
        prevVertical[j] = currentVertical;
    }
    if (j + iStart < gridColTarget) {
        prevHorizontal[j + iStart] = currentHorizontal;
    }

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

        int gapValue = ((verticalGapStarted ? GAP_EXTEND : GAP_START) + (halvedLen1-1) * GAP_EXTEND);
        previousLeftScores[-1] = fixedEnd ? halvedLen1 * GAP_PENALTY : 0;
        prevVertical[-1] = gapValue;
    }
    __syncthreads();
}

template <bool fixedEnd>
void* swl_gotoh_Solve_MultiBlock(void* swlGotohSolveArgs) {
    SwlGotohSolveArgs args = *((SwlGotohSolveArgs *) swlGotohSolveArgs);

    // blockIdx.x = 0 ==> forwards; 1 ==> backwards

    int halvedLen1 = (args.len1 +1)/2;
    halvedLen1 = args.backwards ? args.len1 - halvedLen1 : halvedLen1;

    int threadCount = MAX_THREADS;
    int blockCount = (args.len2 - 1)/threadCount + 1;
    int gridWidth = (halvedLen1 - 1)/threadCount + 1;

    int shared_size = (threadCount+1+(halvedLen1+1))*sizeof(int);
    bool shared = true;
    int* horizontal = NULL;
    if (shared_size > SHARED_MEMORY_LIMIT) {
        shared = false;
        shared_size = (threadCount+1)*sizeof(int);
        cudaMalloc(&horizontal, sizeof(int) * (halvedLen1 + 1));
    }

    bool verticalGapStarted = args.backwards ? args.gapBottom : args.gapTop;
    bool horizontalGapStarted = args.backwards ? args.gapRight : args.gapLeft;

    // // Indexed by it's column
    int* previousLefts;
    cudaMalloc(&previousLefts, sizeof(int) * (args.len2 +2));
    int* prevVertical;
    cudaMalloc(&prevVertical, sizeof(int) * (args.len2 +2));
    int* previousTops;
    cudaMalloc(&previousTops, sizeof(int) * halvedLen1);
    int* prevHorizontal;
    cudaMalloc(&prevHorizontal, sizeof(int) * halvedLen1);
    int* lastDiagScores;
    cudaMalloc(&lastDiagScores, sizeof(int) * blockCount); // bit of an over estimate len2 > len1/2

    int* bestScores;
    cudaMalloc(&bestScores, args.len1 * sizeof(int));
    cudaMemset(bestScores, 0, args.len1 * sizeof(int));
    int* bestI;
    cudaMalloc(&bestI, args.len1 * sizeof(int));
    int* bestJ;
    cudaMalloc(&bestJ, args.len1 * sizeof(int));


    for (unsigned long gridK = 0; gridK < blockCount + gridWidth - 1; gridK++) {
        swl_gotoh_Solve_MultiBlock_device<fixedEnd><<<blockCount, threadCount, shared_size, args.stream>>>(
            shared, args.backwards, verticalGapStarted, horizontalGapStarted,
            previousLefts+1, previousTops,
            prevVertical+1, prevHorizontal,
            horizontal, lastDiagScores,
            gridK,
            args.seq1, args.len1, args.seq2, args.len2,
            bestScores, bestI, bestJ
        );

        cudaStreamSynchronize(args.stream);
    }

    BestCell bestCell = (BestCell){0, 0, 0};
    cudaMemcpy(&bestCell, bestScores, 3 * sizeof(int), cudaMemcpyDeviceToHost);

    cudaFree(bestScores);
    cudaFree(bestI);
    cudaFree(bestJ);
    cudaFree(previousTops);
    cudaFree(prevHorizontal);
    cudaFree(lastDiagScores);

    GotohScoresWithBest* ret = (GotohScoresWithBest*) malloc(sizeof(GotohScoresWithBest));
    *ret = (GotohScoresWithBest) {previousLefts, prevVertical, bestCell};
    return ret;
}

void* swGotohLinear(void* args) {
    SWGotohSequencePairWithStream sp = *((SWGotohSequencePairWithStream *) args);
    cudaStreamSynchronize(sp.stream);

    // If it's easy, just do it directly
    // Also dodges nasty edge cases like trying to halve 1
    if ((sp.len1 < BOTH_MIN_LENGTH && sp.len2 < BOTH_MIN_LENGTH)
            || sp.len1 < ABSOLUTE_MIN_LENGTH || sp.len2 < ABSOLUTE_MIN_LENGTH) {
        return sw_gotoh(sp.stream, sp.seq1, sp.len1, sp.seq2, sp.len2, sp.fixedTop, sp.fixedBottom,
            sp.gapTop, sp.gapLeft, sp.gapBottom, sp.gapRight);
    }

    bool stringsSwapped = sp.len1 < sp.len2;
    if (stringsSwapped) {
        char* tmp_s = sp.seq1;
        sp.seq1 = sp.seq2;
        sp.seq2 = tmp_s;

        unsigned long tmp_l = sp.len1;
        sp.len1 = sp.len2;
        sp.len2 = tmp_l;

        bool temp_b = sp.gapTop;
        sp.gapTop = sp.gapLeft;
        sp.gapLeft = temp_b;

        temp_b = sp.gapBottom;
        sp.gapBottom = sp.gapRight;
        sp.gapRight = temp_b;
    }

    pthread_t top_grid_thread;
    cudaStream_t stream;
    cudaStreamCreate(&stream);
    pthread_t bottom_grid_thread;

    SwlGotohSolveArgs topToMidArgs = {sp.stream, false,
        sp.gapTop, sp.gapBottom, sp.gapLeft,sp.gapRight,
        sp.seq1, sp.len1, sp.seq2, sp.len2};
    GotohScoresWithBest* topToMidResult;
    if (sp.fixedTop) {
        pthread_create(&top_grid_thread, NULL, swl_gotoh_Solve_MultiBlock<true>, (void *)&topToMidArgs);
    }
    else {
        pthread_create(&top_grid_thread, NULL, swl_gotoh_Solve_MultiBlock<false>, (void *)&topToMidArgs);
    }
    pthread_join(top_grid_thread, (void **) &topToMidResult);

    SwlGotohSolveArgs midToBottomArgs = {stream, true,
        sp.gapTop, sp.gapBottom, sp.gapLeft,sp.gapRight,
        sp.seq1, sp.len1, sp.seq2, sp.len2};
    GotohScoresWithBest* midToBottomResult;
    if (sp.fixedBottom) {
        pthread_create(&bottom_grid_thread, NULL, swl_gotoh_Solve_MultiBlock<true>, (void *)&midToBottomArgs);
    }
    else {
        pthread_create(&bottom_grid_thread, NULL, swl_gotoh_Solve_MultiBlock<false>, (void *)&midToBottomArgs);
    }
    pthread_join(bottom_grid_thread, (void **) &midToBottomResult);

    int* topToMidScores = topToMidResult->scores;
    int* midToBottomScores = midToBottomResult->scores;
    int *midToBottomGapScore = midToBottomResult->vertical;
    int* midDownwardsGapScore = topToMidResult->vertical;
    BestCell bestForwards = topToMidResult->bestCell;
    BestCell bestBackwards = midToBottomResult->bestCell;

    free(topToMidResult);
    free(midToBottomResult);

    int* bestMiddleScorePtr;
    cudaMallocManaged(&bestMiddleScorePtr, sizeof(int));
    int* bestPosPtr;
    cudaMallocManaged(&bestPosPtr, sizeof(int));

    add_and_maximise<<<1, MAX_THREADS, (MAX_THREADS)*sizeof(int)*2, sp.stream>>>(
        topToMidScores, midToBottomScores, sp.len2,
        bestMiddleScorePtr, bestPosPtr
    );

    int* bestMiddleGapScorePtr;
    cudaMallocManaged(&bestMiddleGapScorePtr, sizeof(int));
    int* bestGapPosPtr;
    cudaMallocManaged(&bestGapPosPtr, sizeof(int));

    add_and_maximise<<<1, MAX_THREADS, (MAX_THREADS)*sizeof(int)*2, stream>>>(
        midDownwardsGapScore, midToBottomGapScore, sp.len2,
        bestMiddleGapScorePtr, bestGapPosPtr
    );

    cudaStreamSynchronize(sp.stream);
    cudaStreamSynchronize(stream);

    int bestMiddleScore = *bestMiddleScorePtr;
    int bestPos = *bestPosPtr;
    cudaFree(bestMiddleScorePtr);
    cudaFree(bestPosPtr);
    int bestMiddleGapScore = *bestMiddleGapScorePtr;
    int bestGapPos = *bestGapPosPtr;
    cudaFree(bestMiddleGapScorePtr);
    cudaFree(bestGapPosPtr);

    int overallMiddleBest = bestMiddleScore >= bestMiddleGapScore ? bestMiddleScore : bestMiddleGapScore;

    cudaFree(topToMidScores);
    cudaFree(midToBottomScores);
    cudaFree(midToBottomGapScore);
    cudaFree(midDownwardsGapScore);

    AlignedPair* alignedPair;
    if ((!sp.fixedBottom && bestForwards.score >= overallMiddleBest) && (sp.fixedTop || bestForwards.score >= bestBackwards.score)) {
        SWGotohSequencePairWithStream topOnlyArgs = (SWGotohSequencePairWithStream) {
            sp.seq1, bestForwards.i,
            sp.seq2, bestForwards.j,
            sp.fixedTop, true,
            sp.gapTop, false, sp.gapLeft, false,
            sp.stream
        };

        alignedPair = (AlignedPair*) swGotohLinear(&topOnlyArgs);
    }
    else if ((!sp.fixedTop && bestBackwards.score >= overallMiddleBest) && (sp.fixedBottom || bestBackwards.score >= bestForwards.score)) {
        SWGotohSequencePairWithStream bottomOnlyArgs = (SWGotohSequencePairWithStream) {
            sp.seq1 + bestBackwards.i, sp.len1 - bestBackwards.i,
            sp.seq2 + sp.len2 - bestBackwards.j, bestBackwards.j,
            true, sp.fixedBottom,
            false, sp.gapBottom, false, sp.gapRight,
            sp.stream
        };

        alignedPair = (AlignedPair*) swGotohLinear(&bottomOnlyArgs);
    }
    else {
        // Solve sub-matrices
        // Top left: solve from current top-left cell down to and including the 'best' crossing cell
        // Reusing this stream

        bool gapMiddle = bestMiddleGapScore > bestMiddleScore;
        bestPos = gapMiddle ? bestGapPos : bestPos;

        SWGotohSequencePairWithStream topSequences = (SWGotohSequencePairWithStream) {
            sp.seq1, (sp.len1 + 1)/2,
            sp.seq2, (unsigned long)bestPos,
            sp.fixedTop, true,
            sp.gapTop, gapMiddle, sp.gapLeft, false,
            sp.stream
        };

        AlignedPair* topPath;
        pthread_create(&top_grid_thread, NULL, swGotohLinear, (void *)&topSequences);

        // New stream for other segment

        // Bottom right: solve from the bottom-right diagonal of the 'best' crossing cell,
        // exploiting NW which always goes to the absolute top-left to the current bottom-right cell
        SWGotohSequencePairWithStream bottomSequences = (SWGotohSequencePairWithStream) {
            sp.seq1 + (sp.len1 + 1) / 2, sp.len1 - (sp.len1 + 1) / 2,
            sp.seq2 + bestPos, sp.len2 - bestPos,
            true, sp.fixedBottom,
            gapMiddle, sp.gapBottom, false, sp.gapRight,
            stream
        };

        AlignedPair* bottomPath;
        pthread_create(&bottom_grid_thread, NULL, swGotohLinear, (void *)&bottomSequences);

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
