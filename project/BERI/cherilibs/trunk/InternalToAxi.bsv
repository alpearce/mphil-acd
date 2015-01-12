/*-
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

import MasterSlave::*;
import MemTypes::*;
import FIFOF::*;
import SpecialFIFOs::*;
import DefaultValue::*;
import Axi::*;
import Debug::*;
import Assert::*;

`include "parameters.bsv"

interface InternalToAxiRead;
    interface Slave#(CheriMemRequest, CheriMemResponse) slave;
    interface AxiRdMaster#(`PRM_CHERI) master;
endinterface

interface InternalToAxiWrite;
    interface Slave#(CheriMemRequest, CheriMemResponse) slave;
    interface AxiWrMaster#(`PRM_CHERI) master;
endinterface

typedef AxiAddrCmd#(`PRM_CHERI) CheriAxiAddrCmd;
typedef AxiRdResp#(`PRM_CHERI) CheriAxiRdResp;
typedef AxiWrData#(`PRM_CHERI) CheriAxiWrData;
typedef AxiWrResp#(`PRM_CHERI) CheriAxiWrResp;

(* synthesize *)
module mkInternalToAxiRead (InternalToAxiRead);

    FIFOF#(CheriMemRequest)  req  <- mkFIFOF;
    FIFOF#(CheriMemResponse) resp <- mkFIFOF;

    Wire#(CheriAxiAddrCmd) ar_channel <- mkDWire(defaultValue);
    Wire#(Bool) ar_ready <- mkDWire(False);

    Wire#(AxiId#(`PRM_CHERI))   r_id   <- mkDWire(defaultValue);
    Wire#(AxiData#(`PRM_CHERI)) r_data <- mkDWire(defaultValue);
    Wire#(AxiResp)              r_resp <- mkDWire(SLVERR);
    Wire#(Bool)                 r_last <- mkDWire(False);
    Wire#(Bool) r_valid <- mkDWire(False);

    CheriAxiAddrCmd ar_chan = defaultValue;
    case (req.first.operation) matches
        tagged Read .rop: begin
            ar_chan.id    = zeroExtend(pack(req.first.masterID));
            ar_chan.addr  = pack(req.first.addr);
            ar_chan.len   = unpack(zeroExtend(pack(rop.noOfFlits))); // same encoding of the field
            ar_chan.size  = unpack(pack(rop.bytesPerFlit)); // same encoding of the field
            ar_chan.burst = INCR;
            //TODO why does that not build ? ar_chan.lock  <= NORMAL;
            ar_chan.lock  = unpack(0);
            ar_chan.cache = unpack(4'b0010); // Normal Non-cacheable Non-Bufferable, see chap. A4.4 of AXI doc
            ar_chan.prot  = unpack(3'b010);  // Unpriviledged Non-secure Data access, see chap. A4.7 of AXI doc
        end
        /*
        default: begin
            dynamicAssert(False, "only read requests are handled");
        end
        */
    endcase

    rule ar_channel_wire_up;
        ar_channel <= ar_chan;
    endrule

    rule consume_request (ar_ready);
        req.deq;
        debug2("axiRead", $display("<time %0t, AxiRead> consume req", $time));
    endrule

    rule receive_response (r_valid);
        CheriMemResponse internalResp;
        internalResp.masterID = unpack(truncate(r_id));
        internalResp.transactionID = 0; // XXX see AXI doc chap. A5.3.5 and A5.3.6
        internalResp.error = r_resp == OKAY ? NoError : SlaveError;
        internalResp.operation = tagged Read {
            data: Data{
                `ifdef CAP
                cap: unpack(0),
                `endif
                data: r_data
            },
            last: r_last
        };
        resp.enq(internalResp);
        debug2("axiRead", $display("<time %0t, AxiRead> enq rsp", $time));
    endrule

    ////////////////
    // Interfaces //
    ////////////////

    interface AxiRdMaster master;
        // Address Outputs
        method AxiId#(`PRM_CHERI)   arID    = ar_channel.id;
        method AxiAddr#(`PRM_CHERI) arADDR  = ar_channel.addr;
        method AxiLen               arLEN   = ar_channel.len;
        method AxiSize              arSIZE  = ar_channel.size;
        method AxiBurst             arBURST = ar_channel.burst;
        method AxiLock              arLOCK  = ar_channel.lock;
        method AxiCache             arCACHE = ar_channel.cache;
        method AxiProt              arPROT  = ar_channel.prot;
        // control flow output
        method Bool arVALID = req.notEmpty;
        // control flow input
        method Action arREADY(Bool value) =
            action ar_ready <= value; endaction;

        // Response Inputs
        method Action rID(AxiId#(`PRM_CHERI) value) =
            action r_id <= value; endaction;
        method Action rDATA(AxiData#(`PRM_CHERI) value) =
            action r_data <= value; endaction;
        method Action rRESP(AxiResp value) =
            action r_resp <= value; endaction;
        method Action rLAST(Bool value) =
            action r_last <= value; endaction;
        // control flow input
        method Action rVALID(Bool value) =
            action r_valid <= value; endaction;
        // control flow output
        method Bool rREADY = resp.notFull;
    endinterface

    interface Slave slave;
        interface request  = toCheckedPut(req);
        interface response = toCheckedGet(resp);
    endinterface

endmodule

(* synthesize *)
module mkInternalToAxiWrite (InternalToAxiWrite);

    FIFOF#(CheriMemRequest)  req  <- mkFIFOF;
    FIFOF#(CheriMemResponse) resp <- mkFIFOF;

    FIFOF#(CheriAxiAddrCmd)  aw_backup  <- mkBypassFIFOF;
    Reg#(Bool)               aw_done    <- mkReg(False);

    Wire#(CheriAxiAddrCmd) aw_channel <- mkDWire(defaultValue);
    Wire#(Bool) aw_ready <- mkDWire(False);

    Wire#(CheriAxiWrData) w_channel <- mkDWire(defaultValue);
    Wire#(Bool) w_ready <- mkDWire(False);

    Wire#(AxiId#(`PRM_CHERI)) b_id   <- mkDWire(defaultValue);
    Wire#(AxiResp)            b_resp <- mkDWire(SLVERR);
    Wire#(Bool) b_valid <- mkDWire(False);

    CheriAxiAddrCmd aw_chan = defaultValue;
    CheriAxiWrData  w_chan  = defaultValue;
    case (req.first.operation) matches
        tagged Write .wop: begin
            aw_chan.id    = zeroExtend(pack(req.first.masterID));
            aw_chan.addr  = pack(req.first.addr);
            //TODO update Internal format ? aw_chan.len   <= wop.noOfFlits;
            //TODO --- ? aw_chan.size  <= rop.bytesPerFlit; // same encoding of the field
            aw_chan.burst = INCR;
            //TODO Why does that not build ? aw_chan.lock  <= NORMAL;
            aw_chan.lock  = unpack(0);
            aw_chan.cache = unpack(4'b0010); // Normal Non-cacheable Non-Bufferable, see chap. A4.4 of AXI doc
            aw_chan.prot  = unpack(3'b010);  // Unpriviledged Non-secure Data access, see chap. A4.7 of AXI doc

            w_chan.id     = zeroExtend(pack(req.first.masterID));
            w_chan.data   = wop.data.data;
            w_chan.strb   = pack(wop.byteEnable);
            w_chan.last   = wop.last;
        end
        /*
        default: begin
            dynamicAssert(False, "only write requests are handled");
        end
        */
    endcase

    rule backup_request_aw;
        debug2("axiWrite", $display("<time %0t, AxiWrite> enq aw backup", $time));
        aw_backup.enq(aw_chan);
    endrule

    rule forward_request_aw;
        aw_channel <= aw_backup.first;
    endrule

    rule consume_request_aw (aw_ready);
        debug2("axiWrite", $display("<time %0t, AxiWrite> consume aw req", $time));
        aw_backup.deq;
        aw_done <= True;
    endrule

    rule forward_request_w;
        w_channel <= w_chan;
    endrule

    rule consume_request (!w_chan.last && w_ready);
        req.deq;
        debug2("axiWrite", $display("<time %0t, AxiWrite> consume req", $time));
    endrule
    rule consume_last_request (w_chan.last && w_ready && aw_done);
        aw_done <= False;
        req.deq;
        debug2("axiWrite", $display("<time %0t, AxiWrite> consume req", $time));
    endrule

    rule receive_response (b_valid);
        CheriMemResponse internalResp;
        internalResp.masterID = unpack(truncate(b_id));
        internalResp.transactionID = 0; // XXX see AXI doc chap. A5.3.5 and A5.3.6
        internalResp.error = b_resp == OKAY ? NoError : SlaveError;
        internalResp.operation = tagged Write;
        resp.enq(internalResp);
        debug2("axiWrite", $display("<time %0t, AxiWrite> receive rsp", $time));
    endrule

    ////////////////
    // Interfaces //
    ////////////////

    interface AxiWrMaster master;
        // Address Outputs
        method AxiId#(`PRM_CHERI)   awID    = aw_channel.id;
        method AxiAddr#(`PRM_CHERI) awADDR  = aw_channel.addr;
        method AxiLen               awLEN   = aw_channel.len;
        method AxiSize              awSIZE  = aw_channel.size;
        method AxiBurst             awBURST = aw_channel.burst;
        method AxiLock              awLOCK  = aw_channel.lock;
        method AxiCache             awCACHE = aw_channel.cache;
        method AxiProt              awPROT  = aw_channel.prot;
        // control flow output
        method Bool awVALID = aw_backup.notEmpty;
        // control flow input
        method Action awREADY(Bool value) =
            action aw_ready <= value; endaction;

        // Data Outputs
        method AxiId#(`PRM_CHERI)     wID   = w_channel.id;
        method AxiData#(`PRM_CHERI)   wDATA = w_channel.data;
        method AxiByteEn#(`PRM_CHERI) wSTRB = w_channel.strb;
        method Bool                   wLAST = w_channel.last;
        // control flow output
        method Bool wVALID = req.notEmpty;
        // control flow input
        method Action wREADY(Bool value) =
            action w_ready <= value; endaction;

        // Response Inputs
        method Action bID(AxiId#(`PRM_CHERI) value) =
            action b_id <= value; endaction;
        method Action bRESP(AxiResp value) =
            action b_resp <= value; endaction;
        // control flow input
        method Action bVALID(Bool value) =
            action b_valid <= value; endaction;
        // control flow output
        method Bool bREADY = resp.notFull;
    endinterface

    interface Slave slave;
        interface request  = toCheckedPut(req);
        interface response = toCheckedGet(resp);
    endinterface

endmodule
