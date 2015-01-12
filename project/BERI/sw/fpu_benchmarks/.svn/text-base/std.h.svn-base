#ifndef STD_H
#define STD_H

#ifndef MIPS
#include <time.h>
#endif

typedef unsigned char byte;
typedef unsigned int uint;
typedef unsigned long ulong;

typedef float v4sf __attribute__ ((vector_size (16)));

static inline v4sf newV4sf(float x, float y, float z, float w) {
    return (v4sf){x, y, z, w};
}

static inline v4sf replicateToV4sf(float x) {
    return newV4sf(x, x, x, x);
}

static inline float getV4sfElement(v4sf vec, uint element) {
    return vec[element];
}

extern const uint IMG_WIDTH;
extern const uint IMG_HEIGHT;
extern const uint IMG_ARRAY_LENGTH;

extern const uint DATA_COUNT;

extern const uint MAX_ITERATIONS;
extern const float CEN_X;
extern const float CEN_Y;
extern const float SCALE;

extern const float SPHERE_STEP; 
extern const float PLANE_STEP;

void* cheriMalloc(uint size);

#ifdef MIPS
typedef uint TimeUnit;
#else
typedef struct timespec TimeUnit;
#endif

TimeUnit startTiming();
void finishTiming(TimeUnit startTime);

void setPixel(byte* img, int x, int y, byte r, byte g, byte b);

void outputImage(char* name, const byte* img);

uint cheriRand();

#endif
