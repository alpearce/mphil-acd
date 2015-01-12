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
import BufferServer::*;
import CoProFPSynthesisableModules::*;

import FIFO::*;
import GetPut::*;
import ClientServer::*;
import FloatingPoint::*;
import Connectable::*;

Integer fifoLength = 2; // Rarely used, and to allow synthesize attribute

//These specific instances are to let us synthesize them, which stops them being
//recompiled. This is good, as they're pretty complicated to build.
(* synthesize,  options = "-aggressive-conditions" *)
module mkRecipFloatServer(MonadicFloatServer);
    let divider <- mkFloatingPointDivider();
    let worker <- mkBufferOutputServer(mkRecipServer(divider), fifoLength);
    return worker;
endmodule

(* synthesize,  options = "-aggressive-conditions" *)
module mkRecipDoubleServer(MonadicDoubleServer);
    `ifdef BLUESIM
        let divider <- mkFloatingPointDivider();
    `else
        let divider <- mkUnbufferedDoubleDivServer();
    `endif
    let worker <- mkBufferOutputServer(mkRecipServer(divider), fifoLength);
    return worker;
endmodule

module mkRecipServer
    #(FloatingPointServer#(DiadFPRequest#(FloatingPoint#(e, m)),
                           FloatingPoint#(e, m)) divServer)
    (FloatingPointServer#(MonadFPRequest#(FloatingPoint#(e, m)),
                          FloatingPoint#(e, m)))
    provisos ( //To keep BSC happy!
        Mul#(2, TAdd#(m, 5), TAdd#(TAdd#(m, 5), TAdd#(m, 5))),
        Add#(a__, TLog#(TAdd#(1, TAdd#(TAdd#(m, 5), 1))), TAdd#(e, 1)),
        Add#(b__, TLog#(TAdd#(1, TAdd#(m, 1))), TAdd#(TAdd#(e, 1), 1))        
    );

    interface Put request;
        method Action put(MonadFPRequest#(FloatingPoint#(e, m)) req);
            let positiveOne = FloatingPoint::one(False);
            divServer.request.put(tuple3(positiveOne, tpl_1(req), tpl_2(req)));
        endmethod
    endinterface

    interface Get response = divServer.response;
endmodule

interface SqrtServers#(type fpType);
    interface FloatingPointServer#(MonadFPRequest#(fpType), fpType) sqrt;
    interface FloatingPointServer#(MonadFPRequest#(fpType), fpType) recipSqrt;
endinterface

(* synthesize,  options = "-aggressive-conditions" *)
module mkSqrtFloatServers(SqrtServers#(Float));
    let sqrtServer <- mkFloatingPointSquareRooter();
    let recipServer <- mkRecipFloatServer();
    let worker <- mkSqrtServers(sqrtServer, recipServer);
    return worker;
endmodule

(* synthesize,  options = "-aggressive-conditions" *)
module mkSqrtDoubleServers(SqrtServers#(Double));
    `ifdef BLUESIM
        let sqrtServer <- mkFloatingPointSquareRooter();
    `else
        let sqrtServer <- mkUnbufferedDoubleSqrtServer();
    `endif
    let recipServer <- mkRecipDoubleServer();
    let worker <- mkSqrtServers(sqrtServer, recipServer);
    return worker;
endmodule

typedef enum {
    SqrtReq,
    RecipSqrtReq
} SqrtRequestType deriving (Bits, Eq);

module mkSqrtServers
    #(FloatingPointServer#(MonadFPRequest#(FloatingPoint#(e, m)),
                           FloatingPoint#(e, m)) sqrtServer,
      FloatingPointServer#(MonadFPRequest#(FloatingPoint#(e, m)),
                           FloatingPoint#(e, m)) recipServer)
    (SqrtServers#(FloatingPoint#(e, m)))
        provisos ( // again (best provisos ever!)...
        Mul#(2, TAdd#(m, 5), TAdd#(TAdd#(m, 5), TAdd#(m, 5))),
        Add#(a__, TLog#(TAdd#(1, TAdd#(TAdd#(m, 5), 1))), TAdd#(e, 1)),
        Add#(b__, TLog#(TAdd#(1, TAdd#(m, 1))), TAdd#(TAdd#(e, 1), 1)),
        Add#(c__, 2, TMul#(TAdd#(TDiv#(m, 2), 3), 2)),
        Log#(TAdd#(1, TMul#(TAdd#(TDiv#(m, 2), 3), 2)),
            TLog#(TAdd#(TMul#(TAdd#(TDiv#(m, 2), 3), 2), 1))),
        Add#(1, d__, TMul#(TAdd#(TDiv#(m, 2), 3), 2)),
        Add#(m, e__, TMul#(TAdd#(TDiv#(m, 2), 3), 2)),
        Add#(f__, TLog#(TAdd#(1, TMul#(TAdd#(TDiv#(m, 2), 3), 2))), TAdd#(e, 1)),
        Add#(g__, TMul#(TAdd#(TDiv#(m, 2), 3), 2), 
            TMul#(2, TMul#(TAdd#(TDiv#(m, 2), 3), 2))),
        Log#(TAdd#(1, TMul#(2, TMul#(TAdd#(TDiv#(m, 2), 3), 2))),
            TLog#(TAdd#(TMul#(2, TMul#(TAdd#(TDiv#(m, 2), 3), 2)), 1))),
        Add#(h__, 2, TMul#(2, TMul#(TAdd#(TDiv#(m, 2), 3), 2))),
        Add#(i__, TAdd#(TMul#(TAdd#(TDiv#(m, 2), 3), 2), 1), 
            TMul#(2, TMul#(TAdd#(TDiv#(m, 2), 3), 2))),
        Add#(m, j__, TAdd#(TMul#(TAdd#(TDiv#(m, 2), 3), 2), 1)),
        Add#(k__, TLog#(TAdd#(1, 
            TAdd#(TMul#(TAdd#(TDiv#(m, 2), 3), 2), 1))), TAdd#(e, 1)),
        Add#(l__, TLog#(TAdd#(TMul#(TAdd#(TDiv#(m, 2), 3), 2), 1)), e),
        Add#(m__, TLog#(TAdd#(TMul#(TAdd#(TDiv#(m, 2), 3), 2), 1)), TAdd#(e, 2))
    );

    FIFO#(RoundMode) roundModes <- mkSizedFIFO(50);
    FIFO#(SqrtRequestType) requestType <- mkSizedFIFO(50);
    FIFO#(Tuple2#(FloatingPoint#(e, m), Exception)) sqrtResults <- mkSizedFIFO(5);
    FIFO#(FloatingPoint#(e, m)) recipFeeder <- mkFIFO();
    FIFO#(Tuple2#(FloatingPoint#(e, m), Exception)) recipSqrtResults <- mkFIFO();

    (* fire_when_enabled *)
    rule handleSqrtedResult;
        let resp <- sqrtServer.response.get();
        let reqType <- popFIFO(requestType);
        case (reqType)
            SqrtReq: sqrtResults.enq(resp);
            RecipSqrtReq: recipFeeder.enq(tpl_1(resp));
        endcase
    endrule

    (* fire_when_enabled *)
    rule feedRecip;
        let toFeed <- popFIFO(recipFeeder);
        let roundMode <- popFIFO(roundModes);
        recipServer.request.put(tuple2(toFeed, roundMode));
    endrule

    mkConnection(recipServer.response, toPut(recipSqrtResults));
    
    interface FloatingPointServer sqrt;
        interface Put request;
            method Action put(MonadFPRequest#(FloatingPoint#(e, m)) req);
                requestType.enq(SqrtReq);
                sqrtServer.request.put(req);
            endmethod
        endinterface

        interface Get response = toGet(sqrtResults);
    endinterface
    
    interface FloatingPointServer recipSqrt;
        interface Put request;
            method Action put(MonadFPRequest#(FloatingPoint#(e, m)) req);
                requestType.enq(RecipSqrtReq);
                sqrtServer.request.put(req);
                roundModes.enq(tpl_2(req));
            endmethod
        endinterface

        interface Get response = toGet(recipSqrtResults);
    endinterface
endmodule
