#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sequence_file_reader.h"

char* read_fasta(char* file_name, unsigned long sequence_length) {
    char* seq = malloc(sizeof(char) * (sequence_length + 1));
    *seq = '\0';
    FILE* f = fopen(file_name, "r");

    if (f) {
        char line[100];
        // Skip the first line; the name of the sequence of form ">name"
        (void)(fgets(line, 100UL*sizeof(char), f) + 1);
        while (fgets(line, 100UL*sizeof(char), f)) {
            // Strip newlines
            char* newline_position = strchr(line, '\n');
            if (newline_position != NULL) {
                *newline_position = '\0';
            }
            else {
                printf("A line in %s was too long\n", file_name);
                return NULL;
            }

            strcat(seq, line);
        }
        fclose(f);
    }
    else {
        // printf("Couldn't read %s\n", file_name);
        return NULL;
    }

    return seq;
}
