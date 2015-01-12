#include "std.h"

#include <IL/il.h>

#include <stdio.h>
#include <stdlib.h>

int main(int argc, char* argv[]) {
    if (argc != 3) {
        printf("Usage: %s <input data file> <output image file>", argv[0]);
    }

    byte* img = malloc(IMG_ARRAY_LENGTH);
    ilInit();

    uint pos = 0;
    FILE* dataFile = fopen(argv[1], "r");
    while (fscanf(dataFile, "%2hhx", &(img[pos++])) == 1) { }
    fclose(dataFile);

    ilTexImage(IMG_WIDTH, IMG_HEIGHT, 0, 3, IL_RGB, IL_UNSIGNED_BYTE, img);
    ilSaveImage(argv[2]);
}
