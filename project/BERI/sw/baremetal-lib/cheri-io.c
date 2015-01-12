/*
 * Copyright 2012 - INSA Toulouse, France.
 * Written by S. DI MERCURIO
 *
 */

#include "stdio.h"
#include "parameters.h"

#define IO_RD(x) (*(volatile unsigned long long*)(x))
#define IO_RD32(x) (*(volatile int*)(x))
#define IO_WR(x, y) (*(volatile unsigned long long*)(x) = y)
#define IO_WR_BYTE(x, y) (*(volatile unsigned char*)(x) = y)
//#define rdtscl(dest) __asm__ __volatile__("mfc0 %0,$9; nop" : "=r" (dest))

int _read_cheri (char *c, int len);
int _write_cheri (char *c, int len);

_FILE_INIT (_cheri_file, _read_cheri, _write_cheri, 0, 0);

/* Definition of standard files */
FILE	*stdin=&_cheri_file;
FILE	*stdout=&_cheri_file;
FILE	*stderr=&_cheri_file;

//HACK : Forces ld to output a data section which in turn causes it to output a .bss section 
//filled with 0s in the raw binary (Currently don't init .bss at startup so this is needed for correct operation)
int makeBss = 1;

void __writeUARTChar(char c)
{
	//Code for SOPC Builder serial output
	while ((IO_RD32(MIPS_PHYS_TO_UNCACHED(CHERI_JTAG_UART_BASE)+4) &
	    0xFFFF) == 0) {
		asm("add $v0, $v0, $0");
	}
	//int i;
	//for (i=0;i<10000;i++);
	IO_WR_BYTE(MIPS_PHYS_TO_UNCACHED(CHERI_JTAG_UART_BASE), c);
}

void __writeString(char* s)
{
	while(*s)
	{
		__writeUARTChar(*s);
		++s;
	}
}

void __writeHex(unsigned long long n)
{
	unsigned int i;
	for(i = 0;i < 16; ++i)
	{
		unsigned long long hexDigit = (n & 0xF000000000000000L) >> 60L;
//		unsigned long hexDigit = (n & 0xF0000000L) >> 28L;
		char hexDigitChar = (hexDigit < 10) ? ('0' + hexDigit) : ('A' + hexDigit - 10);
		__writeUARTChar(hexDigitChar);
		n = n << 4;
	}
}


void __writeDigit(unsigned long long n)
{
	unsigned int i;
	unsigned int top;
	char tmp[17];
	char str[17];
	
	for(i = 0;i < 17; ++i) str[i] = 0;
	i = 0;
	while(n > 0) {
		tmp[i] = '0' + (n % 10);
		n /= 10;
		i = i + 1;
	}
	i--;
	top = i;
	while(i > 0) {
		str[top - i] = tmp[i];
		i--;
	}
	str[top] = tmp[0];
	__writeString(str);
}


char __readUARTChar()
{
	int i;
	char out;
	//Code for SOPC Builder serial output
	i = IO_RD32(MIPS_PHYS_TO_UNCACHED(CHERI_JTAG_UART_BASE));
//	while((i >> 16) == 0) 
	while((i & 0x00800000) == 0)
	{
		i = IO_RD32(MIPS_PHYS_TO_UNCACHED(CHERI_JTAG_UART_BASE));
		/*
		__writeHex(i);
		__writeString(" and the char:");
		out = (char)i;
		__writeUARTChar(out);
		__writeString("\n");
		*/
	}
	
//	while(i&0x80 == 0) {i = IO_RD(MIPS_PHYS_TO_UNCACHED(CHERI_JTAG_UART_BASE));}
	i = i >> 24;
	out = (char)i;
	return out;
}


int _read_cheri (char *c, int len)
{
	int l=len;
	while (l>0)
	{
		*c=__readUARTChar();
		c++;
		l--;
	}
	return len;
}

int _write_cheri (char *c, int len)
{
	int l=len;
/*	__writeString("__write_cheri: c=");
	__writeHex(c);
	__writeString(" len=");
	__writeHex(len);
	__writeString(" *c=");
	__writeHex(*c);
	__writeUARTChar(10);
*/	while(l>0)
	{
		__writeUARTChar(*c);
//		__writeString(".");
//		__writeHex(*c);
		c++;
		l--;
	}
//	__writeUARTChar(10);
	return len;
}
