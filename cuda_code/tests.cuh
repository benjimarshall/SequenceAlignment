#ifndef CUDA_TESTS_H
#define CUDA_TESTS_H

void run_sw(char* d_seq1, unsigned long len1, char* d_seq2, unsigned long len2, cudaStream_t stream);

void run_nw(char* d_seq1, unsigned long len1, char* d_seq2, unsigned long len2, cudaStream_t stream);

void run_sw_linear_parallel(char* d_seq1, unsigned long len1, char* d_seq2, unsigned long len2, cudaStream_t stream);

void run_sw_gotoh(char* d_seq1, unsigned long len1, char* d_seq2, unsigned long len2, cudaStream_t stream);

void run_sw_singleblock(char* d_seq1, unsigned long len1, char* d_seq2, unsigned long len2, cudaStream_t stream);

char* read_fasta(char* file_name, unsigned long sequence_length);

#endif //CUDA_TESTS_H
