/*****************************************************************************
 * Example for NIOS that uses the I2C interface to control the HDMI chip
 * =====================================================================
 * Simon Moore, Nov 2012
 *****************************************************************************/


/* Altera's notes on small footprint code
 * ======================================
 * 
 * This example prints 'Hello from Nios II' to the STDOUT stream. It runs on
 * the Nios II 'standard', 'full_featured', 'fast', and 'low_cost' example 
 * designs. It requires a STDOUT  device in your system's hardware. 
 *
 * The purpose of this example is to demonstrate the smallest possible Hello 
 * World application, using the Nios II HAL library.  The memory footprint
 * of this hosted application is ~332 bytes by default using the standard 
 * reference design.  For a more fully featured Hello World application
 * example, see the example titled "Hello World".
 *
 * The memory footprint of this example has been reduced by making the
 * following changes to the normal "Hello World" example.
 * Check in the Nios II Software Developers Manual for a more complete 
 * description.
 * 
 * In the SW Application project (small_hello_world):
 *
 *  - In the C/C++ Build page
 * 
 *    - Set the Optimization Level to -Os
 * 
 * In System Library project (small_hello_world_syslib):
 *  - In the C/C++ Build page
 * 
 *    - Set the Optimization Level to -Os
 * 
 *    - Define the preprocessor option ALT_NO_INSTRUCTION_EMULATION 
 *      This removes software exception handling, which means that you cannot 
 *      run code compiled for Nios II cpu with a hardware multiplier on a core 
 *      without a the multiply unit. Check the Nios II Software Developers 
 *      Manual for more details.
 *
 *  - In the System Library page:
 *    - Set Periodic system timer and Timestamp timer to none
 *      This prevents the automatic inclusion of the timer driver.
 *
 *    - Set Max file descriptors to 4
 *      This reduces the size of the file handle pool.
 *
 *    - Check Main function does not exit
 *    - Uncheck Clean exit (flush buffers)
 *      This removes the unneeded call to exit when main returns, since it
 *      won't.
 *
 *    - Check Don't use C++
 *      This builds without the C++ support code.
 *
 *    - Check Small C library
 *      This uses a reduced functionality C library, which lacks  
 *      support for buffering, file IO, floating point and getch(), etc. 
 *      Check the Nios II Software Developers Manual for a complete list.
 *
 *    - Check Reduced device drivers
 *      This uses reduced functionality drivers if they're available. For the
 *      standard design this means you get polled UART and JTAG UART drivers,
 *      no support for the LCD driver and you lose the ability to program 
 *      CFI compliant flash devices.
 *
 *    - Check Access device drivers directly
 *      This bypasses the device file system to access device drivers directly.
 *      This eliminates the space required for the device file system services.
 *      It also provides a HAL version of libc services that access the drivers
 *      directly, further reducing space. Only a limited number of libc
 *      functions are available in this configuration.
 *
 *    - Use ALT versions of stdio routines:
 *
 *           Function                  Description
 *        ===============  =====================================
 *        alt_printf       Only supports %s, %x, and %c ( < 1 Kbyte)
 *        alt_putstr       Smaller overhead than puts with direct drivers
 *                         Note this function doesn't add a newline.
 *        alt_putchar      Smaller overhead than putchar with direct drivers
 *        alt_getchar      Smaller overhead than getchar with direct drivers
 *
 */

#include "sys/alt_stdio.h"
#include "system.h"
#include "io.h"


// Helper functions to access I2C

// base address from system.h
#define I2C_BASE I2C_AVALON_0_BASE

// I2C device number of IT6613 HDMI chip
// note: the device number is the upper 7-bits and bit 0 is left to indicate
//       read or write
#define HDMI_I2C_DEV  0x98

// clock scale factor to get target 100kHz:  scale = system_clock_kHz/(4*100)
#define I2C_CLK_SCALE 250


void
reset_hdmi_chip(void)
{
  IOWR_32DIRECT(HDMI_TX_RESET_N_BASE, 0, 0);
  alt_printf("Reset HDMI chip");  // debug output and delay all in one...
  IOWR_32DIRECT(HDMI_TX_RESET_N_BASE, 0, 1);
}


void
i2c_write_reg(int regnum, int data)
{
  IOWR_8DIRECT(I2C_BASE, regnum, data);
}


int
i2c_read_reg(int regnum)
{
  return IORD_8DIRECT(I2C_BASE, regnum);
}


void
i2c_write_clock_scale(int scale)  // scale is 16-bit number
{
  i2c_write_reg(0, scale & 0xff);
  i2c_write_reg(1, scale >> 8);
}


int
i2c_read_clock_scale(void)
{
  return i2c_read_reg(0) | (i2c_read_reg(1)<<8);
}


void i2c_write_control(int d) { i2c_write_reg(2, d); }
void i2c_write_tx_data(int d) { i2c_write_reg(3, d); }
void i2c_write_command(int d) { i2c_write_reg(4, d); }

int i2c_read_control() { return i2c_read_reg(2); }
int i2c_read_rx_data() { return i2c_read_reg(3); }
int i2c_read_status () { return i2c_read_reg(4); }
int i2c_read_tx_data() { return i2c_read_reg(5); }
int i2c_read_command() { return i2c_read_reg(6); }


int
i2c_write_data_command(int data, int command)
{
  int t, sr;
  // alt_printf("i2c write data=%x, command=%x\n",data,command);
  i2c_write_tx_data(data); // device num + write (=0) bit
  i2c_write_command(command);
  sr = i2c_read_status();
  if((sr & 0x02)==0)
    alt_printf("ERROR - I2C should be busy but isn't - sr=%x\n",sr);

  for(t=100*I2C_CLK_SCALE; (t>0) && ((sr & 0x02)!=0); t--)
    sr = i2c_read_status();

  if(t==0)
    alt_putstr("WRITE TIME OUT\n");
  if((sr & 0x02)!=0)
    alt_putstr("ERROR - transfer is not complete\n");
  if((sr&0x80)!=0)
    alt_putstr("ERROR - no ack received\n");
  return sr;
}


int
hdmi_read_reg(int i2c_addr)
{
  int t, sr;
  // write data: (7-bit address, 1-bit 0=write)
  // command: STA (start condition, bit 7) + write (bit 4)
  sr = i2c_write_data_command(HDMI_I2C_DEV, 0x90);
  sr = i2c_write_data_command(i2c_addr, 0x10);

  // now start the read (with STA and WR bits)
  sr = i2c_write_data_command(HDMI_I2C_DEV | 0x01, 0x90);
  // set RD bit, set ACK to '1' (NACK), set STO bit
  i2c_write_command(0x20 | 0x08 | 0x40);

  for(t=100*I2C_CLK_SCALE,sr=2; (t>0) && ((sr & 0x02)!=0); t--)
    sr = i2c_read_status();
  if(t==0)
    alt_printf("READ TIME OUT  -  sr=%x\n",sr);
  if((sr & 0x02)!=0)
    alt_putstr("ERROR - transfer is not complete\n");
  if((sr&0x80)==0)
    alt_putstr("ERROR - no nack received\n");
  return i2c_read_rx_data();
}


void
hdmi_write_reg(int i2c_addr, int i2c_data_byte)
{
  int sr;
  // write data: (7-bit address, 1-bit 0=write)
  // command: STA (start condition, bit 7) + write (bit 4)
  sr = i2c_write_data_command(HDMI_I2C_DEV, 0x90);
  // command=write
  sr = i2c_write_data_command(i2c_addr, 0x10);
  // command=write+STO (stop)
  sr = i2c_write_data_command(i2c_data_byte & 0xff, 0x50);
}


void
configure_hdmi(void)
{
  // set clock scale factor = system_clock_freq_in_Khz / 400
  {
    int j;
    alt_printf("Setting clock_scale to 0x%x\n",I2C_CLK_SCALE);
    i2c_write_clock_scale(I2C_CLK_SCALE);
    j = i2c_read_clock_scale();
    alt_printf("clock scale = 0x%x",j);
    if(j==I2C_CLK_SCALE)
      alt_printf(" - passed\n");
    else
      alt_printf(" - FAILED\n");

    hdmi_write_reg(0x0f, 0); // switch to using lower register bank (needed after a reset?)

    j = hdmi_read_reg(1);
    if(j==0xca)
      alt_printf("Correct vendor ID\n");
    else
      alt_printf("FAILED - Vendor ID=0x%x but should be 0xca\n",j);

    j = hdmi_read_reg(2) | ((hdmi_read_reg(3) & 0xf)<<8);
    if(j==0x613)
      alt_printf("Correct device ID\n");
    else
      alt_printf("FAILED - Device ID=0x%x but should be 0x613\n",j);
  }

  // the following HDMI sequence is based on Chapter 2 of
  // the IT6613 Programming Guide

  // HDMI: reset internal circuits via its reg04 register
  hdmi_write_reg(4, 0xff);
  hdmi_write_reg(4, 0x00); // release resets
  // hdmi_write_reg(4, 0x1d); - from reg dump

  // HDMI: enable clock ring
  hdmi_write_reg(61, 0x10);  // seems to read as 0x30 on "correct" version?

  // HDMI: set default DVI mode
  {
    int reg;
    for(reg=0xc0; reg<=0xd0; reg++)
      hdmi_write_reg(reg, 0x00);
  }
  // setting from reg dump - makes any sense?
  hdmi_write_reg(0xc3, 0x08);

  // blue screen:
  // hdmi_write_reg(0xc1, 2);

  // HDMI: write protection of C5 register?  needed?
  hdmi_write_reg(0xf8, 0xff);

  // HDMI: disable all interrupts via mask bits
  hdmi_write_reg(0x09, 0xff);
  hdmi_write_reg(0x0a, 0xff);
  hdmi_write_reg(0x0b, 0xff);
  // ...and clear any pending interrupts
  hdmi_write_reg(0x0c, 0xff);
  hdmi_write_reg(0x0d, 0xff);

  // setup interrupt status reg as per reg dump
  // hdmi_write_reg(0x0e, 0x6e);
  hdmi_write_reg(0x0e, 0x00);  // SWM: better to leave as zero?


  // HDMI: set VIC=3, ColorMode=0, Bool16x9=1, ITU709=0
  // HDMI: set RGB444 mode
  //  hdmi_write_reg(0x70, 0x08); // no input data formatting, but sync embedded
  hdmi_write_reg(0x70, 0x0); // no input data formatting, but sync embedded
  hdmi_write_reg(0x72, 0); // no input data formatting
  hdmi_write_reg(0x90, 0); // no sync generation

  {
    int sum = 0;
    // HDMI: construct AVIINFO (video frame information)
    hdmi_write_reg(0x0f, 1); // switch to using upper register bank
    if(hdmi_read_reg(0x0f)!=1)
      alt_printf("ASSERTION ERROR: not using correct register bank (see reg 0x0f)\n");
    hdmi_write_reg(0x58, 0x10); //=0 for DVI mode   - (1<<4) // AVIINFO_DB1 = 0?
    sum += 0x10;
      //    hdmi_write_reg(0x59, 8 | (2<<4)); // AVIINFO_DB2 = 8 | (!b16x9)?(1<<4):(2<<4)
      //    sum += (8 | (2<<4));
    hdmi_write_reg(0x59, 0x68); // AVIINFO_DB2 = from reg dump
    sum += 0x68;
    hdmi_write_reg(0x5a, 0); // AVIINFO_DB3 = 0
    hdmi_write_reg(0x5b, 3); // AVIINFO_DB4 = VIC = 3
    sum +=3;
    hdmi_write_reg(0x5c, 0); // AVIINFO_DB5 = pixelrep & 3 = 0
    // 0x5d = checksum - see below
    hdmi_write_reg(0x5e, 0); // AVIINFO_DB6
    hdmi_write_reg(0x5f, 0); // AVIINFO_DB7
    hdmi_write_reg(0x60, 0); // AVIINFO_DB8
    hdmi_write_reg(0x61, 0); // AVIINFO_DB9
    hdmi_write_reg(0x62, 0); // AVIINFO_DB10
    hdmi_write_reg(0x63, 0); // AVIINFO_DB11
    hdmi_write_reg(0x64, 0); // AVIINFO_DB12
    hdmi_write_reg(0x65, 0); // AVIINFO_DB13
    alt_printf("check: VIC = 0x%x\n",hdmi_read_reg(0x5b));
    // from docs:    hdmi_write_reg(0x5d, - (sum + 0x82 + 2 + 0x0d));
    // from Teraic code: hdmi_write_reg(0x5d, -sum - (2 + 1 + 13));
    // from reg dump:
    hdmi_write_reg(0x5d, 0xf4);
    alt_printf("check: checksum = 0x%x\n",hdmi_read_reg(0x5b));
  }
  hdmi_write_reg(0x0f, 0); // switch to using lower register bank
  hdmi_write_reg(0xcd, 3); // enable avi information packet

  // unmute screen? - correct?
  //hdmi_write_reg(0xc1, 0x41);
  hdmi_write_reg(0xc1, 0x00);

  // disable audio
  hdmi_write_reg(0xe0, 0x08);
  // needed? - part of audio format...
  hdmi_write_reg(0xe1, 0x0);

  alt_printf("Completed HDMI initialisation\n");
  /*
  {
    int reg;
    hdmi_write_reg(0x0f, 0); // switch to using lower register bank
    for(reg=0; reg<0xff; reg++)
      alt_printf("reg[%x] = %x\n",reg,hdmi_read_reg(reg));
    hdmi_write_reg(0x0f, 1); // switch to using upper register bank
    for(reg=0; reg<0xff; reg++)
      alt_printf("reg[b1 %x] = %x\n",reg,hdmi_read_reg(reg));
    hdmi_write_reg(0x0f, 0); // switch to using lower register bank
  }
  */
}


void
brute_force_write_seq(void)
{
  // set clock scale factor = system_clock_freq_in_Khz / 400
  {
    int j;
    alt_printf("Setting clock_scale to 0x%x\n",I2C_CLK_SCALE);
    i2c_write_clock_scale(I2C_CLK_SCALE);
    j = i2c_read_clock_scale();
    alt_printf("clock scale = 0x%x",j);
    if(j==I2C_CLK_SCALE)
      alt_printf(" - passed\n");
    else
      alt_printf(" - FAILED\n");

    hdmi_write_reg(0x0f, 0); // switch to using lower register bank (needed after a reset?)

    j = hdmi_read_reg(1);
    if(j==0xca)
      alt_printf("Correct vendor ID\n");
    else
      alt_printf("FAILED - Vendor ID=0x%x but should be 0xca\n",j);

    j = hdmi_read_reg(2) | ((hdmi_read_reg(3) & 0xf)<<8);
    if(j==0x613)
      alt_printf("Correct device ID\n");
    else
      alt_printf("FAILED - Device ID=0x%x but should be 0x613\n",j);
  }

hdmi_write_reg(0x5, 0x0);
hdmi_write_reg(0x4, 0x3d);
hdmi_write_reg(0x4, 0x1d);
hdmi_write_reg(0x61, 0x30);
hdmi_write_reg(0x9, 0xb2);
hdmi_write_reg(0xa, 0xf8);
hdmi_write_reg(0xb, 0x37);
hdmi_write_reg(0xf, 0x0);
hdmi_write_reg(0xc9, 0x0);
hdmi_write_reg(0xca, 0x0);
hdmi_write_reg(0xcb, 0x0);
hdmi_write_reg(0xcc, 0x0);
hdmi_write_reg(0xcd, 0x0);
hdmi_write_reg(0xce, 0x0);
hdmi_write_reg(0xcf, 0x0);
hdmi_write_reg(0xd0, 0x0);
hdmi_write_reg(0xe1, 0x0);
hdmi_write_reg(0xf, 0x0);
hdmi_write_reg(0xf8, 0xc3);
hdmi_write_reg(0xf8, 0xa5);
hdmi_write_reg(0x22, 0x60);
hdmi_write_reg(0x1a, 0xe0);
hdmi_write_reg(0x22, 0x48);
hdmi_write_reg(0xf8, 0xff);
hdmi_write_reg(0x4, 0x1d);
hdmi_write_reg(0x61, 0x30);
hdmi_write_reg(0xc, 0xff);
hdmi_write_reg(0xd, 0xff);
hdmi_write_reg(0xe, 0xcf);
hdmi_write_reg(0xe, 0xce);
hdmi_write_reg(0x10, 0x1);
hdmi_write_reg(0x15, 0x9);
hdmi_write_reg(0xf, 0x0);
hdmi_write_reg(0x10, 0x1);
hdmi_write_reg(0x15, 0x9);
hdmi_write_reg(0x10, 0x1);
hdmi_write_reg(0x11, 0xa0);
hdmi_write_reg(0x12, 0x0);
hdmi_write_reg(0x13, 0x20);
hdmi_write_reg(0x14, 0x0);
hdmi_write_reg(0x15, 0x3);
hdmi_write_reg(0x10, 0x1);
hdmi_write_reg(0x15, 0x9);
hdmi_write_reg(0x10, 0x1);
hdmi_write_reg(0x11, 0xa0);
hdmi_write_reg(0x12, 0x20);
hdmi_write_reg(0x13, 0x20);
hdmi_write_reg(0x14, 0x0);
hdmi_write_reg(0x15, 0x3);
hdmi_write_reg(0x10, 0x1);
hdmi_write_reg(0x15, 0x9);
hdmi_write_reg(0x10, 0x1);
hdmi_write_reg(0x11, 0xa0);
hdmi_write_reg(0x12, 0x40);
hdmi_write_reg(0x13, 0x20);
hdmi_write_reg(0x14, 0x0);
hdmi_write_reg(0x15, 0x3);
hdmi_write_reg(0x10, 0x1);
hdmi_write_reg(0x15, 0x9);
hdmi_write_reg(0x10, 0x1);
hdmi_write_reg(0x11, 0xa0);
hdmi_write_reg(0x12, 0x60);
hdmi_write_reg(0x13, 0x20);
hdmi_write_reg(0x14, 0x0);
hdmi_write_reg(0x15, 0x3);
hdmi_write_reg(0x4, 0x1d);
hdmi_write_reg(0x61, 0x30);
hdmi_write_reg(0xf, 0x0);
hdmi_write_reg(0xc1, 0x41);
hdmi_write_reg(0xf, 0x1);
hdmi_write_reg(0x58, 0x10);
hdmi_write_reg(0x59, 0x68);
hdmi_write_reg(0x5a, 0x0);
hdmi_write_reg(0x5b, 0x3);
hdmi_write_reg(0x5c, 0x0);
hdmi_write_reg(0x5e, 0x0);
hdmi_write_reg(0x5f, 0x0);
hdmi_write_reg(0x60, 0x0);
hdmi_write_reg(0x61, 0x0);
hdmi_write_reg(0x62, 0x0);
hdmi_write_reg(0x63, 0x0);
hdmi_write_reg(0x64, 0x0);
hdmi_write_reg(0x65, 0x0);
hdmi_write_reg(0x5d, 0xf4);
hdmi_write_reg(0xf, 0x0);
hdmi_write_reg(0xcd, 0x3);
hdmi_write_reg(0xf, 0x0);
hdmi_write_reg(0xf, 0x1);
hdmi_write_reg(0xf, 0x0);
hdmi_write_reg(0x4, 0x1d);
hdmi_write_reg(0x70, 0x0);
hdmi_write_reg(0x72, 0x0);
hdmi_write_reg(0xc0, 0x0);
hdmi_write_reg(0x4, 0x15);
hdmi_write_reg(0x61, 0x10);
hdmi_write_reg(0x62, 0x18);
hdmi_write_reg(0x63, 0x10);
hdmi_write_reg(0x64, 0xc);
hdmi_write_reg(0x4, 0x15);
hdmi_write_reg(0x4, 0x15);
hdmi_write_reg(0xc, 0x0);
hdmi_write_reg(0xd, 0x40);
hdmi_write_reg(0xe, 0x1);
hdmi_write_reg(0xe, 0x0);
hdmi_write_reg(0xf, 0x0);
hdmi_write_reg(0x61, 0x0);
hdmi_write_reg(0xf, 0x0);
hdmi_write_reg(0xc1, 0x40);
hdmi_write_reg(0xc6, 0x3);
}

int
main()
{ 
  alt_putstr("Test I2C on HDMI chip\n");
  // reset HDMI chip via PIO output pin
  reset_hdmi_chip();

  // enable i2c device but leave interrupts off for now
  i2c_write_control(0x80);

  /*
  {
    int j;
    for(j=0; j<4; j++)
      configure_hdmi();
  }
  */
  brute_force_write_seq();

  /* Event loop never exits. */
  while (1);

  return 0;
}
