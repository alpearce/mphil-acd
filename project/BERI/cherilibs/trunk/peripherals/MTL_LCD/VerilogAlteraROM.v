/*-
 * Copyright (c) 2012 Simon W. Moore
 * All rights reserved.
 *
 * This software was previously released by the author to students at
 * the University of Cambridge and made freely available on the web.  It
 * has been included for this project under the following license.
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

 Paramererised Verilog Altera ROM
 ================================
 
 Verilog stub for Altera's Quartus tools to provide a generic ROM interface 
 for AlteraROM.bsv

 *****************************************************************************/

module VerilogAlteraROM(clk, v_addr, v_data, v_en, v_rdy);

  parameter ADDRESS_WIDTH=11;
  parameter MEM_SIZE=(1<<ADDRESS_WIDTH);
  parameter DATA_WIDTH=8;
  parameter FILENAME="your_rom_data.mif";

  input                       clk;
  input [ADDRESS_WIDTH-1:0]   v_addr;
  output reg [DATA_WIDTH-1:0] v_data;
  input                       v_en;
  output reg                  v_rdy;

  (* ram_init_file = FILENAME *) reg [DATA_WIDTH-1:0]    rom [0:MEM_SIZE-1];
  
  always @(posedge clk) begin
    v_rdy <= v_en;
    if(v_en)
      v_data <= rom[v_addr];
  end

endmodule // Verilog_AlteraROM
