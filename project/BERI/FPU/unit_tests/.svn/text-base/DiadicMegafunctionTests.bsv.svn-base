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
import DiadicSingleMegafunctions::*;

import MegafunctionTestBench::*;

(* synthesize *)
module mkDiadicMegafunctionTests (Empty);
    let addMegafunction <- mkVerilogAddMegafunction;
    let addTb <- mkDiadicMegafunctionTestBench(addMegafunction, 7, "Add");

    let mulMegafunction <- mkVerilogMulMegafunction;
    let mulTb <- mkDiadicMegafunctionTestBench(mulMegafunction, 5, "Multiply");

    let divMegafunction <- mkVerilogDivMegafunction;
    let divTb <- mkDiadicMegafunctionTestBench(divMegafunction, 6, "Divide");

    let subMegafunction <- mkVerilogSubMegafunction;
    let subTb <- mkDiadicMegafunctionTestBench(subMegafunction, 7, "Subtract");

    rule finish(addTb.done() &&
                mulTb.done() &&
                divTb.done() &&
                subTb.done());
        $finish();
    endrule
endmodule
