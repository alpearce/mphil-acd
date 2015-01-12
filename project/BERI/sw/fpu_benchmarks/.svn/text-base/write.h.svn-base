#ifndef WRITE_H
#define WRITE_H

void writeUARTChar(char c);
void writeString(char* s);
void writeHexDigits(unsigned long long n, unsigned char digits);
void writeHex(unsigned long long n);
void writeHexByte(unsigned char b);
void writeDigit(unsigned long long n);
void writeFloat(float point, char* name, int scale);

#define WRITE_FLOAT(flt, scale) writeFloat(flt, #flt, scale)

#endif
