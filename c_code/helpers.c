#include <stdlib.h>
#include <stdio.h>

#include "helpers.h"

int match_constant(char a, char b) {
    return a == b ? ALIGN_GAIN : MISALIGN_PENALTY;
}

const int BLOSUM_50_old[24][24] =
    //      A   R   N   D   C   Q   E   G   H   I   L   K   M   F   P   S   T   W   Y   V   B   Z   X   *
    /*A*/ {{5, -2, -1, -2, -1, -1, -1,  0, -2, -1, -2, -1, -1, -3, -1,  1,  0, -3, -2,  0, -2, -1, -1,  0},
    /*R*/ {-2,  7, -1, -2, -4,  1,  0, -3,  0, -4, -3,  3, -2, -3, -3, -1, -1, -3, -1, -3, -1,  0, -1,  0},
    /*N*/ {-1, -1,  7,  2, -2,  0,  0,  0,  1, -3, -4,  0, -2, -4, -2,  1,  0, -4, -2, -3,  4,  0, -1,  0},
    /*D*/ {-2, -2,  2,  8, -4,  0,  2, -1, -1, -4, -4, -1, -4, -5, -1,  0, -1, -5, -3, -4,  5,  1, -1,  0},
    /*C*/ {-1, -4, -2, -4, 13, -3, -3, -3, -3, -2, -2, -3, -2, -2, -4, -1, -1, -5, -3, -1, -3, -3, -2,  0},
    /*Q*/ {-1,  1,  0,  0, -3,  7,  2, -2,  1, -3, -2,  2,  0, -4, -1,  0, -1, -1, -1, -3,  0,  4, -1,  0},
    /*E*/ {-1,  0,  0,  2, -3,  2,  6, -3,  0, -4, -3,  1, -2, -3, -1, -1, -1, -3, -2, -3,  1,  5, -1,  0},
    /*G*/ { 0, -3,  0, -1, -3, -2, -3,  8, -2, -4, -4, -2, -3, -4, -2,  0, -2, -3, -3, -4, -1, -2, -2,  0},
    /*H*/ {-2,  0,  1, -1, -3,  1,  0, -2, 10, -4, -3,  0, -1, -1, -2, -1, -2, -3,  2, -4,  0,  0, -1,  0},
    /*I*/ {-1, -4, -3, -4, -2, -3, -4, -4, -4,  5,  2, -3,  2,  0, -3, -3, -1, -3, -1,  4, -4, -3, -1,  0},
    /*L*/ {-2, -3, -4, -4, -2, -2, -3, -4, -3,  2,  5, -3,  3,  1, -4, -3, -1, -2, -1,  1, -4, -3, -1,  0},
    /*K*/ {-1,  3,  0, -1, -3,  2,  1, -2,  0, -3, -3,  6, -2, -4, -1,  0, -1, -3, -2, -3,  0,  1, -1,  0},
    /*M*/ {-1, -2, -2, -4, -2,  0, -2, -3, -1,  2,  3, -2,  7,  0, -3, -2, -1, -1,  0,  1, -3, -1, -1,  0},
    /*F*/ {-3, -3, -4, -5, -2, -4, -3, -4, -1,  0,  1, -4,  0,  8, -4, -3, -2,  1,  4, -1, -4, -4, -2,  0},
    /*P*/ {-1, -3, -2, -1, -4, -1, -1, -2, -2, -3, -4, -1, -3, -4, 10, -1, -1, -4, -3, -3, -2, -1, -2,  0},
    /*S*/ { 1, -1,  1,  0, -1,  0, -1,  0, -1, -3, -3,  0, -2, -3, -1,  5,  2, -4, -2, -2,  0,  0, -1,  0},
    /*T*/ { 0, -1,  0, -1, -1, -1, -1, -2, -2, -1, -1, -1, -1, -2, -1,  2,  5, -3, -2,  0,  0, -1,  0,  0},
    /*W*/ {-3, -3, -4, -5, -5, -1, -3, -3, -3, -3, -2, -3, -1,  1, -4, -4, -3, 15,  2, -3, -5, -2, -3,  0},
    /*Y*/ {-2, -1, -2, -3, -3, -1, -2, -3,  2, -1, -1, -2,  0,  4, -3, -2, -2,  2,  8, -1, -3, -2, -1,  0},
    /*V*/ { 0, -3, -3, -4, -1, -3, -3, -4, -4,  4,  1, -3,  1, -1, -3, -2,  0, -3, -1,  5, -4, -3, -1,  0},
    /*B*/ {-2, -1,  4,  5, -3,  0,  1, -1,  0, -4, -4,  0, -3, -4, -2,  0,  0, -5, -3, -4,  5,  2, -1,  0},
    /*Z*/ {-1,  0,  0,  1, -3,  4,  5, -2,  0, -3, -3,  1, -1, -4, -1,  0, -1, -2, -2, -3,  2,  5, -1,  0},
    /*X*/ {-1, -1, -1, -1, -2, -1, -1, -2, -1, -1, -1, -1, -1, -2, -2, -1,  0, -3, -1, -1, -1, -1, -1,  0},
    /***/ { 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  1}};

const int BLOSUM_50[26][26] =
/*A */  {{5, -2, -1, -2, -1, -3,  0, -2, -1,  0, -1, -2, -1, -1,  0, -1, -1, -2,  1,  0,  0,  0, -3, -1, -2, -1},
/*B */  {-2,  5, -3,  5,  1, -4, -1,  0, -4,  0,  0, -4, -3,  4,  0, -2,  0, -1,  0,  0,  0, -4, -5, -1, -3,  2},
/*C */  {-1, -3, 13, -4, -3, -2, -3, -3, -2,  0, -3, -2, -2, -2,  0, -4, -3, -4, -1, -1,  0, -1, -5, -2, -3, -3},
/*D */  {-2,  5, -4,  8,  2, -5, -1, -1, -4,  0, -1, -4, -4,  2,  0, -1,  0, -2,  0, -1,  0, -4, -5, -1, -3,  1},
/*E */  {-1,  1, -3,  2,  6, -3, -3,  0, -4,  0,  1, -3, -2,  0,  0, -1,  2,  0, -1, -1,  0, -3, -3, -1, -2,  5},
/*F */  {-3, -4, -2, -5, -3,  8, -4, -1,  0,  0, -4,  1,  0, -4,  0, -4, -4, -3, -3, -2,  0, -1,  1, -2,  4, -4},
/*G */  { 0, -1, -3, -1, -3, -4,  8, -2, -4,  0, -2, -4, -3,  0,  0, -2, -2, -3,  0, -2,  0, -4, -3, -2, -3, -2},
/*H */  {-2,  0, -3, -1,  0, -1, -2, 10, -4,  0,  0, -3, -1,  1,  0, -2,  1,  0, -1, -2,  0, -4, -3, -1,  2,  0},
/*I */  {-1, -4, -2, -4, -4,  0, -4, -4,  5,  0, -3,  2,  2, -3,  0, -3, -3, -4, -3, -1,  0,  4, -3, -1, -1, -3},
/**J*/  { 0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0},
/*K */  {-1,  0, -3, -1,  1, -4, -2,  0, -3,  0,  6, -3, -2,  0,  0, -1,  2,  3,  0, -1,  0, -3, -3, -1, -2,  1},
/*L */  {-2, -4, -2, -4, -3,  1, -4, -3,  2,  0, -3,  5,  3, -4,  0, -4, -2, -3, -3, -1,  0,  1, -2, -1, -1, -3},
/*M */  {-1, -3, -2, -4, -2,  0, -3, -1,  2,  0, -2,  3,  7, -2,  0, -3,  0, -2, -2, -1,  0,  1, -1, -1,  0, -1},
/*N */  {-1,  4, -2,  2,  0, -4,  0,  1, -3,  0,  0, -4, -2,  7,  0, -2,  0, -1,  1,  0,  0, -3, -4, -1, -2,  0},
/**O*/  { 0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0},
/*P */  {-1, -2, -4, -1, -1, -4, -2, -2, -3,  0, -1, -4, -3, -2,  0, 10, -1, -3, -1, -1,  0, -3, -4, -2, -3, -1},
/*Q */  {-1,  0, -3,  0,  2, -4, -2,  1, -3,  0,  2, -2,  0,  0,  0, -1,  7,  1,  0, -1,  0, -3, -1, -1, -1,  4},
/*R */  {-2, -1, -4, -2,  0, -3, -3,  0, -4,  0,  3, -3, -2, -1,  0, -3,  1,  7, -1, -1,  0, -3, -3, -1, -1,  0},
/*S */  { 1,  0, -1,  0, -1, -3,  0, -1, -3,  0,  0, -3, -2,  1,  0, -1,  0, -1,  5,  2,  0, -2, -4, -1, -2,  0},
/*T */  { 0,  0, -1, -1, -1, -2, -2, -2, -1,  0, -1, -1, -1,  0,  0, -1, -1, -1,  2,  5,  0,  0, -3,  0, -2, -1},
/**U*/  { 0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0},
/*V */  { 0, -4, -1, -4, -3, -1, -4, -4,  4,  0, -3,  1,  1, -3,  0, -3, -3, -3, -2,  0,  0,  5, -3, -1, -1, -3},
/*W */  {-3, -5, -5, -5, -3,  1, -3, -3, -3,  0, -3, -2, -1, -4,  0, -4, -1, -3, -4, -3,  0, -3, 15, -3,  2, -2},
/*X */  {-1, -1, -2, -1, -1, -2, -2, -1, -1,  0, -1, -1, -1, -1,  0, -2, -1, -1, -1,  0,  0, -1, -3, -1, -1, -1},
/*Y */  {-2, -3, -3, -3, -2,  4, -3,  2, -1,  0, -2, -1,  0, -2,  0, -3, -1, -1, -2, -2,  0, -1,  2, -1,  8, -2},
/*Z */  {-1,  2, -3,  1,  5, -4, -2,  0, -3,  0,  1, -3, -1,  0,  0, -1,  4,  0,  0, -1,  0, -3, -2, -1, -2,  5}};
       // A   B   C   D   E   F   G   H   I   *J  K   L   M   N   *O  P   Q   R   S   T   *U  V   W   X   Y   Z


int amino_acid_to_index(char a) {
    switch (a) {
        case 'A':
            return 0;
        case 'R':
            return 1;
        case 'N':
            return 2;
        case 'D':
            return 3;
        case 'C':
            return 4;
        case 'Q':
            return 5;
        case 'E':
            return 6;
        case 'G':
            return 7;
        case 'H':
            return 8;
        case 'I':
            return 9;
        case 'L':
            return 10;
        case 'K':
            return 11;
        case 'M':
            return 12;
        case 'F':
            return 13;
        case 'P':
            return 14;
        case 'S':
            return 15;
        case 'T':
            return 16;
        case 'W':
            return 17;
        case 'Y':
            return 18;
        case 'V':
            return 19;
        case 'B':
            return 20;
        case 'Z':
            return 21;
        case 'X':
            return 22;
        default:
            return 23;
    }
}

int match_blosum50_old(char a, char b) {
    return BLOSUM_50_old[amino_acid_to_index(a)][amino_acid_to_index(b)];
}

int match_blosum50(char a, char b) {
    return BLOSUM_50[a - 65][b - 65];
}

int min(int v1, int v2) {
    return v1 < v2 ? v1 : v2;
}

int max(int v1, int v2) {
    return v1 > v2 ? v1 : v2;
}

void print_direction(Direction direction, char* suffix) {
    switch (direction) {
        case Above:
            printf("Above%s", suffix);
            break;
        case Left:
            printf("Left%s", suffix);
            break;
        case Diagonal:
            printf("Diagonal%s", suffix);
            break;
        case Nil:
            printf("Nil%s", suffix);
            break;
        default:
            printf("Error printing direction\n");
            break;
    }
}

char **backtrace(const char *seq1, unsigned long len1, const char *seq2, unsigned long len2, CellDecision **decisions,
                 BestCell *bestCell, bool fromBottomRight) {
    if (fromBottomRight) {
        bestCell->i = len1;
        bestCell->j = len2;
    }

    // Find path ending at best cell
    Direction path[len1+len2+1];
    path[0] = decisions[bestCell->i][bestCell->j].direction;
    // print_direction(path[0], " ");
    int pathLen = 0;
    while (path[pathLen] != Nil) {
        if (path[pathLen] == Diagonal) {
            bestCell->i--;
            bestCell->j--;
        }
        else if (path[pathLen] == Left) {
            bestCell->j--;
        }
        else if (path[pathLen] == Above) {
            bestCell->i--;
        }

        path[++pathLen] = decisions[bestCell->i][bestCell->j].direction;
        // print_direction(path[pathLen], " ");
    }

    char* aligned1 = malloc(sizeof(char) * (pathLen + 1));
    char* aligned2 = malloc(sizeof(char) * (pathLen + 1));
    int p = 0;
    // Align fragments
    for (pathLen--; pathLen >= 0; pathLen--, p++) {
        if (path[pathLen] == Diagonal) {
            aligned1[p] = seq1[bestCell->i++];
            aligned2[p] = seq2[bestCell->j++];
        } else if (path[pathLen] == Left) {
            aligned1[p] = '-';
            aligned2[p] = seq2[bestCell->j++];
        } else if (path[pathLen] == Above) {
            aligned1[p] = seq1[bestCell->i++];
            aligned2[p] = '-';
        }
    }
    aligned1[p] = '\0';
    aligned2[p] = '\0';

    char** alignedPair = malloc(sizeof(char*) * 2);
    alignedPair[0] = aligned1;
    alignedPair[1] = aligned2;
    return alignedPair;
}

char** backtrace_gotoh(const char* seq1, unsigned long len1, const char* seq2, unsigned long len2,
                       GotohGrids grids,
                       BestCell* bestCell, bool fromBottomRight, bool forceBottomVerticalGap, bool forceBottomHorizontalGap) {
    if (fromBottomRight) {
        bestCell->i = len1;
        bestCell->j = len2;
    }

    // Find path ending at best cell
    Direction path[len1+len2+1];
    path[0] = forceBottomVerticalGap ? Above : grids.decisions[bestCell->i][bestCell->j].direction;
    path[0] = forceBottomHorizontalGap ? Left : path[0];
    // print_direction(path[0], " ");
    int pathLen = 0;
    while (path[pathLen] != Nil) {
        if (path[pathLen] == Diagonal) {
            bestCell->i--;
            bestCell->j--;
            pathLen++;
        }
        else if (path[pathLen] == Left) {
            // Fill out the gap while the row is GapExtend
            do {
                bestCell->j--;
                pathLen++;
                // The last path[pathLen] will be overwritten when the loop finishes
                path[pathLen] = Left;
            } while (bestCell->j > 0 && grids.horizontal[bestCell->i][bestCell->j + 1].gap != GapStart);
        }
        else if (path[pathLen] == Above) {
            // Fill out the gap while the column is GapExtend
            do {
                bestCell->i--;
                pathLen++;
                // printf("ij %lu %lu :: Gap %d %d \n", bestCell->i, bestCell->j, GapStart, grids.vertical[bestCell->i + 1][bestCell->j].gap);
                // The last path[pathLen] will be overwritten when the loop finishes
                path[pathLen] = Above;
            } while (bestCell->i > 0 && grids.vertical[bestCell->i + 1][bestCell->j].gap != GapStart);
        }
        // Collect the grid-pointer for the next iteration
        path[pathLen] = grids.decisions[bestCell->i][bestCell->j].direction;

        // print_direction(path[pathLen], " ");
    }

    char* aligned1 = malloc(sizeof(char) * (pathLen + 1));
    char* aligned2 = malloc(sizeof(char) * (pathLen + 1));
    int p = 0;
    // Align fragments
    for (pathLen--; pathLen >= 0; pathLen--, p++) {
        if (path[pathLen] == Diagonal) {
            aligned1[p] = seq1[bestCell->i++];
            aligned2[p] = seq2[bestCell->j++];
        } else if (path[pathLen] == Left) {
            aligned1[p] = '-';
            aligned2[p] = seq2[bestCell->j++];
        } else if (path[pathLen] == Above) {
            aligned1[p] = seq1[bestCell->i++];
            aligned2[p] = '-';
        }
    }
    aligned1[p] = '\0';
    aligned2[p] = '\0';

    char** alignedPair = malloc(sizeof(char*) * 2);
    alignedPair[0] = aligned1;
    alignedPair[1] = aligned2;
    return alignedPair;
}

int score_aligned_pair(char* seq1, char* seq2) {
    int score = 0;

    while (*seq1) {
        if (*seq1 == '-' || *seq2 == '-') {
            score += GAP_PENALTY;
        }
        else {
            score += match(*seq1, *seq2);
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
            score += match(*seq1, *seq2);
        }

        seq1++; seq2++;
    }

    return score;
}

bool validSubstring(const char* original, unsigned long lenOriginal, const char* aligned, unsigned long lenAligned) {
    for (unsigned long i = 0; i < lenOriginal; i++) {
        int pos = 0;
        bool successful = true;
        for (unsigned long j = 0; j < lenAligned; j++) {
            if (aligned[j] != '-') {
                if (original[i + pos] != aligned[j]) {
                    successful = false;
                    break;
                }
                pos++;
            }
        }
        if (successful) return true;
    }

    return false;
}

bool is_valid_pair(char* original1, unsigned long lenOriginal1, char* original2, unsigned long lenOriginal2,
                   char* aligned1, unsigned long lenAligned1, char* aligned2, unsigned long lenAligned2) {
    return lenAligned1 == lenAligned2
        && validSubstring(original1, lenOriginal1, aligned1, lenAligned1)
        && validSubstring(original2, lenOriginal2, aligned2, lenAligned2);
}
