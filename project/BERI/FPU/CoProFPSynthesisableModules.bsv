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
import CoProFPOpModules::*;
import BufferServer::*;
import CoProFPParallelCombinedServer::*;
import CoProFPTypes::*;
import MonadicMegafunctions::*;
import DiadicMegafunctions::*;
import CoProFPMegafunctions::*;
import CoProFPServerCreation::*;

import FloatingPoint::*;
import ClientServer::*;
import GetPut::*;

(* synthesize, options="-aggressive-conditions" *)
module mkConcreteFloatAddServers(CombinedDiadicServers);
    let worker <- mkCombinedDiadicServers(mkFloatingPointAdder, 8);
    return worker;
endmodule

(* synthesize, options="-aggressive-conditions" *)
module mkConcreteDoubleAddServer(DiadicDoubleServer);
    let worker <- mkBufferOutputServer(mkFloatingPointAdder, 8);
    return worker;
endmodule

(* synthesize, options="-aggressive-conditions" *)
module mkConcreteDoubleDivServer(DiadicDoubleServer);
    `ifdef BLUESIM
        let mkDivider = mkFloatingPointDivider;
    `else
        let mkDivider = mkUnbufferedDoubleDivServer;
    `endif

    let worker <- mkBufferOutputServer(mkDivider, 4);
    return worker;
endmodule

(* synthesize, options="-aggressive-conditions" *)
module mkConcreteFloatMulServers(CombinedDiadicServers);
    let worker <- mkCombinedDiadicServers(mkFloatingPointMultiplier, 8);
    return worker;
endmodule

(* synthesize, options="-aggressive-conditions" *)
module mkConcreteDoubleMulServer(DiadicDoubleServer);
    let worker <- mkBufferOutputServer(mkFloatingPointMultiplier, 8);
    return worker;
endmodule

module [Module] mkUnbufferedDoubleSqrtServer(MonadicDoubleServer);
    WithInt#(30, MonadicDoubleServer) mfSqrtWrapped <- mkMegafunctionServer(
            mkMonadicDoubleMegafunction(mkVerilogDoubleSqrtMegafunction)
    );
    return getPayload(mfSqrtWrapped);
endmodule

module [Module] mkUnbufferedDoubleDivServer(DiadicDoubleServer);
    WithInt#(10, DiadicDoubleServer) mfDivWrapped <- mkMegafunctionServer(
        mkDiadicDoubleMegafunction(mkVerilogDoubleDivMegafunction)
    );
    return getPayload(mfDivWrapped);
endmodule
