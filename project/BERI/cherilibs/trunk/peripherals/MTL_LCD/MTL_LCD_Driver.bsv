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

 MTL LCD Driver
 ==============
 
 This peripheral takes an AvalonStream of pixel values and maps them to
 the MTL (multi-touch) LCD colour screen which has an 800x480 resolution.
 
 Pixels are 24-bits (8-bit red, green, blue)
 
 ASSUMPTION:
 - the main clock is running at 33MHz
 - the main clock is fed to the mtl_dclk outside of this module
 
 *****************************************************************************/

package MTL_LCD_Driver;

import FIFO::*;
import FIFOF::*;
import GetPut::*;
import AvalonStreaming::*;

typedef UInt#(8) ColourChannelT;

(* always_ready, always_enabled *)
interface MTL_LCDphysical;
  // LCD physical interface
  method ColourChannelT mtl_r; // red
  method ColourChannelT mtl_g; // green
  method ColourChannelT mtl_b; // blue
  method Bool mtl_hsd;         // hsync
  method Bool mtl_vsd;         // vsync
endinterface

(* always_ready, always_enabled *)
interface MTL_LCDphysicalNested;
  interface MTL_LCDphysical phy;
endinterface
   

typedef UInt#(8) ColourT;

typedef struct {
   ColourT r;    // red
   ColourT g;    // green
   ColourT b;    // blue
   Bool sof;     // start of frame
   } Pixel24bT deriving (Bits,Eq);

typedef struct {
   ColourT r;    // red
   ColourT g;    // green
   ColourT b;    // blue
   } RGBT deriving (Bits,Eq);

interface MTL_Timing24bitIfc;
  interface Put#(Pixel24bT) pixel_stream;
  interface MTL_LCDphysical phy;
endinterface
      

module mkMTL_Timing24bit(MTL_Timing24bitIfc);
   
  let              xres = 800;  // X resolution
  let              yres = 480;  // Y resolution
  let hsync_pulse_width = 30;   // timing parameters from MTL LCD manual
  let  hsync_back_porch = 16;   // terasic seem to use 14, but manual says 16
  let        hsync_time = hsync_pulse_width + hsync_back_porch;
  let hsync_front_porch = 210;  // terasic seem to use 212, but manual says 210
  let vsync_pulse_width = 13;
  let  vsync_back_porch = 10;   // terasic seem to use 8, but manual says 10
  let        vsync_time = vsync_pulse_width + vsync_back_porch;
  let vsync_front_porch = 22;   // terasic seem to use 24, but manual says 22
  let          no_pixel = Pixel24bT{r:0,g:0,b:0,sof:False};
  let         red_pixel = Pixel24bT{r:~0,g:0,b:0,sof:True};

  FIFOF#(Pixel24bT) pixel_buf <- mkGFIFOF(False,True); // ungarded deq
  Reg#(Pixel24bT)   pixel_out <- mkRegU;
  Reg#(Bool)              vsd <- mkRegU;
  Reg#(Bool)              hsd <- mkRegU;
  Reg#(Int#(12))            x <- mkReg(-hsync_time); 
  Reg#(Int#(12))            y <- mkReg(-vsync_time); 
  
  (* no_implicit_conditions, fire_when_enabled *)
  rule every_clock_cycle (True);
    if(x < (xres+hsync_front_porch-1))
      x <= x+1;
    else
      begin
        x <= -hsync_time;
        y <= y < (yres+vsync_front_porch-1) ? y+1 : -vsync_time;
      end
    
    let hsync_pulse = (x < (-hsync_back_porch));
    let vsync_pulse = (y < (-vsync_back_porch));
    hsd <= !hsync_pulse;
    vsd <= !vsync_pulse;
    
    // determine pixel colour
    let pixel_col = no_pixel;
    if((y>=0) && (y<yres) && (x>=0) && (x<xres))
      begin // in drawing region
	// check that the pixel stream is synchronised with the LCD timing,
	// otherwise output red
        if(pixel_buf.notEmpty && (pixel_buf.first.sof == ((x==0) && (y==0))))
          begin
            pixel_col = pixel_buf.first;
            pixel_col.sof = True;    // use SOF for DEN on output
            pixel_buf.deq;
          end
        else // data missing so draw red
          pixel_col = red_pixel;
      end
    pixel_out <= pixel_col;
  endrule      
  
  interface pixel_stream = toPut(pixel_buf);
    interface MTL_LCDphysical phy;
      method ColourChannelT mtl_r;  return pixel_out.r;  endmethod
      method ColourChannelT mtl_g;  return pixel_out.g;  endmethod
      method ColourChannelT mtl_b;  return pixel_out.b;  endmethod
      method Bool mtl_hsd;          return hsd;          endmethod
      method Bool mtl_vsd;          return vsd;          endmethod
  endinterface   
endmodule


(* always_ready, always_enabled *)
interface AvalonStream2MTL_LCD24bitIfc;
  interface AvalonPacketStreamSinkPhysicalIfc#(SizeOf#(RGBT)) asi;
  interface MTL_LCDphysical coe_tpadlcd;
endinterface

(* synthesize,
   reset_prefix = "csi_clockreset_reset_n",
   clock_prefix = "csi_clockreset_clk" *)
module mkAvalonStream2MTL_LCD24bit(AvalonStream2MTL_LCD24bitIfc);
   
  MTL_Timing24bitIfc lcdtiming              <- mkMTL_Timing24bit;
  AvalonPacketStreamSinkIfc#(RGBT) streamIn <- mkAvalonPacketStreamSink2Get;
   
  rule connect_stream_to_lcd_interface;
    let s <- streamIn.rx.get;
    lcdtiming.pixel_stream.put(Pixel24bT{
       r: s.d.r,
       g: s.d.g,
       b: s.d.b,
       sof: s.sop
       });
    // N.B. eop (end-of-packet) currently ignored
  endrule
   
  interface coe_tpadlcd = lcdtiming.phy;
  interface asi = streamIn.physical;
  
endmodule


endpackage
