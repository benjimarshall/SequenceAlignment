#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include "tests.cuh"

int main(int argc, char *argv[]) {
    if (argc < 3) {
        printf("Usage:\n./main <seq1> <seq2>\n");
        return 1;
    }
    char* seq1 = read_fasta(argv[1], 65536);
    bool seq1_from_file = seq1 ? true : false;
    char* seq1_actual = seq1_from_file ? seq1 : argv[1];
    char* seq2 = read_fasta(argv[2], 65536);
    bool seq2_from_file = seq2 ? true : false;
    char* seq2_actual = seq2_from_file ? seq2 : argv[2];
    unsigned long len1 = strlen(seq1_actual);
    unsigned long len2 = strlen(seq2_actual);

    char* d_seq1;
    cudaMallocManaged(&d_seq1, sizeof(char) * len1);
    cudaMemcpy(d_seq1, seq1_actual, len1, cudaMemcpyHostToDevice);
    char* d_seq2;
    cudaMallocManaged(&d_seq2, sizeof(char) * len2);
    cudaMemcpy(d_seq2, seq2_actual, len2, cudaMemcpyHostToDevice);
    cudaStream_t stream;
    cudaStreamCreate(&stream);

    run_sw(d_seq1, len1, d_seq2, len2, stream);
    run_nw(d_seq1, len1, d_seq2, len2, stream);
    run_sw_linear_parallel(d_seq1, len1, d_seq2, len2, stream);
    run_sw_gotoh(d_seq1, len1, d_seq2, len2, stream);
    run_sw_singleblock(d_seq1, len1, d_seq2, len2, stream);

    cudaFree(d_seq1);
    cudaFree(d_seq2);
    cudaStreamDestroy(stream);
    if (seq1_from_file) free(seq1);
    if (seq2_from_file) free(seq2);

    return 0;
}
