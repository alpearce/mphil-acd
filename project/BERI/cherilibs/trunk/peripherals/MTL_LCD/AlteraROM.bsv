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

 Altera ROM
 ==========
 
 Provides a Bluespec wrapper around a ROM initialised from a "mif" (memory
 initialisation file).  The ROM is described in Verilog in VerilogAlteraROM.v
 
 *****************************************************************************/


package AlteraROM;

import GetPut::*;
import ClientServer::*;
import FIFO::*;

interface AlteraROM_Ifc#(type addrT, type dataT);
  method Action read_request(addrT addr);
  method dataT read_response;
endinterface


import "BVI" VerilogAlteraROM =
module mkAlteraROM #(String filename) (AlteraROM_Ifc#(addrT, dataT))
  provisos(Bits#(addrT, addr_width),
           Bits#(dataT, data_width));
  parameter FILENAME = filename;
  parameter ADDRESS_WIDTH = valueOf(addr_width);
  parameter DATA_WIDTH = valueof(data_width);
  method read_request (v_addr)
    enable (v_en);
  method v_data read_response;
    default_clock clk(clk, (*unused*) clk_gate);
    default_reset no_reset;
    schedule (read_response) SBR (read_request);
    schedule (read_response) C (read_response);
    schedule (read_request) C (read_request);
endmodule


module mkAlteraROMServer#(String romfile)(Server#(addrT,dataT))
  provisos(Bits#(addrT, addr_width),
	   Bits#(dataT, data_width));
  
  AlteraROM_Ifc#(addrT,dataT) rom <- mkAlteraROM(romfile);
  FIFO#(Bool) seq_fifo <- mkFIFO1;
  
  interface Put request;
    method Action put(addr);
      rom.read_request(addr);
      seq_fifo.enq(True);
    endmethod
  endinterface
  interface Get response;
    method ActionValue#(dataT) get;
      seq_fifo.deq;
      let data = rom.read_response();
      return data;
    endmethod
  endinterface
endmodule


endpackage
