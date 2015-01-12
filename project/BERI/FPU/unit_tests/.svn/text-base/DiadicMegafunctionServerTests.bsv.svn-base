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

import MegafunctionTestBench::*;
import CoProFPSynthesisableModules::*;
import CoProFPParallelCombinedServer::*;
import PopFIFO::*;
import CoProFPTypes::*;
import CoProFPServerCreation::*;

import MIPS::*;

import GetPut::*;
import ClientServer::*;
import List::*;
import StmtFSM::*;
import FloatingPoint::*;
import FIFO::*;

(* synthesize *)
module mkMegafunctionServerTests ();
    `ifdef MEGAFUNCTIONS
        let floatAddServers <-
            mkCombinedDiadicServers(mkMegafunctionServer(mkVerilogAddMegafunction));
    `else
        let floatAddServers <- mkConcreteFloatAddServers();
    `endif

    FIFO#(Tuple3#(Float, Float, RoundMode)) enteredTests <- mkFIFO();

    let tests = map(unpack, testData);

    Reg#(int) i <- mkRegU;
    Reg#(int) j <- mkRegU;
    mkAutoFSM(seq
        for (i <= 0; i < testDataCount; i <= i + 1) seq
            for (j <= 0; j < testDataCount; j <= j + 1) seq
                action
                    let test = tuple3(tests[i], tests[j], ?);
                    enteredTests.enq(test);
                    floatAddServers.float.request.put(test);
                endaction
            endseq
        endseq
    endseq);

    rule outputResults;
        let test <- popFIFO(enteredTests);
        let res <- floatAddServers.float.response.get();
        $display("%X + %X = %X", tpl_1(test), tpl_2(test), tpl_1(res));
    endrule

endmodule
