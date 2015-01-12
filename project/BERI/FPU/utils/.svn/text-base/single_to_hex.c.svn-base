#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char* argv[]) {
    if (argc != 2) {
        printf("Usage: single_to_hex <floating point value>\n");
        return 1;
    }

    char* end;
    float input = strtod(argv[1], &end);
    if (end != argv[1] + strlen(argv[1])) {
        printf("Not a valid floating point value.\n");
        return 2;
    }

    int* intValue = (int*)&input;
    
    printf("%X\n", *intValue);
    return 0;
}
