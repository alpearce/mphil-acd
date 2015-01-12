/*-
 * Copyright (c) 2013-2013 Ben Thorner, Colin Rothwell
 * All rights reserved.
 *
 * This software was developed by Ben Thorner as part of his summer internship
 * and Colin Rothwell as part of his final year undergraduate project.
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
package CoProFPInst;

import CoProFPTypes :: *;
import MIPS :: *;

typeclass TCoProInst#(type custom_schema);
	function custom_schema convert(CoProInst inst);
endtypeclass

instance TCoProInst#(FPRType);
	function FPRType convert(CoProInst inst);
		FPRType result = unpack(0);
		result.fmt = unpack(pack(inst.op));
		result.ft = inst.regNumDest;
		result.fs = inst.regNumA;
		result.fd = inst.regNumB;
		result.func = unpack(pack(inst.imm));
		return result;
	endfunction
endinstance
	
instance TCoProInst#(FPRIType);
	function FPRIType convert(CoProInst inst);
		let result = unpack(0);
		result.sub = unpack(pack(inst.op));
		result.rt = inst.regNumDest;
		result.fs = inst.regNumA;
		return result;
	endfunction
endinstance

instance TCoProInst#(FPBType);
	function FPBType convert(CoProInst inst);
		FPBType result = unpack(0);
		result.cc = inst.regNumDest[4:2];
		result.nd = unpack(inst.regNumDest[1]);
		result.tf = unpack(inst.regNumDest[0]);
		result.offset = { pack(inst.regNumA), pack(inst.regNumB), pack(inst.imm) };
		return result;
	endfunction
endinstance

instance TCoProInst#(FPCType);
	function FPCType convert(CoProInst inst);
		FPCType result = unpack(0);
		result.fmt = unpack(pack(inst.op));
		result.ft = inst.regNumDest;
		result.fs = inst.regNumA;
		result.cc = pack(inst.regNumB)[4:2];
		result.func = unpack(pack(inst.imm));
		return result;
	endfunction
endinstance

instance TCoProInst#(FPRMCType);
	function FPRMCType convert(CoProInst inst);
		FPRMCType result = unpack(0);
		result.fmt = unpack(pack(inst.op));
		result.cc = pack(inst.regNumDest)[4:2];
		result.tf = unpack(pack(inst.regNumDest)[0]);
		result.fs = inst.regNumA;
		result.fd = inst.regNumB;
		return result;
	endfunction
endinstance

instance TCoProInst#(FPMemInstruction);
    function FPMemInstruction convert(CoProInst inst);
        FPMemInstruction result = unpack(0);
        case (inst.mipsOp)
            LWC1, LDC1: begin
                result.op = Load;
                result.loadTarget = inst.regNumDest;
            end
            SWC1, SDC1: begin
                result.op = Store;
                result.storeSource = FT;
                result.storeReg = inst.regNumDest;
            end
            COP3: begin
                CoProFPXOp fpxOp = unpack(pack(inst.imm)); // It just is. Don't argue.
                case (fpxOp)
                    LWXC1, LDXC1: result.op = Load;
                    SWXC1, SDXC1: result.op = Store;
                endcase
                result.loadTarget = inst.regNumB;
                result.storeSource = FS;
                result.storeReg = inst.regNumA;
            end
        endcase
        return result;
    endfunction
endinstance

endpackage
