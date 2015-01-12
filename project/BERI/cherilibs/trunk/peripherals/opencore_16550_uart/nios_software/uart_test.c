/******************************************************************************
 * Example NIOS code used to run a few tests on the 16550 UART
 ******************************************************************************/

#include "sys/alt_stdio.h"
#include "io.h"
#include "system.h"

// UART TX (W) and RX (R) buffers
#define UART_DATA         0
// UART interrupt enable (RW)
#define UART_INT_ENABLE   1
// UART interrupt identification (R)
#define UART_INT_ID       2
// UART FIFO control (W)
#define UART_FIFO_CTRL    2
// UART Line Control Register (RW)
#define UART_LINE_CTRL    3
// UART Modem Control (W)
#define UART_MODEM_CTRL   4
// UART Line Status (R)
#define UART_LINE_STATUS  5
// UART Modem Status (R)
#define UART_MODEM_STATUS 6
// UART base address of peripheral in NIOS memory map
#define UART_SCRATCH      7

#define UART_BASE OPENCORE_16550_UART_0_BASE


int
reg_mapper(int reg)
{
  return reg<<2;
}


void
UART_write_reg(int reg, int val)
{
  IOWR_8DIRECT(OPENCORE_16550_UART_0_BASE,reg_mapper(reg),val);
}


int
UART_read_reg(int reg)
{
  if((reg<0) || (reg>7)) {
    alt_printf("UART_read_reg - reg=%x is out of range\n",reg);
    return -1;
  } else
    return IORD_8DIRECT(UART_BASE,reg_mapper(reg));
}


void
UART_init(int baud)
{
  int d = ALT_CPU_FREQ / (16 * baud);
  alt_printf("Set divisor to 0x%x\n",d);
  UART_write_reg(UART_LINE_CTRL,0x83);  // access divisor registers
  UART_write_reg(1,d>>8);
  UART_write_reg(0,d & 0xff);
  UART_write_reg(UART_LINE_CTRL,0x03);  // 8-bit data, 1-stop bit, no parity
  UART_write_reg(UART_FIFO_CTRL,0x06);  // interrupt every 1 byte, clear FIFOs
  UART_write_reg(UART_INT_ENABLE,0x00); // disable interrupts
}


int
UART_check_scratch(void)
{
  int j,k,error=0;
  for(j=13; j>=7; j--){
    UART_write_reg(UART_SCRATCH,j);
    k=UART_read_reg(UART_SCRATCH);
    if(k != j) {
      //alt_printf("ERROR: unable to set scratch register to %x read back %x\n",j,k);
      error=1;
    }
  }
  return !error;
}


int main()
{ 

  char c='A';
  int j=0;
  int pause=0;
  if(UART_check_scratch()) {
    alt_putstr("Initialise UART\n");

    UART_init(115200);

    while(1) {
      int status = UART_read_reg(UART_LINE_STATUS);
      int tx_empty = ((status>>5) & 0x1) == 1;
      int rx_ready = (status & 0x1) == 1;
      if(rx_ready) {
	char rx = (char) UART_read_reg(UART_DATA);
	pause = ((rx=='\023') || pause) && !(rx=='\021');
	if((c>='\040') && (c<='\0177')) {
	  UART_write_reg(UART_DATA,rx);	// echo
	  UART_write_reg(UART_DATA,rx ^ ' ');	// echo with case swap
	}
      }
      if(!pause && tx_empty) {
        // alt_putchar(c);
        UART_write_reg(UART_DATA,c);
        c++;
        if(c>='Z') c='A';
	j++;
	if(j>=80) {
	  UART_write_reg(UART_DATA,'\r');
	  UART_write_reg(UART_DATA,'\n');
	  j=0;
	}
      }
    }
  } else {
    alt_printf("Errors while testing the scratch register\n");
  }

  alt_printf("The End\n");
  // Event loop never exits.
  while (1);

  return 0;
}
