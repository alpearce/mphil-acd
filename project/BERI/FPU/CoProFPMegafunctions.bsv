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

import FloatingPoint::*;

module [Module] mkMonadicFloatMegafunction
    #(Module#(VerilogMonadicFloatMegafunction) mkMfToWrap)
    (MonadicFloatMegafunction);

    let mfToWrap <- mkMfToWrap();

    method Action place(Tuple2#(Float, RoundMode) data);
        mfToWrap.place(pack(tpl_1(data)));
    endmethod

    method Tuple2#(Float, Exception) result();
        return tuple2(unpack(mfToWrap.result()), ?);
    endmethod
endmodule

module [Module] mkMonadicDoubleMegafunction
    #(Module#(VerilogMonadicDoubleMegafunction) mkMfToWrap)
    (MonadicDoubleMegafunction);

    let mfToWrap <- mkMfToWrap;

    method Action place(Tuple2#(Double, RoundMode) data);
        mfToWrap.place(pack(tpl_1(data)));
    endmethod

    method Tuple2#(Double, Exception) result();
        return tuple2(unpack(mfToWrap.result()), ?);
    endmethod
endmodule

module [Module] mkDiadicDoubleMegafunction
    #(Module#(VerilogDiadicDoubleMegafunction) mkMfToWrap)
    (DiadicDoubleMegafunction);

    let mfToWrap <- mkMfToWrap;

    method Action place(DiadFPRequest#(Double) data);
        mfToWrap.place(pack(tpl_1(data)), pack(tpl_2(data)));
    endmethod

    method Tuple2#(Double, Exception) result();
        return tuple2(unpack(mfToWrap.result()), ?);
    endmethod
endmodule
