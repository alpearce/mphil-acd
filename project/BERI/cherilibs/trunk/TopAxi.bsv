/*-
* Copyright (c) 2014 Colin Rothwell
* Copyright (c) 2014 Alexandre Joannou
* All rights reserved.
*
* This software was developed by SRI International and the University of
* Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-10-C-0237
* ("CTSRD"), as part of the DARPA CRASH research programme.
*
* This software was developed by SRI International and the University of
* Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249
* ("MRC2"), as part of the DARPA MRC research programme.
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
*/

import Processor::*; // The interface
import Proc::*; // The implementation
import Peripheral::*; // BlueBus interfaces and counter
import CheriAxi::*;
import MemTypes::*;
import AvalonStreaming::*;
import AxiBridge::*;
import BeriBootMem::*;
import Interconnect::*;
import NumberTypes::*;
import MasterSlave::*;
import InternalPeriphBridge::*;
import InternalToAxi::*;

import TLM3::*;
import Axi::*;
import Vector::*;
import BRAM::*;
import Connectable::*;

`include "parameters.bsv"

typedef Vector#(CORE_COUNT, AvalonStreamSinkPhysicalIfc#(Bit#(8))) DebugSinks;
typedef Vector#(CORE_COUNT, AvalonStreamSourcePhysicalIfc#(Bit#(8))) DebugSources;
typedef Vector#(CORE_COUNT, Tuple2#(AvalonStreamSinkPhysicalIfc#(Bit#(8)),
    AvalonStreamSourcePhysicalIfc#(Bit#(8)))) DebugPhysicals;

interface TopAxi;
    (* prefix = "axm_memory" *)
    interface AxiWrMaster#(`PRM_CHERI) write_master;
    (* prefix = "axm_memory" *)
    interface AxiRdMaster#(`PRM_CHERI) read_master;

    `ifdef TRACE
    (* prefix = "axm_trace" *)
    interface AxiWrMaster#(`PRM_TRACE) trace_write_master;
    (* prefix = "axm_trace" *)
    interface AxiRdMaster#(`PRM_TRACE) trace_read_master;
    `endif

    interface DebugSinks debug_stream_sinks;
    interface DebugSources debug_stream_sources;

    (* always_ready, always_enabled *)
    method Action irq(Bit#(32) irqs);

    (* always_ready, always_enabled *)
    method Bool reset_n_out();
endinterface

/* TopAxi overview
 *
 *                           proc
 *                            |
 *                            v
 *              -------- oredered bus --------
 *              |                            |
 *              v                            v
 *        periph bridge                   forward
 *              |                            |
 *              v                            v
 *    ---- ordered bus -----         -- ordered bus --
 *    |       |       |    |         |               |
 *    v       v       v    v         v               v
 * bootmem   cnt     pic  null    AxiRead         AxiWrite
 *                                  ||               ||
 *                                  vv               vv
 *
 */
 
 typedef TLog#(TAdd#(3,CORE_COUNT))          LogPeriphs;
 typedef TAdd#(3,CORE_COUNT)                 PeriphCount;
 typedef BuffIndex#(LogPeriphs, PeriphCount) PeriphBuffIndex;

(* synthesize,
   reset_prefix = "csi_clockreset_reset_n",
   clock_prefix = "csi_clockreset_clk" *)
module mkTopAxi(TopAxi);

    Reg#(Bit#(32)) qsysIrqs <- mkReg(0);

    Processor processor <- mkCheri();

    //////////////////////////////
    // Internal peripherals Bus //
    ///////////////////////////////////////////////////////////////////////////
    // peripherals (slaves)
    Peripheral#(0) counter <- mkCountPerif;
    Peripheral#(0) bootMem <- mkBootMem;
    Peripheral#(0) nullPer <- mkNullPerif;
    
    // wiring up slaves
    Vector#(PeriphCount, Slave#(CheriMemRequest64, CheriMemResponse64)) peripheralSlaves = newVector();
    peripheralSlaves[0] = nullPer.slave;
    peripheralSlaves[1] = counter.slave;
    peripheralSlaves[2] = bootMem.slave;
    for (Integer i=0; i<valueOf(CORE_COUNT); i=i+1)
      peripheralSlaves[i+3] = processor.pic[i].slave;
    // peripheral bridge (master)
    InternalPeripheralBridge peripheralBridge <- mkInternalPeripheralBridge;
    // helper function to route a packet to the right output
    function Maybe#(PeriphBuffIndex) routePeripheral (CheriMemRequest64 r);
        // Main memory by default
        PeriphBuffIndex ret = BuffIndex{bix: 0};
        if (pack(getRoutingField(r))[31:0] == 32'h7F800000) ret.bix = 1;
        else if (pack(getRoutingField(r))[30:17] == 14'h2000) ret.bix = 2;
        // Layout the pics in sequential addresses starting at 7F804000
        for (Integer i=0; i<valueOf(CORE_COUNT); i=i+1)
          if (pack(getRoutingField(r))[31:14] == (20'h7F804 + fromInteger(i)*20'h00004)[19:2]) ret.bix = fromInteger(i)+3;
        return tagged Valid ret;
    endfunction
    // Bus 
    mkSingleMasterOrderedBus(
        peripheralBridge.master,
        peripheralSlaves, routePeripheral, 32
    );

    /////////////////////////////////////
    // Axi split interface ordered Bus //
    ///////////////////////////////////////////////////////////////////////////
    // InternalToAxi translators (slaves)
    InternalToAxiRead  axi_read  <- mkInternalToAxiRead;
    InternalToAxiWrite axi_write <- mkInternalToAxiWrite;
    // wiring up slaves
    Vector#(2, Slave#(CheriMemRequest, CheriMemResponse)) splitSlaves = newVector();
    splitSlaves[0] = axi_read.slave;
    splitSlaves[1] = axi_write.slave;
    // Forward module (master)
    Forward#(CheriMemRequest, CheriMemResponse) forward <- mkForward;
    // helper function to route a packet to the right output
    function Maybe#(BuffIndex#(1, 2)) routeAxiReq (CheriMemRequest r);
        BuffIndex#(1,2) ret = BuffIndex{bix: 0};
        case (r.operation) matches
            tagged Read .rop: begin
                ret.bix = 0;
            end
            tagged Write .wop: begin
                ret.bix = 1;
            end
        endcase
        return tagged Valid ret;
    endfunction
    // Bus 
    mkSingleMasterOrderedBus(
        forward.master,
        splitSlaves, routeAxiReq, 32
    );

    //////////////
    // main Bus //
    ///////////////////////////////////////////////////////////////////////////
    // wiring up slaves
    Vector#(2, Slave#(CheriMemRequest, CheriMemResponse)) interconnectSlaves = newVector();
    interconnectSlaves[0] = forward.slave;
    interconnectSlaves[1] = peripheralBridge.slave;
    // helper function to route a packet to the right output
    function Maybe#(BuffIndex#(1, 2)) route (CheriMemRequest r);
        // Main memory by default
        BuffIndex#(1,2) ret = BuffIndex{bix: 0};
        if (pack(getRoutingField(r))[30:23] == 8'hff) ret.bix = 1;
        else if (pack(getRoutingField(r))[30:17] == 14'h2000) ret.bix = 1;
        return tagged Valid ret;
    endfunction
    // Bus 
    mkSingleMasterOrderedBus(
        processor.extMemory, 
        interconnectSlaves, route, 32 // transactions.
    );

    ///////////
    // Debug //
    ///////////
    ///////////////////////////////////////////////////////////////////////////
    // TODO: Port and connect tracing interface.
    module mkConnectDebug
        #(Server#(Bit#(8), Bit#(8)) beriside)
        (Tuple2#(AvalonStreamSinkPhysicalIfc#(Bit#(8)),
                 AvalonStreamSourcePhysicalIfc#(Bit#(8))));

        let get <- mkAvalonStreamSink2Get();
        let put <- mkPut2AvalonStreamSource();
        mkConnection(get.rx, beriside.request);
        mkConnection(beriside.response, put.tx);

        return tuple2(get.physical, put.physical);
    endmodule

    DebugPhysicals debugs <- mapM(mkConnectDebug, processor.debugStream);
    
    (* fire_when_enabled, no_implicit_conditions*)
    rule irqFeedThrough;
        // blueBusIrqs (in well defined positions) grow from the top.
        // Currently there are no blueBusIrqs.
        // qsysIrqs grow from the bottom.
        processor.putIrqs(qsysIrqs);
    endrule

    method Action irq(Bit#(32) irqs);
        qsysIrqs <= irqs;
    endmethod

    method Bool reset_n_out = processor.reset_n;

    interface debug_stream_sinks = map(tpl_1, debugs);
    interface debug_stream_sources = map(tpl_2, debugs);

    interface read_master  = axi_read.master;
    interface write_master = axi_write.master;

endmodule
