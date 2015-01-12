/*-
 * Copyright (c) 2013 Colin Rothwell
 * All rights reserved.
 *
 * This software was developed by Colin Rothwell as part of his final year
 * undergraduate project.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
import CoProFPTypes::*;
import ShiftRegister::*;
import PopFIFO::*;

import MIPS::*;

import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import GetPut::*;
import ClientServer::*;
import FloatingPoint::*;

module [Module] mkMegafunctionServer
    #(Module#(Megafunction#(reqType, resultType)) mfModule)
    (WithInt#(delayLength, FloatingPointServer#(reqType, resultType)))
    provisos(Add#(resultTypeWidth, _, 64), Bits#(resultType, resultTypeWidth));

    let intDelayLength = valueOf(delayLength);

    // Should use type parameters
    Reg#(UInt#(1)) opPut <- mkDWire(0);
    Reg#(UInt#(1)) opGot <- mkDWire(0);
    Reg#(UInt#(5)) operationsInProgress <- mkReg(0);
    ShiftRegister#(delayLength, Bool) resultValid <- mkDefaultShiftRegister(False);
    FIFOF#(Tuple2#(resultType, FloatingPoint::Exception)) results 
        <- mkSizedBypassFIFOF(intDelayLength);

    let mfToWrap <- mfModule;

    rule updateOperationsInProgress;
        operationsInProgress <= operationsInProgress + 
            zeroExtend(opPut) - zeroExtend(opGot);
    endrule
    
    (* fire_when_enabled *)
    rule takeValidResult (resultValid.getTail());
        results.enq(mfToWrap.result());
    endrule

    interface FloatingPointServer payload;
        interface Put request;
            method Action put(reqType data) 
                    if (operationsInProgress < fromInteger(intDelayLength));

                opPut <= 1;
                resultValid.setHead(True);
                mfToWrap.place(data);
            endmethod
        endinterface

        interface Get response;
            method ActionValue#(Tuple2#(resultType, FloatingPoint::Exception)) get();
                opGot <= 1;
                let res <- popFIFOF(results);
                return res;
            endmethod
        endinterface
    endinterface
endmodule
