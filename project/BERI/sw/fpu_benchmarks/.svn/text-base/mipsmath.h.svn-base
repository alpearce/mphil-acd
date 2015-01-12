#ifndef MIPSMATH_H
#define MIPSMATH_H

extern const float PI;

#ifdef MIPS

#define MONADIC_OP(NAME, OP) \
    static inline float NAME(float input) { \
        float result; \
        asm(#OP " %0, %1" : "=f"(result) : "f"(input)); \
        return result; \
    }

MONADIC_OP(absf, abs.s)
MONADIC_OP(sqrtf, sqrt.s)
//MONADIC_OP(rsqrtf, rsqrt.s)
//MONADIC_OP(recipf, recip.s)

static inline float recipf(float x) { return 1.f / x; }
static inline float rsqrtf(float x) { return recipf(sqrtf(x)); }

#else

#include <math.h>

static inline float absf(float x) { return fabs(x); }
static inline float recipf(float x) { return 1.f / x; }
static inline float rsqrtf(float x) { return recipf(sqrtf(x)); }

#endif

void testforloop();
void testmipsmath();

float cheriSinf(float x);
float cheriCosf(float x);

#endif
