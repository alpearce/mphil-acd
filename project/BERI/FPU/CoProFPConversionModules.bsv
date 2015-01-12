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

import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import GetPut::*;
import ClientServer::*;
import FloatingPoint::*;
import Vector::*;

module mkFPConversionServer
    #(function FloatingPoint#(e2, m2) doConversion(FloatingPoint#(e, m) in),
      Integer fifoLength)
    (FloatingPointServer#(MonadFPRequest#(FloatingPoint#(e, m)),
                          FloatingPoint#(e2, m2)));
    
    FIFO#(Tuple2#(FloatingPoint#(e, m), RoundMode)) requests <- mkFIFO();
    FIFO#(Tuple2#(FloatingPoint#(e2, m2), Exception)) responses <-
        mkSizedFIFO(fifoLength);

    rule convert;
        let req <- popFIFO(requests);
        responses.enq(tuple2(doConversion(tpl_1(req)), ?));
    endrule

    interface Put request = toPut(requests);
    interface Get response = toGet(responses);
endmodule

typedef struct {
    Bool negative;
    Bit#(size) bits;
} SignAndBits#(numeric type size) deriving(Bits);

// Again only works on normalised singles.
module mkFloatingPointToWordServer
    (Server#(MonadFPRequest#(FloatingPoint#(e, m)), Int#(32)))
    provisos (
        Bits#(FloatingPoint#(e, m), width),
        Add#(e, 1, shamtWidth),
        Add#(_a, 32, width),
        Add#(_b, TAdd#(1, m), width) // from bsc
    );
    
    function floatRequestToSignAndBits(floatReq);

        FloatingPoint#(e, m) float = tpl_1(floatReq);
        RoundMode rm = tpl_2(floatReq);
        Bit#(width) resultTemp = zeroExtend({1'b1, float.sfd});
        // Because of the implicit position of the binary point, this is
        // already right shifted by m.
        Int#(shamtWidth) shiftCorrection = fromInteger(valueOf(m) + bias(float));
        Int#(shamtWidth) shift = unpack(zeroExtend(float.exp)) - shiftCorrection;
        if (shift >= 0)
            resultTemp = resultTemp << shift;
        else begin
            // can lose precision, so I need to round
            let rshift = -shift;
            // to put bit rt[rs - 2] in the top bit, 
            // we left shift by width - 1 - (rs - 2)
            let deciderBits = resultTemp << (fromInteger(valueOf(width) + 1) - rshift);
            Bool decider = (|deciderBits == 1);
            // rshift - 1 must be >= 0
            Bool half = (resultTemp[rshift - 1] == 1);
            // we have shifted away any non-zero bit
            Bool inexact = half || decider;
            resultTemp = resultTemp >> rshift;
            case (rm)
                Rnd_Nearest_Even: 
                    if (half && (resultTemp[0] == 1 || decider))
                        resultTemp = resultTemp + 1;
                Rnd_Minus_Inf:
                    if (float.sign && inexact)
                        resultTemp = resultTemp + 1;
                Rnd_Plus_Inf:
                    if (!float.sign && inexact)
                        resultTemp = resultTemp + 1;
                // Truncate happens naturally!
            endcase
        end
        return SignAndBits { negative: float.sign, bits: resultTemp };
    endfunction

    function Bit#(32) evalSignAndBits(SignAndBits#(width) sab);
        return truncate(sab.negative ? -sab.bits : sab.bits);
    endfunction

    FIFO#(SignAndBits#(width)) results <- mkFIFO();

    interface Put request;
        method Action put(MonadFPRequest#(FloatingPoint#(e, m)) data);
            results.enq(floatRequestToSignAndBits(data));
        endmethod
    endinterface

    interface Get response;
        method ActionValue#(Int#(32)) get();
            let res <- popFIFO(results);
            return unpack(evalSignAndBits(results.first()));
        endmethod
    endinterface

endmodule

module mkWordToFloatServer(Server#(Int#(32), Float));

    function UInt#(5) indexOfTopOne(Bit#(32) word);
        // Reverse so we can find from the most signficant bit
        Vector#(32, Bit#(1)) vector = reverse(unpack(word));
        case (findElem(1'b1, vector)) matches
            // 31 is because we had to reverse
            tagged Valid .pos: return 31 - pos; 
            default: return 0;
        endcase
    endfunction

    function Float wordToFloat(Int#(32) word);
        Bool sign = unpack(pack(word)[31]);
        Bit#(32) usWord = pack(abs(word));
        // Floating point implictly has the first one, so that's where we take the
        // mantissa from. If it's more than 23, and we can't mantain precision,
        // we have to cut off some of the bottom, otherwise we shift upwards.
        let msoIndex = indexOfTopOne(usWord);
        Bit#(23) sfd;
        if (msoIndex > 23)
            sfd = truncate(usWord >> (msoIndex - 23));
        else
            sfd = truncate(usWord << (23 - msoIndex));
        Bit#(8) exp = pack(zeroExtend(msoIndex) + 127); // bias = 127;
        return FloatingPoint { sign: sign, exp: exp, sfd: sfd };
    endfunction

    FIFO#(Float) resultFIFO <- mkFIFO;

    interface Put request;
        method Action put(Int#(32) word);
            resultFIFO.enq(wordToFloat(word));
        endmethod
    endinterface

    interface Get response = toGet(resultFIFO);
endmodule

// Copied from the floating point library: they don't export it for some reason.
function Integer bias(FloatingPoint#(e, m) fp);
    return (2 ** (valueof(e) - 1)) - 1;
endfunction
