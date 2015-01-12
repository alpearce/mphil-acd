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
import PopFIFO::*;

import MIPS::*;

import GetPut::*;
import ClientServer::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import FloatingPoint::*;

function DiadFPRequest#(Float) getLowRequest(DiadFPRequest#(PairedSingle) args);
    let left = tpl_1(args);
    let right = tpl_2(args);
    return tuple3(tpl_1(left), tpl_1(right), tpl_3(args));
endfunction

function DiadFPRequest#(Float) getHighRequest(DiadFPRequest#(PairedSingle) args);
    let left = tpl_1(args);
    let right = tpl_2(args);
    return tuple3(tpl_2(left), tpl_2(right), tpl_3(args));
endfunction

module [Module] mkCombinedDiadicServers
    #(Module#(DiadicFloatServer) mkServer, Integer fifoLength)
    (CombinedDiadicServers);

    FIFO#(AbstractFormat) requestTypes <- mkSizedFIFO(6);
    FIFO#(Tuple2#(Float, FloatingPoint::Exception)) floatOutput <-
        mkSizedFIFO(fifoLength);
    FIFO#(Tuple2#(PairedSingle, FloatingPoint::Exception)) pairedSingleOutput <-
        mkSizedFIFO(fifoLength);

    let lowSrv <- mkServer();
    let highSrv <- mkServer();

    (* fire_when_enabled *)
    rule processResult;
        let response <- lowSrv.response.get();
        let responseType <- popFIFO(requestTypes);
        case (responseType)
            SINGLE: begin
                floatOutput.enq(response);
            end
            PAIREDSINGLE: begin
                //TODO: Exceptions properly!
                let resultHigh <- highSrv.response.get();
                let val = tuple2(tpl_1(response), tpl_1(resultHigh));
                pairedSingleOutput.enq(tuple2(val, tpl_2(response)));
            end
        endcase
    endrule

    interface DiadicFloatServer float;
        interface Put request;
            method Action put(DiadFPRequest#(Float) req);
                requestTypes.enq(SINGLE);
                lowSrv.request.put(req);
            endmethod
        endinterface
        interface Get response = toGet(floatOutput);
    endinterface

    interface DiadicPairedSingleServer pairedSingle;
        interface Put request;
            method Action put(DiadFPRequest#(PairedSingle) req);
                requestTypes.enq(PAIREDSINGLE);
                lowSrv.request.put(getLowRequest(req));
                highSrv.request.put(getHighRequest(req));
            endmethod
        endinterface
        interface Get response = toGet(pairedSingleOutput);
    endinterface
endmodule
