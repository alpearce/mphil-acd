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

 MTL-LCD and HDMI Timing Driver
 ==============================
 
 This set of peripherals takes an AvalonStream of pixel values and maps them
 to the Terasic MTL (multi-touch) LCD colour screen which has an 800x480
 resolution and can also send to the HDMI output at 720x480 resolution with the
 right-hand-side cropped.
 
 mkAvalonStream2MTL_LCD24bit - avalon stream of pixels to LCD
 mkAvalonStream2HDMI36bit    - avalon stream of pixels to HDMI
 mkAvalonStream2LCDandHDMI   - avalon stream of pixels to LCD and HDMI
 mkPixelDuplicator           - duplicates a pixel stream (alt. to above)
 
 ASSUMPTIONS:
 - the main clock is running at 27MHz
 - the main clock is fed to the mtl_dclk and HDMI_TX_PCLK outside of this module
 - Pixels streams are 24-bits (8-bit red, green, blue) with red MSB and blue LSB
 
 NOTES ON PIXEL TIMING:
 Timing parameters for the LCD have been adjusted out of spec. to ensure
 that horizontal line length (in pixel clocks) is idential for both
 LCD and HDMI outputs even though the hsync, front- and back-pourch
 timings are different and there are 800 pixels on the LCD but just 720
 on HDMI.  The number of vertical lines is also idential.  This allows
 one pixel stream to be mapped to both displays with no further buffering
 needed.
 
 MISC NOTES (HDMI video modes, pins, etc.) - see end of this file
 *****************************************************************************/



package MTL_LCD_HDMI_Driver;


import FIFO::*;
import FIFOF::*;
import GetPut::*;
import AvalonStreaming::*;

// 8-bit colour channel type (3 of these for 24-bit input colour)
typedef UInt#(8) ColourChanT;
// 12-bit HDMI channel colour
typedef UInt#(12) HDMIColourChanT;

// AvalonStream type for 24-bit pixels with start-of-frame marked
typedef struct {
   ColourChanT r;    // red
   ColourChanT g;    // green
   ColourChanT b;    // blue
   Bool        sof;  // start of frame
   } Pixel24bT deriving (Bits,Eq);

// 24-bit pixel type
typedef struct {
   ColourChanT r;    // red
   ColourChanT g;    // green
   ColourChanT b;    // blue
   } RGBT deriving (Bits,Eq);



/*****************************************************************************
 MTL_LCD timing
 *****************************************************************************/

(* always_ready, always_enabled *)
interface MTL_LCDphysical;  // LCD physical interface
  method ColourChanT mtl_r; // red
  method ColourChanT mtl_g; // green
  method ColourChanT mtl_b; // blue
  method Bool mtl_hsd;      // hsync
  method Bool mtl_vsd;      // vsync
endinterface


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
  let hsync_front_porch = 12;  // terasic seem to use 212, but manual says 210, but use 12 to tie in with HDMI timing
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
  rule every_clock_cycle (pixel_buf.notEmpty);
    // N.B. unlike previous design, we wait for the pixel stream to show up before synchronising
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
      method ColourChanT mtl_r;  return pixel_out.r;  endmethod
      method ColourChanT mtl_g;  return pixel_out.g;  endmethod
      method ColourChanT mtl_b;  return pixel_out.b;  endmethod
      method Bool mtl_hsd;          return hsd;          endmethod
      method Bool mtl_vsd;          return vsd;          endmethod
  endinterface   
endmodule



// Provide Avalon Streaming interface for the above
(* always_ready, always_enabled *)
interface AvalonStream2MTL_LCD24bitIfc;
  interface AvalonPacketStreamSinkPhysicalIfc#(SizeOf#(RGBT)) asi;
  interface MTL_LCDphysical coe_tpadlcd;
endinterface

(* synthesize,
   reset_prefix = "csi_clockreset_reset_n",
   clock_prefix = "csi_clockreset_clk" *)
module mkAvalonStream2MTL_LCD24bit(AvalonStream2MTL_LCD24bitIfc);
   
  MTL_Timing24bitIfc              lcdtiming <- mkMTL_Timing24bit;
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






/*****************************************************************************
 * HDMI timing version
 *****************************************************************************/

(* always_ready, always_enabled *)
interface HDMIphysical;
  // LCD physical interface
  method HDMIColourChanT hdmi_r; // red
  method HDMIColourChanT hdmi_g; // green
  method HDMIColourChanT hdmi_b; // blue
  method Bool hdmi_hsd;          // hsync
  method Bool hdmi_vsd;          // vsync
  method Bool hdmi_de;           // data enable
endinterface


interface HDMI_Timing36bitIfc;
  interface Put#(Pixel24bT) pixel_stream;
  interface HDMIphysical phy;
endinterface
      

// convert 8-bit channel colour into 12-bit HDMI colour
function HDMIColourChanT hdmiCol(ColourChanT col8);
  HDMIColourChanT c12 = extend(col8);
  return c12<<4;  // correct if 24-bit colour mode selected on HDMI chip
endfunction



module mkHDMI_Timing36bit(HDMI_Timing36bitIfc);
   
  let              xpix = 800;        // X pixels resolution of input stream
  let              xres = 720;        // X resolution of display
  let          extrapix = xpix-xres;  // number of pixels to bin
  let              yres = 480;        // Y resolution
  let hsync_pulse_width = 62;
  let  hsync_back_porch = 60;
  let        hsync_time = hsync_pulse_width + hsync_back_porch;
  let hsync_front_porch = 16;
  let vsync_pulse_width = 6;
  let  vsync_back_porch = 30;
  let        vsync_time = vsync_pulse_width + vsync_back_porch;
  let vsync_front_porch = 9;
  let          no_pixel = Pixel24bT{r:0,g:0,b:0,sof:False};
  let         red_pixel = Pixel24bT{r:~0,g:0,b:0,sof:True};

  FIFOF#(Pixel24bT) pixel_buf <- mkGFIFOF(False,True); // ungarded deq
  Reg#(Pixel24bT)   pixel_out <- mkRegU;
  Reg#(Bool)              vsd <- mkRegU;
  Reg#(Bool)              hsd <- mkRegU;
  Reg#(Bool)               de <- mkRegU;               // data enable for HDMI
  Reg#(Int#(12))            x <- mkReg(-hsync_time); 
  Reg#(Int#(12))            y <- mkReg(-vsync_time); 
  Reg#(Int#(12))       binpix <- mkReg(0); 
  
  (* no_implicit_conditions, fire_when_enabled *)
  rule every_clock_cycle (pixel_buf.notEmpty);
    // Note the above explicit condition that we have pixels to render
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
    
    // determine drawing region
    let drawing = (y>=0) && (y<yres) && (x>=0) && (x<xres);
    de <= drawing;
    
    // determine pixel colour
    let pixel_col = no_pixel;
    if(drawing)
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
    else
      if(!pixel_buf.first.sof)
	begin
	  if(x==xres)  // bin remaining pixels on each line
	    begin
	      binpix <= extrapix-1;
	      pixel_buf.deq;
	      // N.B. it's critical that we keep up with the LCD timing in
	      // removing pixels from the buffer at the same time
	    end
	  else
	    if(binpix>0)
	      begin
		binpix <= binpix-1;
		pixel_buf.deq;
	      end
	end
    pixel_out <= pixel_col;
  endrule      
  
  interface pixel_stream = toPut(pixel_buf);
    interface HDMIphysical phy;
      method HDMIColourChanT hdmi_r;  return hdmiCol(pixel_out.r);  endmethod
      method HDMIColourChanT hdmi_g;  return hdmiCol(pixel_out.g);  endmethod
      method HDMIColourChanT hdmi_b;  return hdmiCol(pixel_out.b);  endmethod
      method Bool hdmi_hsd;           return hsd;                   endmethod
      method Bool hdmi_vsd;           return vsd;                   endmethod
      method Bool hdmi_de;            return de;                    endmethod
  endinterface   
endmodule


// AvalonStream wrapper around the above
(* always_ready, always_enabled *)
interface AvalonStream2HDMI36bitIfc;
  interface AvalonPacketStreamSinkPhysicalIfc#(SizeOf#(RGBT)) asi;
  interface HDMIphysical coe;
endinterface

(* synthesize,
   reset_prefix = "csi_clockreset_reset_n",
   clock_prefix = "csi_clockreset_clk" *)
module mkAvalonStream2HDMI36bit(AvalonStream2HDMI36bitIfc);
   
  HDMI_Timing36bitIfc             hdmitiming <- mkHDMI_Timing36bit;
  AvalonPacketStreamSinkIfc#(RGBT)  streamIn <- mkAvalonPacketStreamSink2Get;
   
  rule connect_stream_to_lcd_interface;
    let s <- streamIn.rx.get;
    hdmitiming.pixel_stream.put(Pixel24bT{
       r: s.d.r,
       g: s.d.g,
       b: s.d.b,
       sof: s.sop
       });
    // N.B. eop (end-of-packet) currently ignored
  endrule
   
  interface coe = hdmitiming.phy;
  interface asi = streamIn.physical;
  
endmodule



/*****************************************************************************
 AvalonStream2LCDandHDMI
 =======================
 
 This is the top-level module if you want one stream of input pixels mapped
 to both LCD and HDMI outputs.
 *****************************************************************************/

(* always_ready, always_enabled *)
interface AvalonStream2LCDandHDMIIfc;
  interface AvalonPacketStreamSinkPhysicalIfc#(SizeOf#(RGBT)) asi;
  interface HDMIphysical coe;
  interface MTL_LCDphysical coe_tpadlcd;
endinterface

(* synthesize,
   reset_prefix = "csi_clockreset_reset_n",
   clock_prefix = "csi_clockreset_clk" *)
module mkAvalonStream2LCDandHDMI(AvalonStream2LCDandHDMIIfc);
   
  MTL_Timing24bitIfc               lcdtiming <- mkMTL_Timing24bit;
  HDMI_Timing36bitIfc             hdmitiming <- mkHDMI_Timing36bit;
  AvalonPacketStreamSinkIfc#(RGBT)  streamIn <- mkAvalonPacketStreamSink2Get;
   
  rule connect_stream_to_lcd_and_hdmi_interfaces;
    let s <- streamIn.rx.get;
    lcdtiming.pixel_stream.put(Pixel24bT{
       r: s.d.r,
       g: s.d.g,
       b: s.d.b,
       sof: s.sop
       });
    hdmitiming.pixel_stream.put(Pixel24bT{
       r: s.d.r,
       g: s.d.g,
       b: s.d.b,
       sof: s.sop
       });
    // N.B. eop (end-of-packet) currently ignored
  endrule
   
  interface coe = hdmitiming.phy;
  interface asi = streamIn.physical;
  interface coe_tpadlcd = lcdtiming.phy;
  
endmodule



/*****************************************************************************
 Pixel stream duplicator
 =======================
 Used to push one pixel source to two sinks (e.g. LCD and HDMI).
 
 IMPLEMENTATION NOTE:
 This might be useful if we have trouble with timing on a larger design since
 it will allow the LCD and HDMI timing components to be in seperate modules
 and pulled into Qsys seperately, facilitating floor planning.  Moreover,
 additional buffering could be placed along the avalon streams for futher
 timing flexibility.  That said, the modules only run at 27MHz so it shouldn't
 be a big issue.
 *****************************************************************************/

interface PixelDuplicatorIfc;
  interface AvalonPacketStreamSinkPhysicalIfc#(SizeOf#(RGBT)) asi;
  interface AvalonPacketStreamSourcePhysicalIfc#(SizeOf#(RGBT)) aso_a;
  interface AvalonPacketStreamSourcePhysicalIfc#(SizeOf#(RGBT)) aso_b;
endinterface

(* synthesize,
   reset_prefix = "csi_clockreset_reset_n",
   clock_prefix = "csi_clockreset_clk" *)
module mkPixelDuplicator(PixelDuplicatorIfc);
  
  AvalonPacketStreamSinkIfc#(RGBT) streamIn <- mkAvalonPacketStreamSink2Get;
  AvalonPacketStreamSourceIfc#(RGBT) streamOutA <- mkPut2AvalonPacketStreamSource;
  AvalonPacketStreamSourceIfc#(RGBT) streamOutB <- mkPut2AvalonPacketStreamSource;
  
  rule duplicate_stream;
    let d <- streamIn.rx.get;
    streamOutA.tx.put(d);
    streamOutB.tx.put(d);
  endrule
  
  interface asi   = streamIn.physical;
  interface aso_a = streamOutA.physical;
  interface aso_b = streamOutB.physical;
  
endmodule
			 

endpackage


/*****************************************************************************
 Notes on HDMI video formats
 ===========================
 
 CEA Video Information Code (VIC) Formats:

  VIC = 1, 640 x 480p 59.94/60 Hz 4:3
  VIC = 2, 720 x 480p 59.94/60 Hz 4:3
  VIC = 3, 720 x 480p 59.94/60 Hz 16:9
  VIC = 4, 1280 x 720p 59.94/60 Hz 16:9
  VIC = 5, 1920 x 1080i 59.94/60 Hz 16:9
  VIC = 6, 720(1440) x 480i 59.94/60 Hz 4:3
  VIC = 7, 720(1440) x 480i 59.94/60 Hz 16:9
  VIC = 14, 1440 x 480p 59.94/60 Hz 4:3
  VIC = 15, 1440 x 480p 59.94/60 Hz 16:9
  VIC = 16, Native 1920 x 1080p 59.94/60 Hz 16:9
  VIC = 17, 720 x 576p 50 Hz 4:3
  VIC = 18, 720 x 576p 50 Hz 16:9
  VIC = 19, 1280 x 720p 50 Hz 16:9
  VIC = 20, 1920 x 1080i 50 Hz 16:9
  VIC = 21, 720(1440) x 576i 50 Hz 4:3
  VIC = 22, 720(1440) x 576i 50 Hz 16:9
  VIC = 29, 1440 x 576p 50 Hz 4:3
  VIC = 30, 1440 x 576p 50 Hz 16:9
  VIC = 31, 1920 x 1080p 50 Hz 16:9
  VIC = 32, 1920 x 1080p 23.97/24 Hz 16:9
  VIC = 33, 1920 x 1080p 25 Hz 16:9
  VIC = 34, 1920 x 1080p 29.97/30 Hz 16:9
  VIC = 39, 1920 x 1080i 50 Hz 16:9
  VIC = 41, 1280 x 720p 100 Hz 16:9
  VIC = 42, 720 x 576p 100 Hz 4:3
  VIC = 43, 720 x 576p 100 Hz 16:9
  VIC = 44, 720(1440) x 576i 100 Hz 4:3
  VIC = 45, 720(1440) x 576i 100 Hz 16:9
  VIC = 47, 1280 x 720p 119.88/120 Hz 16:9
  VIC = 48, 720 x 480p 119.88/120 Hz 4:3
  VIC = 49, 720 x 480p 119.88/120 Hz 16:9
 *****************************************************************************/

/*****************************************************************************
 Notes on Pin definitions for DE4 board with HDMI on left hand HSMC connector
 and MTL-LCD on right most IDE connector

// Output colours:
set_location_assignment PIN_AJ31 -to HDMI_TX_BD[11]
set_location_assignment PIN_AR31 -to HDMI_TX_BD[10]
set_location_assignment PIN_AT30 -to HDMI_TX_BD[9]
set_location_assignment PIN_AT33 -to HDMI_TX_BD[8]
set_location_assignment PIN_AU33 -to HDMI_TX_BD[7]
set_location_assignment PIN_AU34 -to HDMI_TX_BD[6]
set_location_assignment PIN_AV34 -to HDMI_TX_BD[5]
set_location_assignment PIN_AT32 -to HDMI_TX_BD[4]
set_location_assignment PIN_AU32 -to HDMI_TX_BD[3]
set_location_assignment PIN_AT31 -to HDMI_TX_BD[2]
set_location_assignment PIN_AU31 -to HDMI_TX_BD[1]
set_location_assignment PIN_AP35 -to HDMI_TX_BD[0]
set_location_assignment PIN_AC28 -to HDMI_TX_GD[11]
set_location_assignment PIN_AC29 -to HDMI_TX_GD[10]
set_location_assignment PIN_AJ29 -to HDMI_TX_GD[9]
set_location_assignment PIN_AK29 -to HDMI_TX_GD[8]
set_location_assignment PIN_AD30 -to HDMI_TX_GD[7]
set_location_assignment PIN_AD31 -to HDMI_TX_GD[6]
set_location_assignment PIN_AK32 -to HDMI_TX_GD[5]
set_location_assignment PIN_AL32 -to HDMI_TX_GD[4]
set_location_assignment PIN_AG27 -to HDMI_TX_GD[3]
set_location_assignment PIN_AH27 -to HDMI_TX_GD[2]
set_location_assignment PIN_AK31 -to HDMI_TX_GD[1]
set_location_assignment PIN_AL31 -to HDMI_TX_GD[0]
set_location_assignment PIN_AB30 -to HDMI_TX_RD[11]
set_location_assignment PIN_AB31 -to HDMI_TX_RD[10]
set_location_assignment PIN_AD27 -to HDMI_TX_RD[9]
set_location_assignment PIN_AE27 -to HDMI_TX_RD[8]
set_location_assignment PIN_AD28 -to HDMI_TX_RD[7]
set_location_assignment PIN_AD29 -to HDMI_TX_RD[6]
set_location_assignment PIN_AE28 -to HDMI_TX_RD[5]
set_location_assignment PIN_AE29 -to HDMI_TX_RD[4]
set_location_assignment PIN_AE26 -to HDMI_TX_RD[3]
set_location_assignment PIN_AF26 -to HDMI_TX_RD[2]
set_location_assignment PIN_AG31 -to HDMI_TX_RD[1]
set_location_assignment PIN_AG32 -to HDMI_TX_RD[0]
// video signalling outputs:
set_location_assignment PIN_AR35 -to HDMI_TX_DE
set_location_assignment PIN_AN32 -to HDMI_TX_HS
set_location_assignment PIN_AP33 -to HDMI_TX_VS

// pixel clock output (27MHz)
set_location_assignment PIN_AN33 -to HDMI_TX_PCLK
// system reset output:
set_location_assignment PIN_AK33 -to HDMI_TX_RST_N
// interrupt input
set_location_assignment PIN_AH34 -to HDMI_TX_INT_N

// I2C clock output
set_location_assignment PIN_AC31 -to HDMI_TX_PCSCL
// I2C bidirectional data (used to configure HDMI chip)
set_location_assignment PIN_AC32 -to HDMI_TX_PCSDA

// I2S interface outputs:
set_location_assignment PIN_AK30 -to HDMI_TX_I2S[3]
set_location_assignment PIN_AL30 -to HDMI_TX_I2S[2]
set_location_assignment PIN_AR32 -to HDMI_TX_I2S[1]
set_location_assignment PIN_AP32 -to HDMI_TX_I2S[0]
set_location_assignment PIN_AT34 -to HDMI_TX_WS
set_location_assignment PIN_AP34 -to HDMI_TX_SCK

// unused inouts (tie to 1'bz):
set_location_assignment PIN_AJ32 -to HDMI_TX_CEC

// unused outputs (e.g. sound):
set_location_assignment PIN_AG35 -to HDMI_TX_DCLK
set_location_assignment PIN_AH35 -to HDMI_TX_DSD_L[3]
set_location_assignment PIN_AJ35 -to HDMI_TX_DSD_L[2]
set_location_assignment PIN_AM34 -to HDMI_TX_DSD_L[1]
set_location_assignment PIN_AN31 -to HDMI_TX_DSD_L[0]
set_location_assignment PIN_AJ34 -to HDMI_TX_DSD_R[3]
set_location_assignment PIN_AK34 -to HDMI_TX_DSD_R[2]
set_location_assignment PIN_AM35 -to HDMI_TX_DSD_R[1]
set_location_assignment PIN_AR34 -to HDMI_TX_DSD_R[0]
set_location_assignment PIN_AG34 -to HDMI_TX_MCLK
set_location_assignment PIN_AM29 -to HDMI_TX_SPDIF
 
*****************************************************************************/

