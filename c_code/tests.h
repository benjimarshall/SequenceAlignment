#ifndef PARTIIPROJECT_TESTS_H
#define PARTIIPROJECT_TESTS_H

void run_sw(char* seq1, unsigned long len1, char* seq2, unsigned long len2);

void run_nw(char* seq1, unsigned long len1, char* seq2, unsigned long len2);

void run_sw_linear_parallel(char* seq1, unsigned long len1, char* seq2, unsigned long len2);

void run_sw_gotoh(char* seq1, unsigned long len1, char* seq2, unsigned long len2);

char* read_fasta(char* file_name, unsigned long sequence_length);

#endif //PARTIIPROJECT_TESTS_H
