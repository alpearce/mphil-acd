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
import Vector::*;

interface ShiftRegister#(numeric type length, type td);
    method Action setHead(td head);
    method td getTail();
endinterface

module mkDefaultShiftRegister#(parameter td def)(ShiftRegister#(length, td))
    provisos(Bits#(td, _));

    Wire#(td) headValue <- mkDWire(def);
    Vector#(length, Reg#(td)) registers <- replicateM(mkReg(def));

    rule placeHead;
        registers[0] <= headValue;
    endrule

    (* fire_when_enabled, no_implicit_conditions *)
    rule advanceRegister;
        for (Integer k = 0; k < valueOf(length) - 1; k = k + 1) begin
            registers[k + 1] <= registers[k];
        end
    endrule

    method Action setHead(td head);
        headValue <= head;
    endmethod

    method td getTail();
        return registers[valueOf(length) - 1];
    endmethod
endmodule

module mkShiftRegister(ShiftRegister#(length, td))
    provisos(Bits#(td, _));

    ShiftRegister#(length, td) sr <- mkDefaultShiftRegister(unpack(0));
    method setHead = sr.setHead;
    method getTail = sr.getTail;
endmodule
