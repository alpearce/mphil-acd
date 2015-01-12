/*-
* Copyright (c) 2014 Colin Rothwell
* All rights reserved.
*
* This software was developed by SRI International and the University of
* Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-10-C-0237
* ("CTSRD"), as part of the DARPA CRASH research programme.
*
* This software was developed by SRI International and the University of
* Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249
* ("MRC2"), as part of the DARPA MRC research programme.
*
* @BERI_LICENSE_HEADER_START@
*
* Licensed to BERI Open Systems C.I.C. (BERI) under one or more contributor
* license agreements.  See the NOTICE file distributed with this work for
* additional information regarding copyright ownership.  BERI licenses this
* file to you under the BERI Hardware-Software License, Version 1.0 (the
* "License"); you may not use this file except in compliance with the
* License.  You may obtain a copy of the License at:
*
*   http://www.beri-open-systems.org/legal/license-1-0.txt
*
* Unless required by applicable law or agreed to in writing, Work distributed
* under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
* CONDITIONS OF ANY KIND, either express or implied.  See the License for the
* specific language governing permissions and limitations under the License.
*
* @BERI_LICENSE_HEADER_END@
*
*/

import UnitTesting::*;
import Variadic::*;
import Randomizable::*;
import StmtFSM::*;

import MasterSlave::*;
import MemTypes::*;
import DMA::*;

// We don't care about preserving padding or invalid instruction accross
// conversion
function Bool functionallyEquivalent(Bit#(32) in, Bit#(32) out);
    let opCode = in[31:28];
    if ((opCode == 0 || opCode > 6) &&& unpack(out) matches InvalidInstruction)
        return True; // Invalid Op Code
    else if (opCode == 3) // transfer
        return in[31:25] == out[31:25];
    else if (opCode == 6) // stop
        return in[31:28] == out[31:28];
    else
        return in == out;
endfunction

module mkFuzzInstructionConversion(Test);
    Randomize#(Bit#(32)) randomizer <- mkGenericRandomizer();
    Reg#(Bit#(32)) rawIns <- mkRegU;
    Reg#(DMAInstruction) ins <- mkRegU;
    Reg#(UInt#(32)) failCount <- mkReg(0);
    Reg#(UInt#(33)) count <- mkRegU;

    method String testName = "Test Fuzzing DMA Instruction encode/decode";

    method Stmt runTest = seq
        randomizer.cntrl.init();
        for (count <= 0; count < 1_000_000; count <= count + 1) seq
            action
                let val <- randomizer.next();
                rawIns <= val;
                ins <= unpack(val);
            endaction
            if (!functionallyEquivalent(rawIns, pack(ins))) action
                /*$display("%h %h", rawIns, pack(ins));*/
                /*$display(fshow(ins));*/
                failCount <= failCount + 1;
            endaction
        endseq
        testAssert(failCount == 0);
    endseq;

endmodule


function CheriMemRequest simpleWrite64(Bit#(40) addr, Bit#(256) data);
    return MemoryRequest {
        addr:          unpack(addr),
        masterID:      0,
        transactionID: 0,
        operation: tagged Write {
            uncached:    True,
            conditional: False,
            byteEnable:  unpack('h0000_0000_0000_00FF),
            data:        Data { data: data },
            last:        True
        }
    };
endfunction

module mkTestRegistersSetCorrectly(Test);
    let dut <- mkDMA();
    Reg#(Error) lastError <- mkRegU;

    method String testName = "Test DMA Register Values are set correctly";

    method runTest = seq
        dut.configuration.request.put(
            simpleWrite64('h8, 'h0123_4567_89AB_CDEF));
        action
            let resp <- dut.configuration.response.get();
            lastError <= resp.error;
        endaction
        testAssertEqual(NoError, lastError);
        testAssertEqual(
            'h0123_4567_89AB_CDEF, dut.debug.readExternalProgramCounter());

        dut.configuration.request.put(
            simpleWrite64('h10, 'hFEDC_BA98_7654_3210));
        action
            let resp <- dut.configuration.response.get();
            lastError <= resp.error;
        endaction
        testAssertEqual(NoError, lastError);
        testAssertEqual(
            'hFEDC_BA98_7654_3210, dut.debug.readExternalSource());

        dut.configuration.request.put(
            simpleWrite64('h16, 'h1234_FEDC_5678_BA98));
        action
            let resp <- dut.configuration.response.get();
            lastError <= resp.error;
        endaction
        testAssertEqual(NoError, lastError);
        testAssertEqual(
            'h1234_FEDC_5678_BA98, dut.debug.readExternalDestination());
    endseq;

endmodule

module mkTestSignalsSetCorrectly(Test);
    let dut <- mkDMA();

    function CheriMemRequest configWrite(Bit#(32) data);
        return MemoryRequest {
            addr:           unpack('h4),
            masterID:       0,
            transactionID:  0,
            operation:      tagged Write {
                uncached:       True,
                conditional:    False,
                byteEnable:     unpack('hF),
                data:           Data { data: zeroExtend(data) }
            }
        };
    endfunction

    function Action resetSignals() = action
        dut.debug.startTransaction <= tagged Invalid;
        dut.debug.enableInterrupt <= tagged Invalid;
    endaction;

    function Action dropResponse() = action
        let _ <- dut.configuration.response.get();
    endaction;


    method String testName =
        "Test start and enable irq signals are set correctly";

    method runTest = seq
        testAssertEqual(tagged Invalid, dut.debug.startTransaction._read());
        testAssertEqual(tagged Invalid, dut.debug.enableInterrupt._read());

        dut.configuration.request.put(configWrite('h3));
        dropResponse();
        testAssertEqual(tagged Valid True, dut.debug.startTransaction._read());
        testAssertEqual(tagged Valid True, dut.debug.enableInterrupt._read());

        resetSignals();
        dut.configuration.request.put(configWrite('h1));
        dropResponse();
        testAssertEqual(tagged Valid True, dut.debug.startTransaction._read());
        testAssertEqual(tagged Valid False, dut.debug.enableInterrupt._read());

        resetSignals();
        dut.configuration.request.put(configWrite('h2));
        dropResponse();
        testAssertEqual(tagged Valid False, dut.debug.startTransaction._read());
        testAssertEqual(tagged Valid True, dut.debug.enableInterrupt._read());
    endseq;

endmodule

module mkTestEngineMasksAddressesCorrectly(Test);
    let dut <- mkDMA();

    function Action dropResp() = action
        let _ <- dut.configuration.response.get();
    endaction;

    method String testName =
        "Test that the engine only pays attention to the low bits of request address";

    method runTest = seq
        dut.configuration.request.put(
            simpleWrite64('h8, 'hBEDE_BEDE_BEDE_BEDE));
        dropResp();
        testAssertEqual(
            'hBEDE_BEDE_BEDE_BEDE, dut.debug.readExternalProgramCounter());

        dut.configuration.request.put(
            simpleWrite64('h28, 'hDEAD_DEAD_DEAD_DEAD));
        dropResp();
        testAssertEqual(
            'hDEAD_DEAD_DEAD_DEAD, dut.debug.readExternalProgramCounter());

        dut.configuration.request.put(
            simpleWrite64('h100008, 'hDEFA_CED1_DEFA_CED2));
        dropResp();
        testAssertEqual(
            'hDEFACED1DEFACED2, dut.debug.readExternalProgramCounter());
    endseq;

endmodule

typedef enum {
    TTRead, TTWrite, TTInvalid
} TransactionType deriving (Bits, Eq, FShow);

module mkTestRequestValuesAreMirroredCorrectly(Test);
    let dut <- mkDMA();

    Reg#(TransactionId) lastTransactionID   <- mkRegU;
    Reg#(UInt#(1))      lastMasterID        <- mkRegU;
    Reg#(TransactionType)   lastTransactionType <- mkRegU;

    function TransactionType typeOfResp(CheriMemResponse resp);
        case (resp.operation) matches
            tagged Read .*: return TTRead;
            tagged Write:   return TTWrite;
            default:        return TTInvalid;
        endcase
    endfunction

    method String testName =
        "Test DMA produces responses with correct form";

    method runTest = seq
        dut.configuration.request.put(MemoryRequest {
            addr:          unpack('h8),
            masterID:      'h1,
            transactionID: 'h4,
            operation:     tagged Write {
                uncached:       True,
                conditional:    False,
                byteEnable:     unpack('hFF),
                data:           Data { data: 0 },
                last:           True
            }
        });
        action
            let resp <- dut.configuration.response.get();
            lastMasterID        <= resp.masterID;
            lastTransactionID   <= resp.transactionID;
            lastTransactionType <= typeOfResp(resp);
        endaction
        testAssertEqual(1, lastMasterID);
        testAssertEqual(4, lastTransactionID);
        testAssertEqual(TTWrite, lastTransactionType);

        dut.configuration.request.put(MemoryRequest {
            addr:           unpack('h0),
            masterID:       'h0,
            transactionID:  'h7,
            operation:      tagged Read {
                uncached:       True,
                linked:         False,
                noOfFlits:      1,
                bytesPerFlit:   BYTE_32
            }
        });
        action
            let resp <- dut.configuration.response.get();
            lastMasterID        <= resp.masterID;
            lastTransactionID   <= resp.transactionID;
            lastTransactionType <= typeOfResp(resp);
        endaction
        testAssertEqual(0, lastMasterID);
        testAssertEqual(7, lastTransactionID);
        testAssertEqual(TTRead, lastTransactionType);

    endseq;

endmodule

module mkTestCanReadEngineReady(Test);
    let dut <- mkDMA();

    Reg#(Bool) invalidResponse <- mkReg(False);
    Reg#(Bool) engineReady <- mkRegU;

    let readEngineReadyReq = MemoryRequest {
        addr:           unpack(0),
        masterID:       0,
        transactionID:  0,
        operation: tagged Read {
            uncached:       True,
            linked:         False,
            noOfFlits:      1,
            bytesPerFlit:   BYTE_32
        }
    };

    function Action getResponse() = action
        let resp <- dut.configuration.response.get();
        case (resp.operation) matches
            tagged Read .data:
                engineReady <= unpack(truncate(data.data.data));
            default:
                invalidResponse <= True;
        endcase
    endaction;


    method String testName = "Test that the engine ready bit can be read";

    method runTest = seq
        dut.configuration.request.put(readEngineReadyReq);
        getResponse();
        testAssert(!invalidResponse);
        testAssertEqual(engineReady, True);

        dut.debug.forceEngineReady(False);
        dut.configuration.request.put(readEngineReadyReq);
        getResponse();
        testAssert(!invalidResponse);
        testAssertEqual(engineReady, False);

        dut.debug.forceEngineReady(True);
        dut.configuration.request.put(readEngineReadyReq);
        getResponse();
        testAssert(!invalidResponse);
        testAssertEqual(engineReady, True);
    endseq;

endmodule


module mkTestErrorOnBadRequest(Test);

    method String testName =
        "Test DMA produces errors in response to silly requests";

    method runTest = seq
        //TODO: Test goes here.
    endseq;

endmodule


module mkTestDMA(Empty);
    Test fuzzInstructionConversion <- mkFuzzInstructionConversion();
    Test registersSetCorrectly <- mkTestRegistersSetCorrectly();
    Test testMirroring <- mkTestRequestValuesAreMirroredCorrectly();
    Test testEngineReady <- mkTestCanReadEngineReady();
    Test testMask <- mkTestEngineMasksAddressesCorrectly();
    Test testSignals <- mkTestSignalsSetCorrectly();

    runTests(list(
        fuzzInstructionConversion,
        registersSetCorrectly,
        testMirroring,
        testEngineReady,
        testMask,
        testSignals
    ));
endmodule
