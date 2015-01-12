#ifndef MIPS
#include <stdio.h>
#endif
#include "std.h"
#include "write.h"
#include "mipsmath.h"

typedef v4sf Vector;

static inline Vector newVector(float x, float y, float z, float w) {
    return newV4sf(x, y, z, w);
}

typedef Vector* Matrix;

static inline void setElement(Matrix matrix, int i, int j, float value) {
    matrix[j][i] = value;
}

static inline float getElement(Matrix matrix, int i, int j) {
    return matrix[j][i];
}

static Matrix newZeroMatrix() {
    Matrix matrix = cheriMalloc(sizeof(v4sf) * 4);
    uint i;
    for (i = 0; i < 4; ++i) {
        matrix[i] = replicateToV4sf(0);
    }
    return matrix;
}

static Matrix newIdentityMatrix() {
    Matrix matrix = newZeroMatrix();
    int i;
    for (i = 0; i < 4; ++i) {
        setElement(matrix, i, i, 1);
    }
    return matrix;
}

static Vector matrixTimesVector(Matrix m, Vector v) {
    v4sf subResult[4];
    for (uint i = 0; i < 4; ++i) {
        subResult[i] = m[i] * replicateToV4sf(getV4sfElement(v, i));
    }
    v4sf result = subResult[0];
    for (uint i = 1; i < 4; ++i) {
        result += subResult[i];
    }
    return result;
}

static Matrix matrixTimesMatrix(Matrix m1, Matrix m2) {
    Matrix result = newZeroMatrix();
    for (uint col = 0; col < 4; ++col) {
        result[col] = matrixTimesVector(m1, m2[col]);
    }
    return result;
}

static Matrix newScaleMatrix(float scalex, float scaley, float scalez) {
    Matrix matrix = newIdentityMatrix();
    setElement(matrix, 0, 0, scalex);
    setElement(matrix, 1, 1, scaley);
    setElement(matrix, 2, 2, scalez);
    return matrix;
}

static Matrix newTranslateMatrix(float x, float y, float z) {
    Matrix matrix = newIdentityMatrix();
    setElement(matrix, 0, 3, x);
    setElement(matrix, 1, 3, y);
    setElement(matrix, 2, 3, z);
    return matrix;
}

static Matrix newRotateXMatrix(float theta) {
    float sinTheta = cheriSinf(theta);
    float cosTheta = cheriCosf(theta);

    Matrix matrix = newIdentityMatrix();
    setElement(matrix, 1, 1, cosTheta);
    setElement(matrix, 1, 2, -sinTheta);
    setElement(matrix, 2, 1, sinTheta);
    setElement(matrix, 2, 2, cosTheta);
    return matrix;
}

static Matrix newRotateYMatrix(float theta) {
    float sinTheta = cheriSinf(theta);
    float cosTheta = cheriCosf(theta);

    Matrix matrix = newIdentityMatrix();
    setElement(matrix, 0, 0, cosTheta);
    setElement(matrix, 2, 0, -sinTheta);
    setElement(matrix, 0, 2, sinTheta);
    setElement(matrix, 2, 2, cosTheta);
    return matrix;
}

static Matrix newRotateZMatrix(float theta) {
    float sinTheta = cheriSinf(theta);
    float cosTheta = cheriCosf(theta);

    Matrix matrix = newIdentityMatrix();
    setElement(matrix, 0, 0, cosTheta);
    setElement(matrix, 0, 1, -sinTheta);
    setElement(matrix, 1, 0, sinTheta);
    setElement(matrix, 1, 1, cosTheta);
    return matrix;
}

static Matrix newProjectMatrix() {
    Matrix matrix = newIdentityMatrix();
    setElement(matrix, 3, 2, 1);
    setElement(matrix, 3, 3, 0);
    return matrix;
}

/*#ifdef MIPS*/
void printVector(Vector v) {
    for (int i = 0; i < 4; ++i) {
        WRITE_FLOAT(v[i], 1000);
    }
}

void printMatrix(Matrix m) {
    for (int row = 0; row < 4; ++row) {
        for (int col = 0; col < 4; ++col) {
            WRITE_FLOAT(getElement(m, row, col), 1000);
        }
        writeString("\n");
    }
}


/*#else*/
/*void printVector(Vector v) {*/
    /*printf("Vector (%f, %f, %f, %f)\n", v[0], v[1], v[2], v[3]);*/
/*}*/

/*void printMatrix(Matrix m) {*/
    /*for (int row = 0; row < 4; ++row) {*/
        /*for (int col = 0; col < 4; ++col) {*/
            /*printf("%f ", getElement(m, row, col));*/
        /*}*/
        /*printf("\n");*/
    /*}*/
    /*printf("\n");*/
/*}*/
/*#endif*/

static void drawPoint(byte* img, Matrix transform, Vector p, byte r, byte g, byte b) {
    p = matrixTimesVector(transform, p);
    int x = (int)(getV4sfElement(p, 0) / getV4sfElement(p, 3));
    int y = (int)(getV4sfElement(p, 1) / getV4sfElement(p, 3));
    setPixel(img, x, y, r, g, b);
}

static void drawCircle(byte* img, Matrix transform, byte r, byte g, byte b) {
    float theta;
    for (theta = 0.f; theta <= PI + SPHERE_STEP / 2.f; theta += SPHERE_STEP) {
        float x = cheriSinf(theta);
        float y = cheriCosf(theta);
        Vector p1 = newVector(x, y, 0, 1);
        Vector p2 = newVector(-x, y, 0, 1);
        drawPoint(img, transform, p1, r, g, b);
        drawPoint(img, transform, p2, r, g, b);
    }
}

static void drawPlane(byte* img, Matrix transform, byte r, byte g, byte b) {
    float x, z;
    for (x = -1.0f; x <= 1.0f; x += PLANE_STEP) {
        for (z = -1.0f; z <= 1.0f; z += PLANE_STEP) {
            drawPoint(img, transform, newVector(x, 0, z, 1), r, g, b);
        }
    }
}

static void drawSphere(byte* img, Matrix transform, byte r, byte g, byte b) {
    int count = 0;
    float rho;
    for (rho = 0.f; rho < PI / 2.f; rho += SPHERE_STEP) {
        ++count;
        float z = cheriCosf(rho);
        float radius = cheriSinf(rho);

        Matrix shiftZ = newTranslateMatrix(0, 0, z);
        Matrix shiftNegZ = newTranslateMatrix(0, 0, -z);
        Matrix scale = matrixTimesMatrix(transform, newScaleMatrix(radius, radius, 1));

        drawCircle(img, matrixTimesMatrix(scale, shiftZ), r, g, b);
        drawCircle(img, matrixTimesMatrix(scale, shiftNegZ), r, g, b);
    }
}


void runProjectionBenchmarkVectorised() {
    byte* img = cheriMalloc(IMG_ARRAY_LENGTH);

    uint x, y;
    for (x = 0; x < IMG_WIDTH; x += 1) {
        for (y = 0; y < IMG_HEIGHT; y += 1) {
            setPixel(img, x, y, 255, 255, 255);
        }
    }

    TimeUnit start = startTiming();

    Matrix project = newIdentityMatrix();
    project = matrixTimesMatrix(newRotateXMatrix(- PI / 6), project);
    project = matrixTimesMatrix(newTranslateMatrix(0, -1, 0), project);
    project = matrixTimesMatrix(newProjectMatrix(), project);
    project = matrixTimesMatrix(newScaleMatrix(IMG_WIDTH / 2, IMG_WIDTH / 2, 0), project);
    project = matrixTimesMatrix(newTranslateMatrix(IMG_HEIGHT / 2, IMG_WIDTH / 2, 0), project);

    Matrix planeTrans = matrixTimesMatrix(project, matrixTimesMatrix(newTranslateMatrix(0, -1, 20), newScaleMatrix(20, 1, 20)));
    Matrix orangeSphereTrans = newTranslateMatrix(1, 0, 9);
    Matrix blueSphereTrans = newTranslateMatrix(0, 0, 6);
    Matrix greenSphereTrans = newTranslateMatrix(-1, 0, 3);

    drawPlane(img, planeTrans, 0, 0, 0);
    drawSphere(img, matrixTimesMatrix(project, orangeSphereTrans), 255, 120, 20);
    drawSphere(img, matrixTimesMatrix(project, blueSphereTrans), 20, 120, 255);
    drawSphere(img, matrixTimesMatrix(project, greenSphereTrans), 20, 255, 120);

    finishTiming(start);

    outputImage("PROJECT", img);
}
