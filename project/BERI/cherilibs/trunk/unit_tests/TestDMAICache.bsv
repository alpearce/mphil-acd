import DefaultValue::*;
import UnitTesting::*;
import Variadic::*;
import StmtFSM::*;

import MasterSlave::*;
import MemTypes::*;
import DMAICache::*;

function CheriMemRequest read32Bits(Bit#(40) addr);
    return MemoryRequest {
        addr:           unpack(addr),
        masterID:       0,
        transactionID:  0,
        operation:      tagged Read {
            uncached:       False,
            linked:         False,
            noOfFlits:      1,
            bytesPerFlit:   BYTE_4
        }
    };
endfunction

function CheriMemResponse memoryResponse(Bit#(256) data);
    CheriMemResponse resp = defaultValue();
    resp.operation = tagged Read {
        data: Data { data: data },
        last: True
    };
    return resp;
endfunction

function Action avToRegister(Reg#(t) theReg, ActionValue#(t) get) = action
    let value <- get();
    theReg <= value;
endaction;

function Action dropActionValue(ActionValue#(t) av) = action
    let _ <- av;
endaction;

function ActionValue#(Maybe#(Bit#(32))) getResponseData(DMAICache cache) =
    actionvalue
        let respFromCache <- cache.slave.response.get();
        case (respFromCache.operation) matches
            tagged Read .read: begin
                return tagged Valid truncate(read.data.data);
            end
            default:
                return tagged Invalid;
        endcase
    endactionvalue;

module mkTestBasic(Test);
    let dut <- mkDMAICache;
    Reg#(Maybe#(Bit#(32))) dataFromCache <- mkReg(tagged Invalid);
    Reg#(CheriMemRequest) reqFromCache <- mkRegU;

    method String testName = "Test simple DMA ICache functionality";

    method Stmt runTest = seq
        dut.slave.request.put(read32Bits(0));
        avToRegister(reqFromCache, dut.master.request.get);
        testAssertEqual(0, pack(reqFromCache.addr));
        dut.master.response.put(memoryResponse('h1234BEAD));
        avToRegister(dataFromCache, getResponseData(dut));
        testAssertEqual(tagged Valid 'h1234BEAD, dataFromCache);
    endseq;

endmodule

module mkTestTwoWordsFromSameLine(Test);
    let dut <- mkDMAICache;
    Reg#(Maybe#(Bit#(32))) dataFromCache <- mkReg(tagged Invalid);

    Bit#(256) line = (('hBEDEDEAD) << 7 * 32) | ('h12344321);

    method String testName = "Test cache is using same line";

    method Stmt runTest = seq
        dut.slave.request.put(read32Bits(0));
        dropActionValue(dut.master.request.get);
        dut.master.response.put(memoryResponse(line));
        avToRegister(dataFromCache, getResponseData(dut));
        testAssertEqual(tagged Valid 'h12344321, dataFromCache);
        dut.slave.request.put(read32Bits(7 * 4));
        // Shouldn't need a memory request this time.
        avToRegister(dataFromCache, getResponseData(dut));
        testAssertEqual(tagged Valid 'hBEDEDEAD, dataFromCache);
    endseq;

endmodule

module mkTestCorrectLineRequested(Test);
    // This also tests my "bypass" functionality that forwards the correct part
    // of memory response before filling in the BRAM.
    let dut <- mkDMAICache;
    Reg#(Maybe#(Bit#(32))) dataFromCache <- mkRegU;

    Bit#(256) line = 'hDEADDEED << (3 * 32);

    method String testName = "Test cache requests correct line from subline";

    method Stmt runTest = seq
        dut.slave.request.put(read32Bits(3 * 4));
        dropActionValue(dut.master.request.get);
        dut.master.response.put(memoryResponse(line));
        avToRegister(dataFromCache, getResponseData(dut));
        testAssertEqual(tagged Valid 'hDEADDEED, dataFromCache);
    endseq;


endmodule

module mkTestLineEvictedCorrectly(Test);
    // This relies on the cache being direct mapped and having 256 entries.
    let dut <- mkDMAICache;
    Reg#(Maybe#(Bit#(32))) dataFromCache <- mkRegU;

    method String testName = "Test cache evicts as expected.";

    method Stmt runTest = seq
        dut.slave.request.put(read32Bits(0));
        dropActionValue(dut.master.request.get);
        dut.master.response.put(memoryResponse(1));
        avToRegister(dataFromCache, getResponseData(dut));
        testAssertEqual(tagged Valid 1, dataFromCache);
        dut.slave.request.put(read32Bits(256 * 4));
        dropActionValue(dut.master.request.get);
        dut.master.response.put(memoryResponse(2));
        avToRegister(dataFromCache, getResponseData(dut));
        testAssertEqual(tagged Valid 2, dataFromCache);
    endseq;

endmodule

module mkTestNothingIncorrectServedWhilstFilling(Test);
    let dut <- mkDMAICache;
    Reg#(Maybe#(Bit#(32))) dataFromCache <- mkRegU;

    method String testName = "Test doesn't serve old data during eviction.";

    method Stmt runTest = seq
        dut.slave.request.put(read32Bits(0));
        dropActionValue(dut.master.request.get);
        dut.master.response.put(memoryResponse('1));
        avToRegister(dataFromCache, getResponseData(dut));
        testAssertEqual(tagged Valid '1, dataFromCache);

        dut.slave.request.put(read32Bits(4));
        avToRegister(dataFromCache, getResponseData(dut));
        testAssertEqual(tagged Valid '1, dataFromCache);

        dut.slave.request.put(read32Bits(256 * 4));
        dut.slave.request.put(read32Bits(257 * 4));
        dropActionValue(dut.master.request.get);
        dut.master.response.put(memoryResponse(0));
        dropActionValue(getResponseData(dut));
        avToRegister(dataFromCache, getResponseData(dut));
        testAssertEqual(tagged Valid 0, dataFromCache);
    endseq;

endmodule

module mkTestDMAICache(Empty);
    Test basic <- mkTestBasic;
    Test twoWords <- mkTestTwoWordsFromSameLine;
    Test correctLine <- mkTestCorrectLineRequested;
    Test evict <- mkTestLineEvictedCorrectly;
    Test fill <- mkTestNothingIncorrectServedWhilstFilling;

    runTests(list(
        basic,
        twoWords,
        correctLine,
        evict,
        fill
    ));

endmodule
