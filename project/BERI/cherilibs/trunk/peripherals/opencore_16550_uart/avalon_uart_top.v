/*-
 * Copyright (c) 2013 Simon W. Moore
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
 * Avalon wrapper around the UART core with wishbone interface discarded.
 */

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on


module avalon_uart_top	(
    // byte wide Avalon slave interface
    input        avc_c1_clk,
    input        avc_c1_reset,
    input [4:0]  avs_s1_address,
    input [7:0]  avs_s1_writedata,
    input        avs_s1_write,
    input        avs_s1_read,
    output       avs_s1_waitrequest,
    output [7:0] avs_s1_readdata, // SWM use 8-bit rather than 32-bit bus
    output       avi_int_irq,
    
    // export signals for the UART
    input        srx_pad_i,
    output       stx_pad_o,
    output       rts_pad_o,
    input        cts_pad_i,
    output       dtr_pad_o,
    input        dsr_pad_i,
    input        ri_pad_i,
    input        dcd_pad_i
  );

  assign avs_s1_waitrequest = 0;
  
  uart_regs the_uart_regs
    (
     .clk          (avc_c1_clk),
     .wb_rst_i     (avc_c1_reset),
     .wb_addr_i    (avs_s1_address[4:2]),
     .wb_dat_i     (avs_s1_writedata),
     .wb_dat_o     (avs_s1_readdata),
     .wb_we_i      (avs_s1_write),
     .wb_re_i      (avs_s1_read),
     .modem_inputs ({cts_pad_i, dsr_pad_i, ri_pad_i,  dcd_pad_i}),
     .stx_pad_o    (stx_pad_o),
     .srx_pad_i    (srx_pad_i),
     .rts_pad_o    (rts_pad_o), 
     .dtr_pad_o    (dtr_pad_o), 
     .int_o        (avi_int_irq)
     );
     
endmodule


