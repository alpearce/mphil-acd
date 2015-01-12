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
 */

/******************************************************************************
  Touch LCD (MTL) test on DE4-230 board
  =====================================
  Simon Moore, March 2012
  
 ******************************************************************************/

module toplevel(

	//////////// CLOCK //////////
	GCLKIN,
	GCLKOUT_FPGA,
	OSC_50_BANK2,
	OSC_50_BANK3,
	OSC_50_BANK4,
	OSC_50_BANK5,
	OSC_50_BANK6,
	OSC_50_BANK7,
	PLL_CLKIN_p,

	//////////// External PLL //////////
	MAX_I2C_SCLK,
	MAX_I2C_SDAT,

	//////////// LED x 8 //////////
	LED,

	//////////// BUTTON x 4, EXT_IO and CPU_RESET_n //////////
	BUTTON,
	CPU_RESET_n,
	EXT_IO,

	//////////// DIP SWITCH x 8 //////////
	SW,

	//////////// SLIDE SWITCH x 4 //////////
	SLIDE_SW,

	//////////// SEG7 //////////
	SEG0_D,
	SEG0_DP,
	SEG1_D,
	SEG1_DP,

	//////////// Temperature //////////
	TEMP_INT_n,
	TEMP_SMCLK,
	TEMP_SMDAT,

	//////////// Current //////////
	CSENSE_ADC_FO,
	CSENSE_CS_n,
	CSENSE_SCK,
	CSENSE_SDI,
	CSENSE_SDO,

	//////////// Fan //////////
	FAN_CTRL,

	/*
	//////////// SDCARD //////////
	SD_CLK,
	SD_CMD,
	SD_DAT,
	SD_WP_n,

	//////////// Ethernet x 4 //////////
	ETH_INT_n,
	ETH_MDC,
	ETH_MDIO,
	ETH_RST_n,
	ETH_RX_p,
	ETH_TX_p,
*/

                /*
	//////////// PCIe x 8 //////////
	PCIE_PREST_n,
//	PCIE_REFCLK_p,
	PCIE_RX_p,
	PCIE_SMBCLK,
	PCIE_SMBDAT,
	PCIE_TX_p,
	PCIE_WAKE_n,
*/
	//////////// Flash and SRAM Address/Data Share Bus //////////
	FSM_A,
	FSM_D,

	//////////// Flash Control //////////
	FLASH_ADV_n,
	FLASH_CE_n,
	FLASH_CLK,
	FLASH_OE_n,
	FLASH_RESET_n,
	FLASH_RYBY_n,
	FLASH_WE_n,

	//////////// SSRAM Control //////////
	SSRAM_ADV,
	SSRAM_BWA_n,
	SSRAM_BWB_n,
	SSRAM_CE_n,
	SSRAM_CKE_n,
	SSRAM_CLK,
	SSRAM_OE_n,
	SSRAM_WE_n,
                /*
	//////////// SATA //////////
	SATA_DEVICE_RX_p,
	SATA_DEVICE_TX_p,
	SATA_HOST_RX_p,
	SATA_HOST_TX_p,
	SATA_REFCLK_p,
                 */
/*
	//////////// DDR2 SODIMM, DDR2 SODIMM_0 //////////
	M1_DDR2_addr,
	M1_DDR2_ba,
	M1_DDR2_cas_n,
	M1_DDR2_cke,
	M1_DDR2_clk,
	M1_DDR2_clk_n,
	M1_DDR2_cs_n,
	M1_DDR2_dm,
	M1_DDR2_dq,
	M1_DDR2_dqs,
	M1_DDR2_dqsn,
	M1_DDR2_odt,
	M1_DDR2_ras_n,
	M1_DDR2_SA,
	M1_DDR2_SCL,
	M1_DDR2_SDA,
	M1_DDR2_we_n,

	//////////// DDR2 SODIMM, DDR2 SODIMM_1 //////////
	M2_DDR2_addr,
	M2_DDR2_ba,
	M2_DDR2_cas_n,
	M2_DDR2_cke,
	M2_DDR2_clk,
	M2_DDR2_clk_n,
	M2_DDR2_cs_n,
	M2_DDR2_dm,
	M2_DDR2_dq,
	M2_DDR2_dqs,
	M2_DDR2_dqsn,
	M2_DDR2_odt,
	M2_DDR2_ras_n,
	M2_DDR2_SA,
	M2_DDR2_SCL,
	M2_DDR2_SDA,
	M2_DDR2_we_n 
	*/
	//////////// GPIO_0, GPIO_0 connect to LTM - 4.3" LCD and Touch //////////
	lcdtouchLTM_ADC_BUSY,
	lcdtouchLTM_ADC_DCLK,
	lcdtouchLTM_ADC_DIN,
	lcdtouchLTM_ADC_DOUT,
	lcdtouchLTM_ADC_PENIRQ_n,
	lcdtouchLTM_B,
	lcdtouchLTM_DEN,
	lcdtouchLTM_G,
	lcdtouchLTM_GREST,
	lcdtouchLTM_HD,
	lcdtouchLTM_NCLK,
	lcdtouchLTM_R,
	lcdtouchLTM_SCEN,
	lcdtouchLTM_SDA,
	lcdtouchLTM_VD,
	
	//////////// GPIO_1 connect to MTL capacitive touch screen
	mtl_dclk,
	mtl_r,
	mtl_g,
	mtl_b,
	mtl_hsd,
	mtl_vsd,
	mtl_touch_i2cscl,
	mtl_touch_i2csda,
	mtl_touch_int
);

//=======================================================
//  PORT declarations
//=======================================================

//////////// CLOCK //////////
input		          		GCLKIN;
output		          		GCLKOUT_FPGA;
input		          		OSC_50_BANK2;
input		          		OSC_50_BANK3;
input		          		OSC_50_BANK4;
input		          		OSC_50_BANK5;
input		          		OSC_50_BANK6;
input		          		OSC_50_BANK7;
input		          		PLL_CLKIN_p;

//////////// External PLL //////////
output		          		MAX_I2C_SCLK;
inout		          		MAX_I2C_SDAT;

//////////// LED x 8 //////////
output		     [7:0]		LED;

//////////// BUTTON x 4, EXT_IO and CPU_RESET_n //////////
input		     [3:0]		BUTTON;
input		          		CPU_RESET_n;
inout		          		EXT_IO;

//////////// DIP SWITCH x 8 //////////
input		     [7:0]		SW;

//////////// SLIDE SWITCH x 4 //////////
input		     [3:0]		SLIDE_SW;

//////////// SEG7 //////////
output		     [6:0]		SEG0_D;
output		          		SEG0_DP;
output		     [6:0]		SEG1_D;
output		          		SEG1_DP;

//////////// Temperature //////////
input		          		TEMP_INT_n;
output		          		TEMP_SMCLK;
inout		          		TEMP_SMDAT;

//////////// Current //////////
output		          		CSENSE_ADC_FO;
output		     [1:0]		CSENSE_CS_n;
output		          		CSENSE_SCK;
output		          		CSENSE_SDI;
input		          		CSENSE_SDO;

//////////// Fan //////////
output		          		FAN_CTRL;

/*
//////////// SDCARD //////////
output		          		SD_CLK;
inout		          		SD_CMD;
inout		     [3:0]		SD_DAT;
input		          		SD_WP_n;

//////////// Ethernet x 4 //////////
input		     [3:0]		ETH_INT_n;
output		     [3:0]		ETH_MDC;
inout		     [3:0]		ETH_MDIO;
output		          		ETH_RST_n;
input		     [3:0]		ETH_RX_p;
output		     [3:0]		ETH_TX_p;
*/

/*
//////////// PCIe x 8 //////////
input		          		PCIE_PREST_n;
// input		          		PCIE_REFCLK_p;
input		     [7:0]		PCIE_RX_p;
input		          		PCIE_SMBCLK;
inout		          		PCIE_SMBDAT;
output		     [7:0]		PCIE_TX_p;
output		          		PCIE_WAKE_n;
*/

//////////// Flash and SRAM Address/Data Share Bus //////////
output		    [25:1]		FSM_A;
inout		    [15:0]		FSM_D;

//////////// Flash Control //////////
output		          		FLASH_ADV_n;
output		          		FLASH_CE_n;
output		          		FLASH_CLK;
output		          		FLASH_OE_n;
output		          		FLASH_RESET_n;
input		          		FLASH_RYBY_n;
output		          		FLASH_WE_n;
  
//////////// SSRAM Control //////////
output		          		SSRAM_ADV;
output		          		SSRAM_BWA_n;
output		          		SSRAM_BWB_n;
output		          		SSRAM_CE_n;
output		          		SSRAM_CKE_n;
output		          		SSRAM_CLK;
output		          		SSRAM_OE_n;
output		          		SSRAM_WE_n;

//////////// SATA //////////
/*
input		     [1:0]		SATA_DEVICE_RX_p;
output		     [1:0]		SATA_DEVICE_TX_p;
input		     [1:0]		SATA_HOST_RX_p;
output		     [1:0]		SATA_HOST_TX_p;
input		          		SATA_REFCLK_p;
*/

/*
//////////// DDR2 SODIMM, DDR2 SODIMM_0 //////////
output		    [15:0]		M1_DDR2_addr;
output		     [2:0]		M1_DDR2_ba;
output		          		M1_DDR2_cas_n;
output		     [1:0]		M1_DDR2_cke;
inout		     [1:0]		M1_DDR2_clk;
inout		     [1:0]		M1_DDR2_clk_n;
output		     [1:0]		M1_DDR2_cs_n;
output		     [7:0]		M1_DDR2_dm;
inout		    [63:0]		M1_DDR2_dq;
inout		     [7:0]		M1_DDR2_dqs;
inout		     [7:0]		M1_DDR2_dqsn;
output		     [1:0]		M1_DDR2_odt;
output		          		M1_DDR2_ras_n;
output		     [1:0]		M1_DDR2_SA;
output		          		M1_DDR2_SCL;
inout		          		M1_DDR2_SDA;
output		          		M1_DDR2_we_n;

//////////// DDR2 SODIMM, DDR2 SODIMM_1 //////////
output		    [15:0]		M2_DDR2_addr;
output		     [2:0]		M2_DDR2_ba;
output		          		M2_DDR2_cas_n;
output		     [1:0]		M2_DDR2_cke;
inout		     [1:0]		M2_DDR2_clk;
inout		     [1:0]		M2_DDR2_clk_n;
output		     [1:0]		M2_DDR2_cs_n;
output		     [7:0]		M2_DDR2_dm;
inout		    [63:0]		M2_DDR2_dq;
inout		     [7:0]		M2_DDR2_dqs;
inout		     [7:0]		M2_DDR2_dqsn;
output		     [1:0]		M2_DDR2_odt;
output		          		M2_DDR2_ras_n;
output		     [1:0]		M2_DDR2_SA;
output		          		M2_DDR2_SCL;
inout		          		M2_DDR2_SDA;
output		          		M2_DDR2_we_n;
*/

//////////// GPIO_0, GPIO_0 connect to LTM - 4.3" LCD and Touch //////////
input		          		lcdtouchLTM_ADC_BUSY;
output		          		lcdtouchLTM_ADC_DCLK;
output		          		lcdtouchLTM_ADC_DIN;
input		          		lcdtouchLTM_ADC_DOUT;
input		          		lcdtouchLTM_ADC_PENIRQ_n;
output		     [7:0]		lcdtouchLTM_B;
output		          		lcdtouchLTM_DEN;
output		     [7:0]		lcdtouchLTM_G;
output		          		lcdtouchLTM_GREST;
output		          		lcdtouchLTM_HD;
output		          		lcdtouchLTM_NCLK;
output		     [7:0]		lcdtouchLTM_R;
output		          		lcdtouchLTM_SCEN;
inout		          		lcdtouchLTM_SDA;
output		          		lcdtouchLTM_VD;

/////////// GPIO_1 connected to the capacitive multitouch screen
output	        mtl_dclk;
output [7:0]	mtl_r;
output [7:0]	mtl_g;
output [7:0]	mtl_b;
output      	mtl_hsd;
output      	mtl_vsd;
output      	mtl_touch_i2cscl;
inout       	mtl_touch_i2csda;
input       	mtl_touch_int;

//=======================================================
//  External PLL Configuration
//  (left over from using XCVR links
//=======================================================

  //  Signal declarations
  wire [ 3: 0]  clk1_set_wr, clk2_set_wr, clk3_set_wr;
  wire          conf_ready;
  wire          counter_max;
  wire [7:0]    counter_inc;
  reg [7:0]     auto_set_counter;
  reg           conf_wr;
  
  // try faster for higher data rate...
  //assign clk3_set_wr = 4'd8; //200 MHZ for 6.4Gb/s links - seems okay
  //assign clk3_set_wr = 4'd10; //250 MHZ for 8Gb/s links? - probably wrong
  //assign clk3_set_wr = 4'd16; //400 MHZ for 8Gb/s links? - wrong!
  
  // Settings generated from Terasic System Builder tool...
  assign clk1_set_wr = 4'd4; //100 MHZ
  assign clk2_set_wr = 4'd4; //100 MHZ
  assign clk3_set_wr = 4'd11; //312.5 MHZ
  // assign clk3_set_wr = 4'd12; //625 MHZ - I didn't get brave enough to try this!
  
  // synchronize reset signal
  reg           rstn, rstn_metastable;
  always @(posedge OSC_50_BANK2)
	begin
	  rstn_metastable <= CPU_RESET_n;
	  rstn <= rstn_metastable;
	end
  
  assign counter_max = &auto_set_counter;
  assign counter_inc = auto_set_counter + 1'b1;
  
  always @(posedge OSC_50_BANK2 or negedge rstn)
	if(!rstn)
	  begin
		auto_set_counter <= 0;
		conf_wr <= 0;
	  end 
	else if (counter_max)
	  conf_wr <= 1;
	else
	  auto_set_counter <= counter_inc;
  
  
  ext_pll_ctrl ext_pll_ctrl_Inst(
	.osc_50(OSC_50_BANK2), //50MHZ
    .rstn(rstn),
    
    // device 1 (HSMA_REFCLK)
    .clk1_set_wr(clk1_set_wr),
    .clk1_set_rd(),
    
    // device 2 (HSMB_REFCLK)
    .clk2_set_wr(clk2_set_wr),
    .clk2_set_rd(),

    // device 3 (PLL_CLKIN/SATA_REFCLK)
    .clk3_set_wr(clk3_set_wr),
    .clk3_set_rd(),

    // setting trigger
    .conf_wr(conf_wr), // 1T 50MHz 
    .conf_rd(), // 1T 50MHz

    // status 
    .conf_ready(conf_ready),
    
    // 2-wire interface 
    .max_sclk(MAX_I2C_SCLK),
    .max_sdat(MAX_I2C_SDAT)
    );

  // clocks generated by the mail PLL
  (* keep = 1 *) wire clk150;
  (* keep = 1 *) wire clk100;
  (* keep = 1 *) wire clk50;
  (* keep = 1 *) wire clk33;
  (* noprune *) reg rstn150;
  (* noprune *) reg rstn100;
  (* noprune *) reg rstn50;
  (* noprune *) reg rstn33;
  reg rstn150sample, rstn100sample, rstn50sample, rstn33sample;
  
  mainpll mainpll_inst(
    .inclk0(OSC_50_BANK3),
    .c0(clk100),
    .c1(clk33),
    .c2(clk150),
    .c3(SSRAM_CLK),
    .c4(clk50));
    
  always @(posedge clk33)
    begin
      rstn33sample <= rstn;
      rstn33 <= rstn33sample;
    end

  always @(posedge clk50)
    begin
      rstn50sample <= rstn;
      rstn50 <= rstn50sample;
    end
  
  always @(posedge clk100)
    begin
      rstn100sample <= rstn33;
      rstn100 <= rstn100sample;
    end
  
  always @(posedge clk150)
    begin
      rstn150sample <= rstn33;
      rstn150 <= rstn150sample;
    end
  
  reg [7:0] SW_P;
  always @(posedge OSC_50_BANK2)
    SW_P <= ~SW;  // positive version of DIP switches

  wire [15:0] hexleds;
  assign SEG1_DP = ~0;
  assign SEG1_D  = ~hexleds[14:8];
  assign SEG0_DP = ~0;
  assign SEG0_D  = ~hexleds[6:0];
  
  wire [7:0]  ledg;
  assign LED = ~ledg;
  
  // package up DIP switches (8), Buttons (4), slide switches (4)
  // wire [15:0] switches = {SW, BUTTON, SLIDE_SW};
  
  reg [3:0]   slide_sw_metastable, slide_sw_sync;
  always @(posedge clk150)
    begin
      slide_sw_metastable <= SLIDE_SW;
      slide_sw_sync <= slide_sw_metastable;
    end
  
  //  assign PCIE_WAKE_n = 1'b0;
  //  assign PCIE_SMBDATA = 1'bz;
  
  // signals for the old Terasic resistive touch screen (currently unused)
  wire [7:0] vga_R, vga_G, vga_B;
  wire       vga_DEN, vga_HD, vga_VD;
  
  assign vga_DEN = 1'b0;
  assign vga_HD = 1'b0;
  assign vga_VD = 1'b0;
  assign vga_R = 8'd0;
  assign vga_G = 8'd0;
  assign vga_B = 8'd0;
  
  assign lcdtouchLTM_R = vga_R;
  assign lcdtouchLTM_G = vga_G;
  assign lcdtouchLTM_B = vga_B;
  assign lcdtouchLTM_DEN = vga_DEN;
  assign lcdtouchLTM_HD = vga_HD;
  assign lcdtouchLTM_VD = vga_VD;
  
  assign lcdtouchLTM_GREST = rstn33;
  assign lcdtouchLTM_NCLK = clk33;
  
  assign lcdtouchLTM_SCEN = 1'b1;
  assign lcdtouchLTM_ADC_DCLK = 1'b1;
  assign lcdtouchLTM_ADC_DIN = 1'b1;

  // temperature reading and fan control  
  wire [7:0] temp_val;
  reg [7:0]  temp_dec_r;
  
  temperature_fan_control fan_speed(
    .clk50(OSC_50_BANK2),
    .rstn(rstn),
    .temperatureDegC(temp_val),
    .fanOn(FAN_CTRL));

  // display the temperature
  always @(posedge OSC_50_BANK2)
    begin
      temp_dec_r[3:0] <= temp_val % 10;
      temp_dec_r[7:4] <= temp_val / 10;
    end
  
  hex2leds digit0(.hexval(temp_dec_r[3:0]), .ledcode(hexleds[6:0]));
  hex2leds digit1(.hexval(temp_dec_r[7:4]), .ledcode(hexleds[14:8]));
    
  // clock for multitouch screen
  assign mtl_dclk      = clk33;

  
  (* keep = 1 *) wire        ssram_data_outen;
  (* keep = 1 *) wire [15:0] ssram_data_out;

  // instantiate the touch screen controller provided by Terasic (encrypted block)
  wire touch_ready;
  wire [9:0] touch_x1, touch_x2;
  wire [8:0] touch_y1, touch_y2;
  wire [1:0] touch_count;
  wire [7:0] touch_gesture;
  
  i2c_touch_config touch(
    .iCLK(clk50),
    .iRSTN(rstn50),
    .iTRIG(!mtl_touch_int), // note that this signal is inverted
    .oREADY(touch_ready),
    .oREG_X1(touch_x1),
    .oREG_Y1(touch_y1),
    .oREG_X2(touch_x2),
    .oREG_Y2(touch_y2),
    .oREG_TOUCH_COUNT(touch_count),
    .oREG_GESTURE(touch_gesture),
    .I2C_SCLK(mtl_touch_i2cscl),
    .I2C_SDAT(mtl_touch_i2csda));

  // Qsys project
  nios_system u0 (
    .clk100_clk             (clk100),
    .reset100_reset_n       (rstn100),
    .clk33_clk              (clk33),
    .reset33_reset_n        (rstn33),
    .fbssram_1_ssram_adv    (SSRAM_ADV),
    .fbssram_1_ssram_bwa_n  (SSRAM_BWA_n),
    .fbssram_1_ssram_bwb_n  (SSRAM_BWB_n),
    .fbssram_1_ssram_ce_n   (SSRAM_CE_n),
    .fbssram_1_ssram_cke_n  (SSRAM_CKE_n),
    .fbssram_1_ssram_oe_n   (SSRAM_OE_n),
    .fbssram_1_ssram_we_n   (SSRAM_WE_n),
    .fbssram_1_fsm_a        (FSM_A),
    .fbssram_1_fsm_d_out    (ssram_data_out),
    .fbssram_1_fsm_d_in     (FSM_D),
    .fbssram_1_fsm_dout_req (ssram_data_outen),
    .fbtouch_x1             (touch_x1),
    .fbtouch_y1             (touch_y1),
    .fbtouch_x2             (touch_x2),
    .fbtouch_y2             (touch_y2),
    .fbtouch_count_gesture  ({touch_count,touch_gesture}),
    .fbtouch_touch_valid    (touch_ready),
    .mtl_r                  (mtl_r),
    .mtl_g                  (mtl_g),
    .mtl_b                  (mtl_b),
    .mtl_hsd                (mtl_hsd),
    .mtl_vsd                (mtl_vsd)
    );
  
  // handle tristate ssram data bus
  assign FSM_D         = ssram_data_outen ? ssram_data_out : 16'bzzzzzzzzzzzzzzzz;
                  
  // handle unused flash signals
  assign FLASH_ADV_n   = 1'b1;
  assign FLASH_CE_n    = 1'b1;
  assign FLASH_CLK     = 1'b0;
  assign FLASH_OE_n    = 1'b1;
  assign FLASH_RESET_n = rstn100;
  assign FLASH_WE_n    = 1'b1;

endmodule
