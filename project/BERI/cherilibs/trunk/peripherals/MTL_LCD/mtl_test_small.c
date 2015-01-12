/*-
 * Copyright (c) 2012 Simon W. Moore
 * All rights reserved.
 *
 * This software was developed by SRI International and the University of
 * Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-10-C-0237
 * ("CTSRD"), as part of the DARPA CRASH research programme.
 *
 * @BERI_LICENSE_HEADER_START@
 *
 * Licensed to BERI Open Systems C.I.C. (BERI) under one or more contributor
 * license agreements.  See the NOTICE file distributed with this work for
 * additional information regarding copyright ownership.  BERI licenses this
 * file to you under the BERI Hardware-Software License, Version 1.0 (the
 * "License"); you may not use this file except in compliance with the
 * License.  You may obtain a copy of the License at:
 *
 *   http://www.beri-open-systems.org/legal/license-1-0.txt
 *
 * Unless required by applicable law or agreed to in writing, Work distributed
 * under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * @BERI_LICENSE_HEADER_END@
 *
 *****************************************************************************

 Description:
 - Nios II soft-core code to tests the MTL_LCD_Driver.
   - built using small libraries since it was run in just 64K of
     on-FPGA memory.
 - Displays one and two touch inputs as red and green lines.
 - Screen is cleared by toching the top left corner.
 - The number of touches is displayed in text using the text frame buffer.
 - Test the Flash soldered to the DE4 board.  Various reuable routines
   for locking/unlocking, erasing, obtaining status, etc. 
 *****************************************************************************/


#include "sys/alt_stdio.h"
#include <alt_types.h>
#include <system.h>
#include <io.h>

// position of the framebuffer from system.h:
#define MTL_FRAMEBUFFER_BASE    FRAMEBUFFER_FLASH_BASE
// length of the SSRAM based framebuffer
#define MTL_FRAMEBUFFER_LENGTH  (1<<21)
// position of the control registers
#define MTL_CONTROL_REG         (MTL_FRAMEBUFFER_BASE+MTL_FRAMEBUFFER_LENGTH*2)
#define MTL_PIXELBUFFER_LENGTH  (800*480*4)
// default position for the character buffer (which can be moved)
#define MTL_CHARBUFFER_BASE     (MTL_FRAMEBUFFER_BASE+MTL_PIXELBUFFER_LENGTH)
#define MTL_CHARBUFFER_LENGTH   (100*40*2)

#define MTL_FLASH_BASE          (FRAMEBUFFER_FLASH_BASE + 0x04000000)


void lcd_blend(int col_overlay, int alpha_pixel, int alpha_textfg, int alpha_textbg)
{
  col_overlay = col_overlay & 0xf;
  alpha_pixel = alpha_pixel & 0xff;
  alpha_textfg = alpha_textfg & 0xff;
  alpha_textbg = alpha_textbg & 0xff;
  IOWR_32DIRECT(MTL_CONTROL_REG,0*4,(col_overlay<<24) | (alpha_pixel<<16) | (alpha_textfg<<8) | alpha_textbg);
}

void lcd_cursor_pos(int x, int y)
{
  IOWR_32DIRECT(MTL_CONTROL_REG,1*4,((x&0xff)<<8) | (y&0xff));
}

void lcd_clear_screen(int colour)
{
  int offset;
  // zero the whole buffer
  for(offset=0; offset<MTL_PIXELBUFFER_LENGTH; offset+=4)
    IOWR_32DIRECT(MTL_FRAMEBUFFER_BASE,offset,colour);
  // write spaces in character buffer 4 at a time
  for(offset=0; offset<MTL_CHARBUFFER_LENGTH; offset+=4)
    IOWR_32DIRECT(MTL_CHARBUFFER_BASE,offset,0x20202020);
}


void lcd_putmsg_top(char* s)
{
  int j;
  char* char_buf = (char*) (MTL_CHARBUFFER_BASE | 0x80000000); // none cachable address
  for(j=0; (j<100) && (s[j]!='\0'); j++) {
    char_buf[j*2] = s[j];
    char_buf[j*2+1] = 0x0f;
  }
  for(; (j<100); j++) {
    char_buf[j*2] = ' ';
    char_buf[j*2+1] = 0x0f;
  }
}


void lcd_put_alphabet(int vga_text_col)
{
  char * charfb = (char*) ((MTL_FRAMEBUFFER_BASE + 800*480*4) | 0x80000000);
  char c='A';
  int j;
  for(j=0; j<40*100; j++) {
    charfb[j*2] = c;
    charfb[j*2+1] = vga_text_col & 0xff;
    c = c<'Z' ? c+1 : 'A';
  }
}


void lcd_put_alpha_pattern()
{
  char * charfb = (char*) ((MTL_FRAMEBUFFER_BASE + 800*480*4) | 0x80000000);
  char c='0';
  int x,y,j;
  for(y=0; y<40; y++) {
    for(x=0; x<100; x++) {
      j=x+y*100;
      charfb[j*2] = c;
      charfb[j*2+1] = 'z';
    }
    c = c<'9' ? c+1 : '0';
  }
}


void lcd_display_vga_text_test()
{
  char * charfb = (char*) ((MTL_FRAMEBUFFER_BASE + 800*480*4) | 0x80000000);
  lcd_blend(0,0,255,255); // no colour overlay, remove pixels, solid char fg and bg
  int x,y,j;
  for(y=0; y<40; y++) {
    for(x=0; x<100; x++) {
      j=x+y*100;
      charfb[j*2] = (char) (j & 0xff);
      charfb[j*2+1] = (j/8) & 0xff;
    }
  }  
}


void lcd_text_cursor_follower()
{
  int x0, y0, gc, count;
  int charfg_alpha=255;
  int charbg_alpha=255;
  int pixel_alpha=0;
  
  while(1) {
    do {
      x0 = IORD_32DIRECT(MTL_CONTROL_REG,3*4);
    } while(x0<0);
    y0 = IORD_32DIRECT(MTL_CONTROL_REG,4*4);
    // note that this final read dequeues
    gc = IORD_32DIRECT(MTL_CONTROL_REG,7*4);
    count = gc>>8;
    gc = gc&0xff; // extract gesture
    if(count==1) {
      lcd_cursor_pos(x0/8, y0/12);
      //alt_printf("x,y=(0x%x,0x%x)\n",x0/8,y0/12);
      charbg_alpha=x0 & 0xff;
      alt_printf("blend=%x\n",charbg_alpha);
      lcd_blend(0,255-charbg_alpha,255,charbg_alpha);
      // fade: lcd_blend(0,255-charbg_alpha,charbg_alpha,charbg_alpha);
    }
    /*
    if(count==2) {
      if((gc==0x3c) && (charbg_alpha>0))   charbg_alpha--; // west
      if((gc==0x34) && (charbg_alpha<255)) charbg_alpha++; // east
      if((gc==0x30) && (charfg_alpha>0))   charfg_alpha--; // north
      if((gc==0x38) && (charfg_alpha<255)) charfg_alpha++; // south
      if((gc==0x48) && (pixel_alpha>0))    pixel_alpha--;  // west
      if((gc==0x49) && (pixel_alpha<255))  pixel_alpha++;  // east
      //alt_printf("charfg=%x charbg=%x pixel=%x\n",
      //	 charfg_alpha, charbg_alpha, pixel_alpha);
      lcd_blend(0, pixel_alpha, charfg_alpha, charbg_alpha);
    }
    */
  }
}

void plot_pixel(int x, int y, unsigned int col)
{
  if((x>=0) && (x<800) && (y>=0) && (y<480))
    IOWR_32DIRECT(MTL_FRAMEBUFFER_BASE,(x+y*800)*4,col);
}

/**************************************************************************
 *  line_fast                                                             *
 *    draws a line using Bresenham's line-drawing algorithm, which uses   *
 *    no multiplication or division.                                      *
 **************************************************************************/

inline int sgn(int j)
{
  return j==0 ? 0 : ((j<0) ? -1 : 1);
}

inline int abs(int j)
{
  return j<0 ? -j : j;
}

void plot_line(int x1, int y1, int x2, int y2, unsigned int colour)
{
  int i,dx,dy,sdx,sdy,dxabs,dyabs,x,y,px,py;
  dx=x2-x1;      /* the horizontal distance of the line */
  dy=y2-y1;      /* the vertical distance of the line */
  dxabs=abs(dx);
  dyabs=abs(dy);
  sdx=sgn(dx);
  sdy=sgn(dy);
  x=dyabs>>1;
  y=dxabs>>1;
  px=x1;
  py=y1;

  if((x1==x2) && (y1==y2))
    plot_pixel(x1,y1,colour);
  else if (dxabs>=dyabs) { /* the line is more horizontal than vertical */
    for(i=0;i<dxabs;i++) {
      y+=dyabs;
      if (y>=dxabs) {
        y-=dxabs;
        py+=sdy;
      }
      px+=sdx;
      plot_pixel(px,py,colour);
    }
  } else { /* the line is more vertical than horizontal */
    for(i=0;i<dyabs;i++) {
      x+=dxabs;
      if (x>=dyabs) {
        x-=dyabs;
        px+=sdx;
      }
      py+=sdy;
      plot_pixel(px,py,colour);
    }
  }
}



void test_pattern()
{
  int col, j;
  // plot colour pattern
  for(col=1; col<(1<<16); col+=8) {
    for(j=0; j<800; j+=2)
      plot_line(0,16,j,479,(col<<8) | (j & 0xff));
    for(j=479; j>=0; j-=2)
      plot_line(0,16,800,j,(col<<8) | (j & 0xff));
    if((col & 0xff)==0xff)
      col += 0x700;
  }
}


void test_colour_stripes()
{
  int col, j, r, g, b;
  // lcd_clear_screen();
  // plot colour pattern
  for(j=0; j<800; j++) {
    col = (j>>4) & 0x7;
    r = (col & 0x1)==0 ? 0 : 0xff;
    g = (col & 0x2)==0 ? 0 : 0xff;
    b = (col & 0x4)==0 ? 0 : 0xff;
    col = (r<<16) | (b<<8) | g;
    //    col = 0xffffff;
    plot_line(j,16,j,479,col);
  }
}


void mtl_test()
{
  unsigned int red   = 0xff0000;
  unsigned int green = 0x00ff00;
  unsigned int blue  = 0x0000ff;
  //  unsigned int black = 0x000000;
  unsigned int white = 0xffffff;
  int x0,y0,x1,y1,gc;
  int px0=-1;
  int py0=-1;
  int px1=-1;
  int py1=-1;
  lcd_clear_screen(white);
  plot_line(0,0,799,479,blue);
  plot_line(0,479,799,0,blue);
  while(1) {
    do {
      x0 = IORD_32DIRECT(MTL_CONTROL_REG,3*4);
    } while (x0<0); // pole for new touch info
    y0 = IORD_32DIRECT(MTL_CONTROL_REG,4*4);
    x1 = IORD_32DIRECT(MTL_CONTROL_REG,5*4);
    y1 = IORD_32DIRECT(MTL_CONTROL_REG,6*4);
    // note that this final read dequeues
    gc = IORD_32DIRECT(MTL_CONTROL_REG,7*4);

    if(gc>=0) {
      int count = gc>>8;
      if((count<1) || (count>2)) {
	px0=py0=px1=py1=-1;
	lcd_putmsg_top("Count 0");
      }
      if(count>0) {
        // if the top left corner is touched, clear the screen
	if((x0>=0) && (x0<=20) && (y0>=0) && (y0<=20)) {
	  lcd_clear_screen(white);
	  plot_line(0,0,799,479,blue);
	  plot_line(0,479,799,0,blue);
	}
	if((x0>=0) && (y0>=0)) {
	  if((px0<0) || (py0<0))
	    plot_pixel(x0,y0,green);
	  else
	    plot_line(px0,py0,x0,y0,green);
	  px0=x0;
	  py0=y0;
	  lcd_putmsg_top("Count 1");
	}
      }
      if(count>1) {
	if((x1>=0) && (y1>=0)) {
	  if((px1<0) || (py1<0))
	    plot_pixel(x1,y1,red);
	  else
	    plot_line(px1,py1,x1,y1,red);
	  px1=x1;
	  py1=y1;
	}
	lcd_putmsg_top("Count 2");
      } else {
	px1=-1;
	py1=-1;
      }
    }
  }
}


int mem_test_frame_buffer()
{
  int j,p,k;

  for(p=1; p!=0; p=p<<1) {
    for(j=0; j<MTL_FRAMEBUFFER_LENGTH; j+=4)
      IOWR_32DIRECT(MTL_FRAMEBUFFER_BASE,j,p);
    for(j=0; j<MTL_FRAMEBUFFER_LENGTH; j+=4) {
      k=IORD_32DIRECT(MTL_FRAMEBUFFER_BASE,j);
      if(k!=p) {
	// printf("mem_test_frame_buffer failed at address 0x%08x - read 0x%08x but expected 0x%08x\n",j,k,p);
	alt_putstr("mem_test_frame_buffer failed");
	return -1;
      }
      IOWR_32DIRECT(MTL_FRAMEBUFFER_BASE,j,~p);
    }
  }
  alt_putstr("mem_test_frame_buffer passed\n");
  return 0;
}


/*****************************************************************************
 Flash tests
*****************************************************************************/

void write_check(int offset, int data)
{
  int base = MTL_FLASH_BASE;
  // perform memory transactions in a burst to make them easier to SignalTap
  int rd1 = IORD_32DIRECT(base,offset);
  int rd2 = IORD_32DIRECT(base,offset);
  IOWR_32DIRECT(base,offset,data);
  int rd3 = IORD_32DIRECT(base,offset);
  int rd4 = IORD_32DIRECT(base,offset);
  // report the results
  alt_printf("read from flash before write: %x\n",rd1);
  alt_printf("read from flash before write: %x\n",rd2);
  alt_printf("wrote to flash: %x\n",data);
  alt_printf("read from flash: %x\n",rd3);
  if(rd3==data) alt_putstr("PASSED\n"); else alt_putstr("FAILED\n");
  alt_printf("read from flash: %x\n",rd4);
  if(rd4==data) alt_putstr("PASSED\n"); else alt_putstr("FAILED\n");
}


void clear_status_register()
{
  IOWR_16DIRECT(MTL_FLASH_BASE,0,0x50);
}

int read_status_register()
{
  IOWR_16DIRECT(MTL_FLASH_BASE,0,0x70);
  return IORD_16DIRECT(MTL_FLASH_BASE,0);
}

void read_mode()
{ // this puts the flash back in normal read_mode
  // i.e. in its state post reset where it looks like a ROM
  IOWR_16DIRECT(MTL_FLASH_BASE,0,0xff);
}

void unlock_block_for_writes(int offset)
{
  IOWR_16DIRECT(MTL_FLASH_BASE,offset,0x60); // lock block setup
  IOWR_16DIRECT(MTL_FLASH_BASE,offset,0xd0); // unlock block
}

void lock_block_to_prevent_writes(int offset)
{
  IOWR_16DIRECT(MTL_FLASH_BASE,offset*2,0x60); // lock block setup
  IOWR_16DIRECT(MTL_FLASH_BASE,offset*2,0x01); // lock block
}

void write16_check(int offset, int data)
{
  int j;
  int base = MTL_FLASH_BASE;
  int rd1 = IORD_16DIRECT(base,offset);
  unlock_block_for_writes(offset);
  IOWR_16DIRECT(base,offset,0x40); // send write command
  IOWR_16DIRECT(base,offset,data);
  int status;
  status = read_status_register();
  for(j=0; ((status & 0x80)==0) && (j<0xfff); j++) 
    status = read_status_register();
  lock_block_to_prevent_writes(offset);
  read_mode();
  if((status & 0x80)==0)
    alt_printf("ERROR on write - flash is busy even after 0x%x checks\n",j);
  else {
    int rd3 = IORD_16DIRECT(base,offset);
    int rd4 = IORD_16DIRECT(base,offset);
    alt_printf("Attempting write mem[0x%x]=0x%x\n",offset,data);
    alt_printf("Write caused flash to be busy for 0x%x poling loop iterations\n",j);
    alt_printf("read from flash: %x\n",rd1);
    alt_printf("wrote to flash: %x\n",data);
    alt_printf("read from flash: %x\n",rd3);
    if(rd3==data) alt_putstr("PASSED\n"); else alt_putstr("FAILED\n");
    alt_printf("read from flash: %x\n",rd4);
    if(rd4==data) alt_putstr("PASSED\n"); else alt_putstr("FAILED\n");
  }
}

void erase_block(int offset)
{
  int base = MTL_FLASH_BASE;
  int j, status;
  unlock_block_for_writes(offset);
  clear_status_register();
  IOWR_16DIRECT(base,offset,0x20);
  IOWR_16DIRECT(base,offset,0xD0);
  status = read_status_register();
  for(j=0; ((status & 0x80)==0) && (j<10000000); j++) 
    status = read_status_register();
  if((status & 0x80)==0)
    alt_printf("ERROR on erase - flash is busy even after 0x%x status checks\n",j);
  if((status & (1<<5))==0)
    alt_printf("Erase passed");
  else if((status & 2)!=0)
    alt_printf("Erase failed since block locked during erase");
  else
    alt_printf("Erase failed");
  alt_printf(" after 0x%x status checks\n",j);
  alt_printf("Status = 0x%x\n",status);
  lock_block_to_prevent_writes(offset);
  clear_status_register();
  read_mode();
}

void display_device_info()
{
  int j;
  int r;
  alt_putstr("Flash device information:\n");
  IOWR_16DIRECT(MTL_FLASH_BASE,0,0x90);
  alt_printf("                  manufacturer code: 0x%x\n",IORD_16DIRECT(MTL_FLASH_BASE,0x00*2));
  alt_printf("                     device id code: 0x%x\n",IORD_16DIRECT(MTL_FLASH_BASE,0x01*2));
  alt_printf("                block lock config 0: 0x%x\n",IORD_16DIRECT(MTL_FLASH_BASE,0x02*2));
  alt_printf("                block lock config 1: 0x%x\n",IORD_16DIRECT(MTL_FLASH_BASE,0x03*2));
  alt_printf("                block lock config 2: 0x%x\n",IORD_16DIRECT(MTL_FLASH_BASE,0x04*2));
  alt_printf("             configuration register: 0x%x\n",IORD_16DIRECT(MTL_FLASH_BASE,0x05*2));
  alt_printf("                    lock register 0: 0x%x\n",IORD_16DIRECT(MTL_FLASH_BASE,0x80*2));
  alt_printf("                    lock register 1: 0x%x\n",IORD_16DIRECT(MTL_FLASH_BASE,0x89*2));
  alt_printf("  64-bit factory program protection: 0x%x 0x%x 0x%x 0x%x\n"
             ,IORD_16DIRECT(MTL_FLASH_BASE,0x84*2)
             ,IORD_16DIRECT(MTL_FLASH_BASE,0x83*2)
             ,IORD_16DIRECT(MTL_FLASH_BASE,0x82*2)
             ,IORD_16DIRECT(MTL_FLASH_BASE,0x81*2));
  alt_printf("     64-bit user program protection: 0x%x 0x%x 0x%x 0x%x\n"
             ,IORD_16DIRECT(MTL_FLASH_BASE,0x88*2)
             ,IORD_16DIRECT(MTL_FLASH_BASE,0x87*2)
             ,IORD_16DIRECT(MTL_FLASH_BASE,0x86*2)
             ,IORD_16DIRECT(MTL_FLASH_BASE,0x85*2));
  alt_printf("    128-bit user program protection: 0x%x 0x%x 0x%x 0x%x\n"
             ,IORD_16DIRECT(MTL_FLASH_BASE,0x88*2)
             ,IORD_16DIRECT(MTL_FLASH_BASE,0x87*2)
             ,IORD_16DIRECT(MTL_FLASH_BASE,0x86*2)
             ,IORD_16DIRECT(MTL_FLASH_BASE,0x85*2));
  for(j=0x84; j<=0x109; j+=8) {
    alt_printf("128-bit user program prot. reg[0x%x]:",(j-0x84)/8);
    for(r=7; r>0; r--)
      alt_printf(" 0x%x",IORD_16DIRECT(MTL_FLASH_BASE,(j+r*2)));
    alt_putstr("\n");
  }
}

void read_test(void)
{
  int base = MTL_FLASH_BASE;
  int offset = 0x0;
  for(offset=0; offset<64*1024*1024; offset+=4) {
    alt_printf("%x:%x\n",offset,IORD_32DIRECT(base,offset));
  }
}


/****************************************************************************/


int main()
{ 
  int a, j;
  //  alt_putstr("Starting MTL tests...\n");
  // mem_test_frame_buffer();
  lcd_clear_screen(0);
  lcd_putmsg_top("Starting test");

  lcd_display_vga_text_test();
  //lcd_put_alphabet(0x70); 
  test_colour_stripes();
  lcd_text_cursor_follower();
  while(1);

  // do some read tests
  //  while(1)
  for(j=0; j<26; j++)
    a=IORD_32DIRECT(MTL_FRAMEBUFFER_BASE,1<<j);

  // some flash tests
  display_device_info();

  // write flash test - don't do too often since the flash has a limited number of erase cycles
  /*
  clear_status_register();
  alt_printf("status register = 0x%x\n",read_status_register);
  alt_printf("status register = 0x%x\n",read_status_register);
  write16_check(0x3ff8000,0xf0f0);
  erase_block(0x3ff8000);
  write16_check(0x3ff8000,0xf0f0);
  */

  // some other tests:
  // lcd_put_alphabet(); 
  // lcd_put_alpha_pattern(); 
  // test_colour_stripes();
  // test_pattern();

  lcd_putmsg_top("Running mtl_test");
  //alt_putstr("Running mtl_test\n");
  mtl_test();

  //alt_putstr("THE END\n");
  lcd_putmsg_top("THE END");

  /* Event loop never exits. */
  while (1);

  return 0;
}
