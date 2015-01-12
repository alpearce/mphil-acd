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
import MonadicMegafunctions::*;
import CoProFPMegafunctions::*;

import GetPut::*;
import ClientServer::*;
import List::*;
import StmtFSM::*;
import FloatingPoint::*;
import FIFO::*;

(* synthesize *)
module mkMegafunctionServerTests ();
    `ifndef BLUESIM
        WithInt#(30, MonadicDoubleServer) mfSqrtWrapped <- 
            mkMegafunctionServer(
                mkMonadicDoubleMegafunction(mkVerilogDoubleSqrtMegafunction)
            );
        let mfSqrt = getPayload(mfSqrtWrapped);
    `endif
    let bsvSqrt <- mkFloatingPointSquareRooter();
    
    function toDouble(Bit#(32) raw);
        Float float = unpack(raw);
        Double ret = tpl_1(convert(float, ?, True));
        return ret;
    endfunction

    let tests = map(toDouble, testData);

    Reg#(int) i <- mkRegU;
    Reg#(int) j <- mkRegU;
    Reg#(int) k <- mkRegU;
    mkAutoFSM(par
        for (i <= 0; i < testDataCount; i <= i + 1) seq
            action
                let test = tuple2(tests[i], ?);
                `ifndef BLUESIM
                    mfSqrt.request.put(test);
                `endif
                bsvSqrt.request.put(test);
            endaction
        endseq

        for (j <= 0; j < testDataCount; j <= j + 1) action
            let bsvRes <- bsvSqrt.response.get();
            $display("FROM BSV: %X", tpl_1(bsvRes));
        endaction

        `ifndef BLUESIM
            for (k <= 0; k < testDataCount; k <= k + 1) action
                let mfRes <- mfSqrt.response.get();
                $display("FROM MF: %X", tpl_1(mfRes));
            endaction
        `endif
    endpar);
endmodule
