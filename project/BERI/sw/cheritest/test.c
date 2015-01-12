
extern void __writeString(char* s);
extern void __writeHex(unsigned long long n);
extern void __writeDigit(unsigned long long n);
extern char __readUARTChar();
extern void __writeUARTChar(char c);

#include "../../cherilibs/trunk/include/parameters.h"
#include "dhrystone.c"
#include <stdint.h>
#include <stddef.h>

#define BUTTONS (0x900000007F009000ULL)

#define IO_RD(x) (*(volatile unsigned long long*)(x))
#define IO_RD32(x) (*(volatile int*)(x))
#define IO_WR(x, y) (*(volatile unsigned long long*)(x) = y)
#define IO_WR32(x, y) (*(volatile int*)(x) = y)
#define IO_WR_BYTE(x, y) (*(volatile unsigned char*)(x) = y)
//#define rdtscl(dest) __asm__ __volatile__("mfc0 %0,$9; nop" : "=r" (dest))

#define DIVIDE_ROUND(N, D) (((N) + (D) - 1) / (D))

#define SORT_SIZE (64)

void fillArray(int *A, int n, int seed)
{
	int i;
	int val = seed;
	for (i=0; i<n; i++) {
		val = (val << 10) ^ (val + 10);
		A[i] = val;
	}
}

void swap(int *A, int i, int j) {
	int t = A[i];
	A[i] = A[j];
	A[j] = t;
}

void bubbleSort(int *A, int n)
{
	int newn;
	int i;
	do {
		newn = 0;
		for (i = 1; i <= n-1; i++) {
			if (A[i-1] > A[i]) {
				swap(A, i-1, i);
				/*writeString("Swapped ");
				writeHex(A[i-1]);
				writeString(" and ");
				writeHex(A[i-1]);
				writeString("\n");*/
				newn = i;
			}
		}
		n = newn;
	} while (n != 0);
}

void quickSort(int *arr, int beg, int end)
{
	if (end > beg + 1)
	{
		int piv = arr[beg], l = beg + 1, r = end;
		while (l < r)
		{
			if (arr[l] <= piv)
				l++;
			else {
				/*writeString("Swapped ");
				writeHex(arr[l]);
				writeString(" and ");
				writeHex(arr[r]);
				writeString("\n");*/
				swap(arr, l, --r);
			}
		}
		/*writeString("Swapped ");
		writeHex(arr[l]);
		writeString(" and ");
		writeHex(arr[beg]);
		writeString("\n");*/
		swap(arr, --l, beg);
		quickSort(arr, beg, l);
		quickSort(arr, r, end);
	}
}

int binarySearch(int *arr, int value, int left, int right) {
      while (left <= right) {
            int middle = (left + right) / 2;
            if (arr[middle] == value)
                  return middle;
            else if (arr[middle] > value)
                  right = middle - 1;
            else
                  left = middle + 1;
      }
      return -1;
}

long long mul(long long A, long long B)
{
	return A*B;
}

long long modExp(long long A, long long B)
{
	long long base,power;
	base=A;
	power=B;
	long long result = 1;
	int i;
	for (i = 63; i >= 0; i--) {
		result = mul(result,result);
		if ((power & (1 << i)) != 0) {
			result = mul(result,base);
		}
	}
	return result;
}

int main(void)
{
  int i;
	int j;
  int A[SORT_SIZE];
  __writeString("Branch Exercise:\n");
	__writeString("Starting Dhrystone\n");
	dhrystone();
	__writeString("Done!\n");
  fillArray(A, SORT_SIZE/2, 1000);
  bubbleSort(A, SORT_SIZE/2);
  __writeString("Finished Bubble Sort!\n");
  for (i = 0; i<SORT_SIZE/2; i+= SORT_SIZE/2/32) {
    __writeHex(i);
    __writeString(" = ");
    __writeHex(A[i]);
    __writeString("\n");
  }
  fillArray(A, SORT_SIZE, 1234);
  quickSort(A, 0, SORT_SIZE);
  __writeString("Finished Quick Sort!\n");
  for (i = 0; i<SORT_SIZE; i+= SORT_SIZE/32) {
    __writeHex(i);
    __writeString(" = ");
    __writeHex(A[i]);
    __writeString("\n");
  }
  __writeString("Searching for each element...\n");
  for (j = 0; j<4; j++) {
    for (i = 0; i<SORT_SIZE; i++) {
      binarySearch(A, A[i], 0, SORT_SIZE);
    }
  }
  __writeString("Searching Done.\n");
  __writeString("Starting Modular Eponentiation\n");
  for (i = 0; i<SORT_SIZE/4; i++) {
    __writeHex(modExp(i,0xAAAAAAAAAAAAAAAA));
    __writeString("\n");
  }
	return 0;
}

