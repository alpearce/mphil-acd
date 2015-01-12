#include "std.h"
#include "write.h"

// General image producing constants
const uint IMG_WIDTH = 200;
const uint IMG_HEIGHT = 200;
const uint IMG_ARRAY_LENGTH = 3 * 200 * 200;

/*const uint IMG_WIDTH = 32;*/
/*const uint IMG_HEIGHT = 32;*/
/*const uint IMG_ARRAY_LENGTH = 3 * 32 * 32;*/

// Array data length
const uint DATA_COUNT = 2000000;

// Mandelbrot constants
/*const uint MAX_ITERATIONS = 25;*/
const uint MAX_ITERATIONS = 255;
const float CEN_X = -0.75f;
const float CEN_Y = 0.f;
const float SCALE = 3.f;

// Projection constants
const float SPHERE_STEP = 3.1415927f / 256;
const float PLANE_STEP = 0.003;

#ifdef MIPS
unsigned long long malloc_start = 0x9800000001000000;
void* cheriMalloc(uint size) {
    void* address = (void*)malloc_start;
    if (size % 8 != 0) 
        size = 8 * (size / 8 + 1); //So we are double aligned
    malloc_start += size;
    return address;
}
#else
#include <stdio.h>
#include <stdlib.h>

void* cheriMalloc(uint size) {
    return malloc(size);
}
#endif

TimeUnit currentTime() {
    TimeUnit count;
#ifdef MIPS
    asm ("mfc0 %0, $9, 0" : "=r"(count));
#else
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &count);
#endif
    return count;
}

TimeUnit startTiming() {
    return currentTime();
}

void finishTiming(TimeUnit startTime) {
#ifdef MIPS
    TimeUnit diff = currentTime() - startTime;
    writeString("Took "); writeDigit(diff); writeString(" cycles.\n");
    writeString("That's "); writeDigit(diff / 100000); writeString(" milliseconds.\n");
#else
    TimeUnit end;
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &end);
    double time = (end.tv_sec - startTime.tv_sec) * 1000.0;
    time += (end.tv_nsec - startTime.tv_nsec) / 1000000.0;
    printf("Took %f milliseconds.\n", time);
#endif
}

void setPixel(byte* img, int x, int y, byte r, byte g, byte b) {
    /*writeString("setPixel "); writeDigit(x); writeString(","); writeDigit(y);*/
    /*writeString(" to ("); writeHexByte(r); writeString(", "); writeHexByte(g);*/
    /*writeString(", "); writeHexByte(b); writeString(")\n");*/
    if (x >= 0 && x < (int)IMG_WIDTH && y >= 0 && y < (int)IMG_HEIGHT) {
        int pixel_start = 3 * (IMG_WIDTH * y + x);
        img[pixel_start] = r;
        img[pixel_start + 1] = g;
        img[pixel_start + 2] = b;
    }
}

void outputImage(char* name, const byte* img) {
#ifdef OUTPUT_IMAGE
    writeString("START");
    writeString(name);
    writeString(" ");
    for (uint i = 0; i < IMG_ARRAY_LENGTH; ++i) {
        writeHexByte(img[i]);
    }
    writeString("END\n");
#endif
}

const uint randMax = -1;
const uint randMult = 1664525;
const uint randAdd = 1013904223;
uint currentRand = 1;

uint cheriRand() {
    currentRand = randMult * currentRand + randAdd;
    return currentRand;
}
