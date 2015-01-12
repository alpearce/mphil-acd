#include "write.h"
#include "std.h"

static inline float imageXInMandelbrot(uint x) {
    return SCALE * ((float)x / (float)IMG_WIDTH - 0.5f) + CEN_X;
}

static inline float imageYInMandelbrot(uint y) {
    return SCALE * ((float)y / (float)IMG_HEIGHT - 0.5f) + CEN_Y;
}

static int mandelbrotIterations(float x0, float y0) {
    float x = x0, y = y0, xtemp, xsq, ysq;

    uint iterations;
    for (iterations = 0; iterations < MAX_ITERATIONS; ++iterations) {
        xsq = x * x;
        ysq = y * y;
        if (xsq + ysq >= 4.0f) {
            break;
        }
        xtemp = xsq - ysq + x0;
        y = 2.0f * x * y + y0;
        x = xtemp;
    }
    return iterations;
}

void calculateMandelbrotScalar() {
    byte* img = cheriMalloc(IMG_ARRAY_LENGTH);

    TimeUnit start = startTiming();
    
    uint x, y;
    for (x = 0; x < IMG_WIDTH; ++x) {
        for (y = 0; y < IMG_HEIGHT; ++y) {
            float mandelbrotX = imageXInMandelbrot(x);
            float mandelbrotY = imageYInMandelbrot(y);
            int iterations = mandelbrotIterations(mandelbrotX, mandelbrotY);

            byte red = 0;
            byte green = 0x86 - (iterations * 0x86) / MAX_ITERATIONS;
            byte blue = 0xFF - (iterations * 0xFF) / MAX_ITERATIONS;
            setPixel(img, x, y, red, green, blue);
        }
    }
    finishTiming(start);
    outputImage("MANDELBROTSCALAR", img);
}

