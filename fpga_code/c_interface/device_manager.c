#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "scoring.h"
#include "device_manager.h"

// Pointer to the base address that will be routed to the accelerator
// Once initialised by device_init(), you can read and write from address in the FPGA as if this
// was a normal block of 64b memory (with 64-bits of data per address).
// Reading and writing to and from the Avalon interface is as simple as dereferencing this pointer,
// with some offset if you so choose.
volatile unsigned long long *h2p_interface_addr;

// One-time initialisation to connect to the accelerator
void device_init(void) {
    int fd;

    // Open the raw physical memory map
    if ( (fd = open("/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1) {
        printf("ERROR: could not open \"/dev/mem\"...\n");
        return;
    }

    // Map the addresses that will be routed to the accelerator
    void *virtual_base = mmap(0, FPGA_INTERFACE_BYTE_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd,
                              FPGA_INTERFACE_OFFSET);
    if (virtual_base == MAP_FAILED) {
        printf("ERROR: mmap() failed...\n");
        close(fd);
        return;
    }

    h2p_interface_addr = virtual_base;
}

unsigned long long basic_read(size_t index) {
    return *(h2p_interface_addr + index);
}

StatusFlags get_status_flags(void) {
    // Where the LSB represents whether the device has finished aligning sequences (grid filled and
    // backtraced) and the 2nd LSB represents whether the grid has been filled (but backtracing)
    // may still be occuring

    StatusFlags status_flags;

    unsigned long long flags = *h2p_interface_addr;
    status_flags.finished = flags % 2;
    status_flags.grid_finished = ((flags % 4) - status_flags.finished) >> 1;

    return status_flags;
}

inline unsigned long long dna_val(char c) {
    switch (c) {
        case 'A':
            return 0;
        case 'C':
            return 1;
        case 'G':
            return 2;
        case 'T':
            return 3;
        default:
            printf("ERROR converting value %c to DNA\n", c);
            return 4;
    }
}

inline void write_sequence_dna(char* seq, unsigned long long len,
                    volatile unsigned long long* target) {
    for (int i = 0; i*32 < len; i++) {
        unsigned long long seq_word = 0ULL;
        for (int j = 0; j < 32 && i*32+j < len; j++) {
            unsigned long long value = dna_val(seq[i*32 + j]);

            seq_word += value << (62 - j*2);
        }

        *(target + i) = seq_word;
    }
}

inline void write_sequence_protein(char* seq, unsigned long long len,
                    volatile unsigned long long* target) {
    for (int i = 0; i*8 < len; i++) {
        unsigned long long seq_word = 0ULL;
        for (int j = 0; j < 8 && i*8+j < len; j++) {
            unsigned long long value = seq[i*8 + j] - 65;

            seq_word += value << (35 - j*5);
        }

        *(target + i) = seq_word;
    }
}

void start_job(char* seq1, char* seq2, int is_dna) {
    *h2p_interface_addr = 0ULL; // reset the device by writing 0 to *0

    unsigned long long len1 = strlen(seq1);
    unsigned long long len2 = strlen(seq2);
    unsigned long long seq2_offset = is_dna ? 32 : 128;

    if (is_dna) {
        write_sequence_dna(seq1, len1, h2p_interface_addr + 1);
        write_sequence_dna(seq2, len2, h2p_interface_addr + 1 + seq2_offset);
    }
    else {
        write_sequence_protein(seq1, len1, h2p_interface_addr + 1);
        write_sequence_protein(seq2, len2, h2p_interface_addr + 1 + seq2_offset);
    }

    // The device will start aligning sequences when the LSB of value at address 0 is set to 1
    // So we get ready to write that here
    unsigned long long start_flag = 1ULL;

    // Also in the address 0 is other meta-data: the lengths of the two sequences that
    // have been written to the device just before
    start_flag += len1 << 32;
    start_flag += len2 << 48;

    // We pass the length meta-data and the instruction to start (LSB = 1) at the same time
    *h2p_interface_addr = start_flag;
}

inline int is_last_row(unsigned long long row) {
    // These rows are a sequence of 2-bit pointers, null terminated by 0b00
    // The stuff afterwards might have been garbage (but probably isn't the current setup)
    // So we need to see if any aligned pair of bits are 0b00

    // We fold the pointers into themselves using an OR, so non-null pointers
    // OR to 1, null folds to 0, by ORing with itself bitshifted. The MSB of
    // each pair is that value, we don't care about the LSB because it crosses
    // pointers
    // Running (row << 1) | row
    // Small example: 1110_0100_1111
    //               11100_1001_111
    //             | ---------------
    //                1110_1101_1111
    //                       ^the null pointer bit
    // Mask off the bits we don't care about, calling them good (1) using:
    //        1110_1101_1111
    //        0101_0101_0101    (the constant 0x5555...)
    //     OR --------------
    //        1111_1101_1111
    //               ^our null pointer
    // Now we simply compare it to 0xFFFF... == -> no nulls, != -> is at least 1 null
    return (((row << 1) | row) | 0x5555555555555555) != 0xFFFFFFFFFFFFFFFF;
}

inline void read_row(unsigned long long row, char* dest) {
    unsigned long long sub = 0ULL;

    for (int i = 62; i >= 0; i -= 2) {
        unsigned long long val = (row >> i) - sub;
        switch(val) {
            case 1ULL:
                *(dest++) = '|';
                break;
            case 2ULL:
                *(dest++) = '-';
                break;
            case 3ULL:
                *(dest++) = '\\';
                break;
            case 0ULL:
                *(dest++) = '.';
                *dest = '\0';
                return;
            default:
                printf("Error reading row %llu with cell %llu at %d\n", row, val, i);
                return;
        }

        sub = (sub + val) << 2;
    }
}

void read_results(char* pointer_sequence, int* maxCol, int* maxRow, int doPrint) {
    unsigned long long flags = *h2p_interface_addr;
    unsigned int finished = flags % 2;
    unsigned int grid_finished = ((flags % 4) - finished) >> 1;

    if (doPrint) printf("Overall status: %d\nGrid status: %d\n", finished, grid_finished);

    *maxCol = flags >> 48;
    *maxRow = (flags >> 32) - ((*maxCol) << 16);
    if (doPrint) printf("Max Row: %d\nMax Col: %d\n", *maxRow, *maxCol);

    volatile unsigned long long* p_row = h2p_interface_addr;
    unsigned long long current_row;

    do {
        p_row++;
        current_row = *p_row;
        read_row(current_row, pointer_sequence);
        pointer_sequence += 32;

    } while (!is_last_row(current_row));
}

char** parse_results(char* seq1, char* seq2, char* pointer_sequence, int maxCol, int maxRow,
    int* score, int is_dna, int using_blosum) {

    // unsigned long long len1 = strlen(seq1);
    // unsigned long long len2 = strlen(seq2);
    unsigned long long pathLen = strlen(pointer_sequence);

    char* aligned1 = malloc(sizeof(char) * (pathLen));
    char* aligned2 = malloc(sizeof(char) * (pathLen));

    char** alignedPair = malloc(sizeof(char*)*2);
    alignedPair[0] = aligned1;
    alignedPair[1] = aligned2;

    aligned1 += pathLen-1;
    *(aligned1--) = '\0';
    aligned2 += pathLen-1;
    *(aligned2--) = '\0';

    unsigned long long count1 = maxRow;
    unsigned long long count2 = maxCol;
    *score = 0;

    while (*pointer_sequence) {
        switch(*pointer_sequence) {
            case '\\':
                if (count1 <= 0) {
                    // printf("Ran out of seq1. Count1: %llu, Count2: %llu\n", count1, count2);
                    return NULL;
                }
                if (count2 <= 0) {
                    // printf("Ran out of seq2. Count1: %llu, Count2: %llu\n", count1, count2);
                    return NULL;
                }
                char a = *(seq1 + count1);
                char b = *(seq2 + count2);
                *score += is_dna || !using_blosum ? match_constant(a, b) : match_blosum50(a, b);

                *(aligned1--) = *(seq1 + count1--);
                *(aligned2--) = *(seq2 + count2--);
                break;
            case '|':
                if (count1 <= 0) {
                    // printf("Ran out of seq1. Count1: %llu, Count2: %llu\n", count1, count2);
                    return NULL;
                }
                *score += GAP_PENALTY;

                *(aligned1--) = *(seq1 + count1--);
                *(aligned2--) = '-';
                break;
            case '-':
                if (count2 <= 0) {
                    // printf("Ran out of seq2. Count1: %llu, Count2: %llu\n", count1, count2);
                    return NULL;
                }
                *score += GAP_PENALTY;

                *(aligned1--) = '-';
                *(aligned2--) = *(seq2 + count2--);
                break;
            case '.':
                if (aligned1+1 != alignedPair[0] || aligned2+1 != alignedPair[1]) {
                    printf("Found an early Nil %c at SeqCount1: %llu, SeqCount2: %llu,"
                           " AlignedPos1 %d AlignedPos2 %d\n",
                           *pointer_sequence, count1, count2,
                           aligned1+1 - alignedPair[0], aligned2+1 - alignedPair[1]
                    );
                }
                break;
               default:
                printf("Unexpected pointer character: %c at SeqCount1: %llu, SeqCount2: %llu\n",
                       *pointer_sequence, count1, count2
                );
                return 0;
        }

        // printf("Aligned %c : %c %c\n", *pointer_sequence, *(aligned1+1), *(aligned2+1));

        pointer_sequence++;
    }

    if (aligned1+1 != alignedPair[0] || aligned2+1 != alignedPair[1]) {
        printf("Didn't finish with expected null. Positions are Count1: %llu, Count2: %llu\n",
               count1, count2
        );
        printf("%p %p :: %p %p \n", aligned1+1, alignedPair[0], aligned2+1, alignedPair[1]);
    }

    return alignedPair;
}
