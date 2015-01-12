#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    unsigned int first;
    unsigned int second;
} UIntPair;

typedef union {
    double d;
    UIntPair uip;
} UIntAndDouble;

int main(int argc, char* argv[]) {
    if (argc != 2) {
        printf("Usage: double_to_hex <floating point value>\n");
        return 1;
    }

    char* end;
    UIntAndDouble in;
    in.d = strtod(argv[1], &end);
    if (end != argv[1] + strlen(argv[1])) {
        printf("Not a valid floating point value.\n");
        return 2;
    }

    printf("%08X%08X", in.uip.second, in.uip.first);
    return 0;
}
