#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

typedef struct {
    unsigned int first;
    unsigned int second;
} UIntPair;

typedef union {
    double d;
    uint64_t l;
} LongAndDouble;

int main(int argc, char* argv[]) {
    if (argc != 2) {
        printf("Usage: double_to_hex <floating point value>\n");
        return 1;
    }

    char* end;
    LongAndDouble input;
    input.l = strtol(argv[1], &end, 16);
    if (end != argv[1] + strlen(argv[1])) {
        printf("Not a valid hexadecimal value.\n");
        return 2;
    }

    printf("%f\n", input.d);
}
