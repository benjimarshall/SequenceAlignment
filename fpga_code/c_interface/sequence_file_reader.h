#ifndef SEQUENCE_FILE_READER_H
#define SEQUENCE_FILE_READER_H

char* read_fasta(char* file_name, unsigned long sequence_length);

char* find_prot_seq(const char* sequence_length_str, unsigned long sequence_length, int file_number);

char* find_dna_seq(const char* sequence_length_str, unsigned long sequence_length, int file_number);

#endif // SEQUENCE_FILE_READER_H
