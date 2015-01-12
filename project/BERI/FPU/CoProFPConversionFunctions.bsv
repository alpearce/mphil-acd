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
import FloatingPoint::*;

// Zero extend a quantity by padding on the LSB side.
function Bit#(m) zeroExtendLSB(Bit#(n) value)
    provisos(Add#(a__, n, m));

    Bit#(m) resp = 0;
    resp[valueOf(m)-1:valueOf(m)-valueOf(n)] = value;
    return resp;
endfunction

function Bit#(m) truncateLSB(Bit#(n) value);
    return value[valueOf(n)-1:valueOf(n)-valueOf(m)];
endfunction

function Double floatToDouble(Float in);
    if (isZero(in))
        return zero(in.sign);
    else if (isNaN(in)) 
        return qnan();
    else if (isInfinity(in))
        return infinity(in.sign);
    else begin
        let resp = Double { sign: in.sign, exp: ?, sfd: zeroExtendLSB(in.sfd)};
        resp.exp = zeroExtend(in.exp) + 896; // undo biasing
        return resp;
    end
endfunction

function Float doubleToFloat(Double in);
    if (isZero(in))
        return zero(in.sign);
    else if (isNaN(in)) 
        return qnan();
    else if (isInfinity(in))
        return infinity(in.sign);
    else begin
        Float resp = Float { sign: in.sign, exp: ?, sfd: ? };
        resp.sfd = truncateLSB(in.sfd);
        resp.exp = truncate(in.exp - 896);
        // Round up if more than half way between, or half way between, and
        // significand is odd
        if (in.sfd[22] == 1 && (|in.sfd[21:0] != 0 || in.sfd[23] == 1))
            resp = unpack((pack(resp) + 1)[31:0]);
        return resp;
    end
endfunction

