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
import CoProFPTypes :: *;
import MIPS :: *;

interface CoProFPControlRegFile;
    method Action upd(RegNum addr, MIPSReg d);
    method MIPSReg sub(RegNum addr);
endinterface

module mkCoProFPControlRegFile(CoProFPControlRegFile);
    Reg#(FCSR) fcsr <- mkReg(unpack(0));

    FIR fir = FIR { f64: True, 
                    l: False, w: False,
                    threeD: False,
                    ps: True, d: True, s: True,
                    pid: 0, rev: 0 };

    method Action upd(RegNum addr, MIPSReg d);
        let fcsr_tmp = fcsr;
	    case (addr)
		    25:	begin
                fcsr_tmp.fcc = unpack(d[7:0]);
            end
		    26:	begin
                fcsr_tmp.cause = unpack(d[17:12]);
                fcsr_tmp.flags = unpack(d[6:2]);
            end
		    28: begin
                fcsr_tmp.enables = unpack(d[11:7]);
                fcsr_tmp.flushToZero = unpack(d[2]);
                fcsr_tmp.roundingMode = unpack(d[1:0]);
            end
            31: fcsr_tmp = unpack(d);
        endcase
	    fcsr <= fcsr_tmp;
	endmethod
    
    method MIPSReg sub(RegNum addr);
	    case (addr)
                0: return pack(fir);
                25: return {
                    32'b0, 24'b0, 
                    pack(fcsr.fcc)
                };
                26: return {
                    32'b0, 14'b0, 
                    pack(fcsr.cause), 
                    5'b0, 
                    pack(fcsr.flags),
                    2'b0
                };
                28: return {
                    32'b0, 20'b0, 
                    pack(fcsr.enables),
                    4'b0,
                    pack(fcsr.flushToZero),
                    pack(fcsr.roundingMode)
                };
                31: return pack(fcsr);
	    endcase
	endmethod
endmodule
