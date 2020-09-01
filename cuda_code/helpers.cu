#include <stdio.h>

#include "helpers.cuh"

__device__
int match_direct(char a, char b) {
    if (a == b) {
        return ALIGN_GAIN;
    }
    else {
        return MISALIGN_PENALTY;
    }
}

int match_direct_host(char a, char b) {
    if (a == b) {
        return ALIGN_GAIN;
    }
    else {
        return MISALIGN_PENALTY;
    }
}

__constant__ int BLOSUM_50[26 * 26] =
/*A */  {5, -2, -1, -2, -1, -3,  0, -2, -1,  0, -1, -2, -1, -1,  0, -1, -1, -2,  1,  0,  0,  0, -3, -1, -2, -1,
/*B */  -2,  5, -3,  5,  1, -4, -1,  0, -4,  0,  0, -4, -3,  4,  0, -2,  0, -1,  0,  0,  0, -4, -5, -1, -3,  2,
/*C */  -1, -3, 13, -4, -3, -2, -3, -3, -2,  0, -3, -2, -2, -2,  0, -4, -3, -4, -1, -1,  0, -1, -5, -2, -3, -3,
/*D */  -2,  5, -4,  8,  2, -5, -1, -1, -4,  0, -1, -4, -4,  2,  0, -1,  0, -2,  0, -1,  0, -4, -5, -1, -3,  1,
/*E */  -1,  1, -3,  2,  6, -3, -3,  0, -4,  0,  1, -3, -2,  0,  0, -1,  2,  0, -1, -1,  0, -3, -3, -1, -2,  5,
/*F */  -3, -4, -2, -5, -3,  8, -4, -1,  0,  0, -4,  1,  0, -4,  0, -4, -4, -3, -3, -2,  0, -1,  1, -2,  4, -4,
/*G */   0, -1, -3, -1, -3, -4,  8, -2, -4,  0, -2, -4, -3,  0,  0, -2, -2, -3,  0, -2,  0, -4, -3, -2, -3, -2,
/*H */  -2,  0, -3, -1,  0, -1, -2, 10, -4,  0,  0, -3, -1,  1,  0, -2,  1,  0, -1, -2,  0, -4, -3, -1,  2,  0,
/*I */  -1, -4, -2, -4, -4,  0, -4, -4,  5,  0, -3,  2,  2, -3,  0, -3, -3, -4, -3, -1,  0,  4, -3, -1, -1, -3,
/**J*/   0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,
/*K */  -1,  0, -3, -1,  1, -4, -2,  0, -3,  0,  6, -3, -2,  0,  0, -1,  2,  3,  0, -1,  0, -3, -3, -1, -2,  1,
/*L */  -2, -4, -2, -4, -3,  1, -4, -3,  2,  0, -3,  5,  3, -4,  0, -4, -2, -3, -3, -1,  0,  1, -2, -1, -1, -3,
/*M */  -1, -3, -2, -4, -2,  0, -3, -1,  2,  0, -2,  3,  7, -2,  0, -3,  0, -2, -2, -1,  0,  1, -1, -1,  0, -1,
/*N */  -1,  4, -2,  2,  0, -4,  0,  1, -3,  0,  0, -4, -2,  7,  0, -2,  0, -1,  1,  0,  0, -3, -4, -1, -2,  0,
/**O*/   0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,
/*P */  -1, -2, -4, -1, -1, -4, -2, -2, -3,  0, -1, -4, -3, -2,  0, 10, -1, -3, -1, -1,  0, -3, -4, -2, -3, -1,
/*Q */  -1,  0, -3,  0,  2, -4, -2,  1, -3,  0,  2, -2,  0,  0,  0, -1,  7,  1,  0, -1,  0, -3, -1, -1, -1,  4,
/*R */  -2, -1, -4, -2,  0, -3, -3,  0, -4,  0,  3, -3, -2, -1,  0, -3,  1,  7, -1, -1,  0, -3, -3, -1, -1,  0,
/*S */   1,  0, -1,  0, -1, -3,  0, -1, -3,  0,  0, -3, -2,  1,  0, -1,  0, -1,  5,  2,  0, -2, -4, -1, -2,  0,
/*T */   0,  0, -1, -1, -1, -2, -2, -2, -1,  0, -1, -1, -1,  0,  0, -1, -1, -1,  2,  5,  0,  0, -3,  0, -2, -1,
/**U*/   0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,
/*V */   0, -4, -1, -4, -3, -1, -4, -4,  4,  0, -3,  1,  1, -3,  0, -3, -3, -3, -2,  0,  0,  5, -3, -1, -1, -3,
/*W */  -3, -5, -5, -5, -3,  1, -3, -3, -3,  0, -3, -2, -1, -4,  0, -4, -1, -3, -4, -3,  0, -3, 15, -3,  2, -2,
/*X */  -1, -1, -2, -1, -1, -2, -2, -1, -1,  0, -1, -1, -1, -1,  0, -2, -1, -1, -1,  0,  0, -1, -3, -1, -1, -1,
/*Y */  -2, -3, -3, -3, -2,  4, -3,  2, -1,  0, -2, -1,  0, -2,  0, -3, -1, -1, -2, -2,  0, -1,  2, -1,  8, -2,
/*Z */  -1,  2, -3,  1,  5, -4, -2,  0, -3,  0,  1, -3, -1,  0,  0, -1,  4,  0,  0, -1,  0, -3, -2, -1, -2,  5};

int BLOSUM_50_direct[26 * 26] =
/*A */  {5, -2, -1, -2, -1, -3,  0, -2, -1,  0, -1, -2, -1, -1,  0, -1, -1, -2,  1,  0,  0,  0, -3, -1, -2, -1,
/*B */  -2,  5, -3,  5,  1, -4, -1,  0, -4,  0,  0, -4, -3,  4,  0, -2,  0, -1,  0,  0,  0, -4, -5, -1, -3,  2,
/*C */  -1, -3, 13, -4, -3, -2, -3, -3, -2,  0, -3, -2, -2, -2,  0, -4, -3, -4, -1, -1,  0, -1, -5, -2, -3, -3,
/*D */  -2,  5, -4,  8,  2, -5, -1, -1, -4,  0, -1, -4, -4,  2,  0, -1,  0, -2,  0, -1,  0, -4, -5, -1, -3,  1,
/*E */  -1,  1, -3,  2,  6, -3, -3,  0, -4,  0,  1, -3, -2,  0,  0, -1,  2,  0, -1, -1,  0, -3, -3, -1, -2,  5,
/*F */  -3, -4, -2, -5, -3,  8, -4, -1,  0,  0, -4,  1,  0, -4,  0, -4, -4, -3, -3, -2,  0, -1,  1, -2,  4, -4,
/*G */   0, -1, -3, -1, -3, -4,  8, -2, -4,  0, -2, -4, -3,  0,  0, -2, -2, -3,  0, -2,  0, -4, -3, -2, -3, -2,
/*H */  -2,  0, -3, -1,  0, -1, -2, 10, -4,  0,  0, -3, -1,  1,  0, -2,  1,  0, -1, -2,  0, -4, -3, -1,  2,  0,
/*I */  -1, -4, -2, -4, -4,  0, -4, -4,  5,  0, -3,  2,  2, -3,  0, -3, -3, -4, -3, -1,  0,  4, -3, -1, -1, -3,
/**J*/   0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,
/*K */  -1,  0, -3, -1,  1, -4, -2,  0, -3,  0,  6, -3, -2,  0,  0, -1,  2,  3,  0, -1,  0, -3, -3, -1, -2,  1,
/*L */  -2, -4, -2, -4, -3,  1, -4, -3,  2,  0, -3,  5,  3, -4,  0, -4, -2, -3, -3, -1,  0,  1, -2, -1, -1, -3,
/*M */  -1, -3, -2, -4, -2,  0, -3, -1,  2,  0, -2,  3,  7, -2,  0, -3,  0, -2, -2, -1,  0,  1, -1, -1,  0, -1,
/*N */  -1,  4, -2,  2,  0, -4,  0,  1, -3,  0,  0, -4, -2,  7,  0, -2,  0, -1,  1,  0,  0, -3, -4, -1, -2,  0,
/**O*/   0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,
/*P */  -1, -2, -4, -1, -1, -4, -2, -2, -3,  0, -1, -4, -3, -2,  0, 10, -1, -3, -1, -1,  0, -3, -4, -2, -3, -1,
/*Q */  -1,  0, -3,  0,  2, -4, -2,  1, -3,  0,  2, -2,  0,  0,  0, -1,  7,  1,  0, -1,  0, -3, -1, -1, -1,  4,
/*R */  -2, -1, -4, -2,  0, -3, -3,  0, -4,  0,  3, -3, -2, -1,  0, -3,  1,  7, -1, -1,  0, -3, -3, -1, -1,  0,
/*S */   1,  0, -1,  0, -1, -3,  0, -1, -3,  0,  0, -3, -2,  1,  0, -1,  0, -1,  5,  2,  0, -2, -4, -1, -2,  0,
/*T */   0,  0, -1, -1, -1, -2, -2, -2, -1,  0, -1, -1, -1,  0,  0, -1, -1, -1,  2,  5,  0,  0, -3,  0, -2, -1,
/**U*/   0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,
/*V */   0, -4, -1, -4, -3, -1, -4, -4,  4,  0, -3,  1,  1, -3,  0, -3, -3, -3, -2,  0,  0,  5, -3, -1, -1, -3,
/*W */  -3, -5, -5, -5, -3,  1, -3, -3, -3,  0, -3, -2, -1, -4,  0, -4, -1, -3, -4, -3,  0, -3, 15, -3,  2, -2,
/*X */  -1, -1, -2, -1, -1, -2, -2, -1, -1,  0, -1, -1, -1, -1,  0, -2, -1, -1, -1,  0,  0, -1, -3, -1, -1, -1,
/*Y */  -2, -3, -3, -3, -2,  4, -3,  2, -1,  0, -2, -1,  0, -2,  0, -3, -1, -1, -2, -2,  0, -1,  2, -1,  8, -2,
/*Z */  -1,  2, -3,  1,  5, -4, -2,  0, -3,  0,  1, -3, -1,  0,  0, -1,  4,  0,  0, -1,  0, -3, -2, -1, -2,  5};

__device__
int match_blosum(char a, char b) {
    return BLOSUM_50[(a-65)*26 + (b-65)];
}

int match_blosum_host(char a, char b) {
    return BLOSUM_50_direct[(a-65)*26 + (b-65)];
}

__device__
AlignedPair backtrace(const char *seq1, unsigned long len1, const char *seq2, unsigned long len2,
    CellDecision *decisions, BestCell bestCell, bool globalAlign) {

    if (globalAlign) {
        bestCell.i = len1;
        bestCell.j = len2;
    }

    // Find path ending at best cell
    Direction* path = (Direction*) malloc((len1+len2+1) * sizeof(Direction));
    path[0] = decisions[(bestCell.i)*(len2+1) + bestCell.j].direction;
    int pathLen = 0;
    while (path[pathLen] != Nil) {
        if (path[pathLen] == Diagonal) {
            bestCell.i--;
            bestCell.j--;
        }
        else if (path[pathLen] == Left) {
            bestCell.j--;
        }
        else if (path[pathLen] == Above) {
            bestCell.i--;
        }

        path[++pathLen] = decisions[(bestCell.i)*(len2+1) + bestCell.j].direction;
    }

    char* aligned1 = (char*) malloc(sizeof(char) * (pathLen + 1));
    char* aligned2 = (char*) malloc(sizeof(char) * (pathLen + 1));
    int p = 0;
    // Align fragments
    for (int pathPos = pathLen-1; pathPos >= 0; pathPos--, p++) {
        if (path[pathPos] == Diagonal) {
            aligned1[p] = seq1[bestCell.i++];
            aligned2[p] = seq2[bestCell.j++];
        } else if (path[pathPos] == Left) {
            aligned1[p] = '-';
            aligned2[p] = seq2[bestCell.j++];
        } else if (path[pathPos] == Above) {
            aligned1[p] = seq1[bestCell.i++];
            aligned2[p] = '-';
        }
    }
    aligned1[p] = '\0';
    aligned2[p] = '\0';

    free(path);

    return (AlignedPair) {aligned1, aligned2, pathLen};
}

__global__
void backtraceRunner(const char *seq1, unsigned long len1, const char *seq2, unsigned long len2,
    CellDecision *decisions, BestCell bestCell, bool globalAlign, AlignedPair* alignedPair) {

    AlignedPair result = backtrace(seq1, len1, seq2, len2, decisions, bestCell, globalAlign);
    memcpy(alignedPair->seq1, result.seq1, sizeof(char)*(result.len+1));
    memcpy(alignedPair->seq2, result.seq2, sizeof(char)*(result.len+1));
    alignedPair->len = result.len;

    free(result.seq1);
    free(result.seq2);
}

__device__
AlignedPair backtrace_gotoh(const char *seq1, unsigned long len1, const char *seq2, unsigned long len2,
                CellDecision *decisions, GapDecision *vertical, GapDecision *horizontal,
                BestCell bestCell, bool globalAlign, bool forceBottomVerticalGap, bool forceBottomHorizontalGap) {
    if (globalAlign) {
        bestCell.i = len1;
        bestCell.j = len2;
    }

    // Find path ending at best cell
    Direction* path = (Direction*) malloc((len1+len2+1) * sizeof(Direction));
    path[0] = forceBottomVerticalGap ? Above : decisions[(bestCell.i)*(len2+1) + bestCell.j].direction;
    path[0] = forceBottomHorizontalGap ? Left : path[0];
    int pathLen = 0;
    while (path[pathLen] != Nil) {
        if (path[pathLen] == Diagonal) {
            bestCell.i--;
            bestCell.j--;
            pathLen++;
        }
        else if (path[pathLen] == Left) {
            do {
                bestCell.j--;
                pathLen++;
                // The last path[pathLen] will be overwritten when the loop finishes
                path[pathLen] = Left;
            } while (bestCell.j > 0 && horizontal[(bestCell.i)*(len2+1) + bestCell.j + 1].gap != GapStart);
        }
        else if (path[pathLen] == Above) {
            do {
                bestCell.i--;
                pathLen++;
                // The last path[pathLen] will be overwritten when the loop finishes
                path[pathLen] = Above;
            } while (bestCell.i > 0 && vertical[(bestCell.i + 1)*(len2+1) + bestCell.j].gap != GapStart);
        }
        path[pathLen] = decisions[(bestCell.i)*(len2+1) + bestCell.j].direction;
    }

    char* aligned1 = (char*) malloc(sizeof(char) * (pathLen + 1));
    char* aligned2 = (char*) malloc(sizeof(char) * (pathLen + 1));
    int p = 0;
    // Align fragments
    for (int pathPos = pathLen-1; pathPos >= 0; pathPos--, p++) {
        if (path[pathPos] == Diagonal) {
            aligned1[p] = seq1[bestCell.i++];
            aligned2[p] = seq2[bestCell.j++];
        } else if (path[pathPos] == Left) {
            aligned1[p] = '-';
            aligned2[p] = seq2[bestCell.j++];
        } else if (path[pathPos] == Above) {
            aligned1[p] = seq1[bestCell.i++];
            aligned2[p] = '-';
        }
    }
    aligned1[p] = '\0';
    aligned2[p] = '\0';

    free(path);

    return (AlignedPair) {aligned1, aligned2, pathLen};
}

__global__
void backtraceGotohRunner(const char *seq1, unsigned long len1, const char *seq2, unsigned long len2,
    CellDecision *decisions, GapDecision *vertical, GapDecision *horizontal,
    BestCell bestCell, bool globalAlign, bool forceBottomVerticalGap, bool forceBottomHorizontalGap,
    AlignedPair* alignedPair) {

    AlignedPair result = backtrace_gotoh(seq1, len1, seq2, len2,
        decisions, vertical, horizontal,
        bestCell, globalAlign, forceBottomVerticalGap, forceBottomHorizontalGap
    );
    memcpy(alignedPair->seq1, result.seq1, sizeof(char)*(result.len+1));
    memcpy(alignedPair->seq2, result.seq2, sizeof(char)*(result.len+1));
    alignedPair->len = result.len;

    free(result.seq1);
    free(result.seq2);
}

__global__
void printSeqs(char *d_seq1, unsigned long len1, char *d_seq2, unsigned long len2) {
    printf("Solving ");
    for (int i = 0; i < len1; i++)
        printf("%c", d_seq1[i]);
    printf("  ");
    for (int i = 0; i < len2; i++)
        printf("%c", d_seq2[i]);
    printf("\n");
}

int score_aligned_pair(char* seq1, char* seq2) {
    int score = 0;

    while (*seq1) {
        if (*seq1 == '-' || *seq2 == '-') {
            score += GAP_PENALTY;
        }
        else {
            score += match_host(*seq1, *seq2);
        }

        seq1++; seq2++;
    }

    return score;
}

int score_gotoh(char* seq1, char* seq2) {
    int score = 0;
    bool above_gap = false;
    bool left_gap = false;

    while (*seq1) {
        if (*seq1 == '-') {
            above_gap = false;
            if (left_gap)
                score += GAP_EXTEND;
            else {
                left_gap = true;
                score += GAP_START;
            }
        }
        else if (*seq2 == '-') {
            left_gap = false;
            if (above_gap)
                score += GAP_EXTEND;
            else {
                above_gap = true;
                score += GAP_START;
            }
        }
        else {
            above_gap = false;
            left_gap = false;
            score += match_host(*seq1, *seq2);
        }

        seq1++; seq2++;
    }

    return score;
}
