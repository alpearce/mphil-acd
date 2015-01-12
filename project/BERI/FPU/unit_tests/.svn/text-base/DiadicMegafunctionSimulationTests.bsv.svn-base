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
import CoProFPTypes::*;
import CoProFPSimulatedOps::*;
import CoProFPMegafunctionSimulation::*;
import MegafunctionTestBench::*;

import MIPS::*;

import List::*;

interface DiadicSimulatedMegafunctionTestBench#(numeric type delay);
    method Bool done();
endinterface

(* synthesize *)
module mkDiadicMegafunctionSimulationTests (Empty);
    DiadicSimulatedMegafunctionTestBench#(7) addTb <-
        mkSimulatedDiadicMegafunctionTestBench(add_fn, "Add");

    DiadicSimulatedMegafunctionTestBench#(5) mulTb <-
        mkSimulatedDiadicMegafunctionTestBench(mul_fn, "Multiply");

    DiadicSimulatedMegafunctionTestBench#(6) divTb <-
        mkSimulatedDiadicMegafunctionTestBench(div_fn, "Divide");

    DiadicSimulatedMegafunctionTestBench#(7) subTb <-
        mkSimulatedDiadicMegafunctionTestBench(sub_fn, "Subtract");

    rule finish(addTb.done() &&
                mulTb.done() && 
                divTb.done() && 
                subTb.done());
        $finish();
    endrule
endmodule

module [Module] mkSimulatedDiadicMegafunctionTestBench
    #(function Bit#(32) calculate(Bit#(32) left, Bit#(32) right),
      parameter String tag)
    (DiadicSimulatedMegafunctionTestBench#(delay))
    provisos(Add#(unused, 1, delay)); // delay <= 1 so piplining it works 

    SimulatedDiadicMegafunction#(delay) delayedFunction <- 
        mkSimulatedDiadicMegafunction(calculate);

    int delayInt = fromInteger(valueOf(delay));
    MegafunctionTestBench testBench <- 
        mkDiadicMegafunctionTestBench(delayedFunction.mf, delayInt, tag);

    method Bool done();
        return testBench.done();
    endmethod
endmodule
