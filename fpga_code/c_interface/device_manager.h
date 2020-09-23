#ifndef DEVICE_MANAGER_H
#define DEVICE_MANAGER_H

// The physical address for the base region of the memory mapped accelerator
#define FPGA_INTERFACE_OFFSET 0xC0040000U

// The number of address bytes that have meaning for the accelerator
#define FPGA_INTERFACE_BYTE_SIZE 1

void device_init(void);

typedef struct {
    unsigned int finished;
    unsigned int grid_finished;
} StatusFlags;

StatusFlags get_status_flags(void);

void start_job(char* seq1, char* seq2, int is_dna);

void read_results(char* pointer_sequence, int* maxCol, int* maxRow, int doPrint);

char** parse_results(char* seq1, char* seq2, char* pointer_sequence,
                     int maxCol, int maxRow, int* score, int is_dna, int using_blosum);

#endif // DEVICE_MANAGER_H

