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
import MegafunctionTestBench::*;
import SingleToMIPSReg::*;
import CoProFPConversionModules::*;
import CoProFPTypes::*;

import MIPS::*;

import List::*;
import GetPut::*;

(* synthesize *)
module mkFloatingPointConversionTest(Empty);

    let data = map(singleToMIPSReg, testData);
    
    Reg#(int) nextDatumToLoad <- mkReg(0);
    Reg#(int) nextDatumToRead <- mkReg(0);

    let singleToDoubleServer <- mkSingleToDoubleServer(1);
    let doubleToSingleServer <- mkDoubleToSingleServer(1);

    rule loadSingleToDouble (nextDatumToLoad < testDataCount);
        let datum = data[nextDatumToLoad];
        singleToDoubleServer.request.put(data[nextDatumToLoad]);
        nextDatumToLoad <= nextDatumToLoad + 1;
    endrule

    rule loadDoubleToSingle;
        let resp <- singleToDoubleServer.response.get();
        doubleToSingleServer.request.put(resp);
    endrule

    rule readDatum;
        let result <- doubleToSingleServer.response.get();
        let expected = data[nextDatumToRead];
        String isMatch;
        if (result == expected)
            isMatch = "Match! :)";
        else
            isMatch = "!! MISMATCH !! :(";
        $display("%d: Expected %X, Got %X. %s", nextDatumToRead, expected, result, isMatch);
        nextDatumToRead <= nextDatumToRead + 1;
    endrule

    rule finish (nextDatumToRead == testDataCount);
        $finish();
    endrule
endmodule
