#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char* argv[]) {
    if (argc != 2) {
        printf("Usage: hex_to_single <hex value>\n");
        return 1;
    }

    char* end;
    int input = strtol(argv[1], &end, 10);
    if (end != argv[1] + strlen(argv[1])) {
        printf("Not a valid decimal value.\n");
        return 2;
    }

    float* floatValue = (float*)&input;
    
    printf("%f\n", *floatValue);
    return 0;
}
