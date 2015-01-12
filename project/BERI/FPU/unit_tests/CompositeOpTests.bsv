#-
# Copyright (c) 2013 Colin Rothwell
# All rights reserved.
#
# This software was developed by Colin Rothwell as part of his final year
# undergraduate project.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
import List::*;

import MIPS::*;

import MegafunctionTestBench::*;
import CoProFPCompositeServers::*;
import CoProFPTypes::*;

import GetPut::*;

List#(MIPSReg) testDoubles =
    cons('h3FF0000000000000, // 1
    cons('h3FC555555530AED6, // 0.1666666
    cons('hC06D5431F8A0902E, // -234.6311
    cons('h41E1808E6C666666, // some random big number
    nil))));

int testDoubleCount = fromInteger(length(testDoubles));

(* synthesize *)
module mkCompositeOpTests(Empty);
    let recipTest <- mkDualMonadicServerTest(mkRecipServers (1), "Recip");
    let recipSqrtTest <- mkDualMonadicServerTest(mkRecipSqrtServers (1), "RecipSqrt");

    rule finish (recipTest.done() && recipSqrtTest.done());
        $finish();
    endrule
endmodule

interface Test;
    method Bool done();
endinterface

module [Module] mkDualMonadicServerTest
    #(Module#(DualServers#(MonadicServer)) mkTestServers, String tag)
    (Test);

    let testServers <- mkTestServers;
    let singleServer = testServers.single;
    let doubleServer = testServers.double;

    Reg#(Bool) placingDoubles <- mkReg(False);
    Reg#(Bool) takingDoubles <- mkReg(False);
    Reg#(Bool) finished <- mkReg(False);
    Reg#(int) in <- mkReg(0);
    Reg#(int) out <- mkReg(0);

    rule placeSingle (!placingDoubles);
        singleServer.request.put(signExtend(testData[in]));
        let nextIn = in + 1;
        if (nextIn < testDataCount)
            in <= nextIn;
        else begin
            in <= 0;
            placingDoubles <= True;
        end
    endrule

    rule takeSingle (!takingDoubles);
        $display("%d: %sSingle Result %X", out, tag, singleServer.response.get());
        let nextOut = out + 1;
        if (nextOut < testDataCount)
            out <= nextOut;
        else begin
            out <= 0;
            takingDoubles <= True;
        end
    endrule

    rule placeDouble (placingDoubles && in < testDoubleCount);
        doubleServer.request.put(testDoubles[in]);
        in <= in + 1;
    endrule

    rule takeDouble (takingDoubles && !finished);
        $display("%d: %sDouble Result %X", out, tag, doubleServer.response.get());
        let nextOut = out + 1;
        if (nextOut < testDoubleCount)
            out <= nextOut;
        else
            finished <= True;
    endrule

    method Bool done();
        return finished;
    endmethod
endmodule
