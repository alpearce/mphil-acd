/*
*
* A specialised ICache for the DMA engine.
*
* It is asymmetric, and designed to use only a single M9K BRAM block for data
* memory, with a further M9K for tags. It is direct mapped for simplicity.

* It accepts only 32 bit (4 byte) aligned reads, but has an effective line
* size of 256 bits (32 bytes). This is because the maximum width supported by
* an M9K block is 32 bits. Consequetly, a fill takes the round trip time +
* 8 cycles to fill in each part of the memory.
*
* A tag is for one of these 256 bit lines. The memory has 32 256 bit lines, so
* requires a 30 bit tag, meaning that we need another M9K block.
*
* I ignore a bunch of properties of the request that I don't expected to see:
* cached vs uncached, linked, conditional etc.
*
* Cache operation is as follows:
* 1) Request comes in. Request to read internal BRAMS is dispatched.
* 2) Tag of request is checked against tag in BRAM...
*       -> Tag matches, data is returned as response.
*       -> Tag fails to match, request is dispatched to main memory for
*          appropriate data.
*            Response comes back from main memory. Correct data response is
*            dispatched. Then the cache is in an invalid state for a particular
*            tag, so operation is halted.
*
* A possible optimisation is to start writing sublines at the address of the
* subline requested, and maintain a tag for each subline, rather than for the
* whole line. NB: It's probably easier to add the ability to forward from the
* memory request.
*
*/

import Assert::*;
import FIFOF::*;
import Vector::*;

import MasterSlave::*;
import MEM::*;
import MemTypes::*;

export DMAICache (..);
export mkDMAICache;

interface DMAICache;
    interface Slave#(CheriMemRequest, CheriMemResponse) slave;
    interface Master#(CheriMemRequest, CheriMemResponse) master;
endinterface

typedef Bit#(5)     ICacheTagIndex;
typedef Bit#(8)     ICacheDataIndex;
typedef struct {
    Bool        valid;
    Bit#(30)    tag;
} Tag deriving (Bits, Eq, FShow);

typedef struct {
    CheriPhyAddr        addr;
    CheriMasterID       masterID;
    TransactionId       transactionID;
    Bool                error;
} ResponseInformation deriving (Bits, Eq, FShow);

typedef enum {
    Initialising,
    ServingRequests,
    WaitingForMemoryResponse,
    WritingSublines
} CacheState deriving (Bits, Eq, FShow);

module mkDMAICache(DMAICache);

    // Is address 32 bit aligned read of 32 bits?
    function Bool isValidRequest(CheriMemRequest req);
        case (req.operation) matches
            tagged Read .read: return (
                pack(req.addr)[1:0] == 0 &&
                read.noOfFlits == 1 &&
                read.bytesPerFlit == BYTE_4
            );
            default: return False;
        endcase
    endfunction

    function ICacheDataIndex dataIndexFromAddress(CheriPhyAddr address);
        return pack(address)[9:2];
    endfunction

    function ICacheTagIndex tagIndexFromAddress(CheriPhyAddr address);
        return pack(address)[9:5];
    endfunction

    function Bit#(30) tagFromAddress(CheriPhyAddr address);
        return pack(address)[39:10];
    endfunction

    function CheriPhyAddr lineAligned(CheriPhyAddr address);
        return unpack(pack(address) & ~'hFF);
    endfunction

    Reg#(CacheState)            cacheState          <- mkReg(Initialising);
    Reg#(ICacheTagIndex)        tagToInvalidate     <- mkReg(0);
    Reg#(UInt#(3))              subLineToWrite      <- mkReg(0);
    // The tags are invalid when a 256 bit line is being written into the data
    // memory. subLineToWrite is the next 32 bit part of a line to be written
    // into memory.

    // This is called responseInformation because it's information needed for
    // the response. It could have been called requestInformation, because it's
    // from the request, but oh well.
    FIFOF#(ResponseInformation) responseInformation  <- mkSizedFIFOF(4);
    // Response data can't get out of order, because we don't serve requests if
    // we miss.
    FIFOF#(Bit#(32))            responseData        <- mkSizedFIFOF(4);

    MEM#(ICacheTagIndex, Tag)       tags            <- mkMEM;
    MEM#(ICacheDataIndex, Bit#(32)) data            <- mkMEM;

    // For interacting with main memory
    FIFOF#(CheriMemRequest)     memRequests         <- mkFIFOF;
    FIFOF#(CheriMemResponse)    memResponses        <- mkFIFOF;

    // We have to be able to "peek" at this.
    CheriMemResponse cacheResponse = MemoryResponse {
        masterID: responseInformation.first().masterID,
        transactionID: responseInformation.first().transactionID,
        error: (responseInformation.first().error ? SlaveError : NoError),
        operation: tagged Read {
            data: Data { data: zeroExtend(responseData.first()) },
            last: True
        }
    };

    // Mark all tags as invalid
    rule initialise (cacheState == Initialising);
        tags.write(tagToInvalidate, Tag { valid: False, tag: ? });
        if (tagToInvalidate == '1) // i.e. the last tag
            cacheState <= ServingRequests;
        tagToInvalidate <= tagToInvalidate + 1;
    endrule

    rule checkTag (cacheState == ServingRequests);
        /*$display("Checking tag.");*/
        let addr = responseInformation.first().addr;
        let myTag <- tags.read.get();
        let reqTag = tagFromAddress(addr);
        let myData <- data.read.get();
        if (myTag.valid && (myTag.tag == reqTag)) begin
            responseData.enq(myData);
        end
        else begin
            cacheState <= WaitingForMemoryResponse;
            tags.write(tagIndexFromAddress(addr), Tag { valid: True, tag: reqTag });
            memRequests.enq(MemoryRequest {
                addr: lineAligned(addr),
                masterID: 0, // TODO: FIX THIS?!
                transactionID: 0,
                operation: tagged Read {
                    uncached: False,
                    linked: False,
                    noOfFlits: 1,
                    bytesPerFlit: BYTE_32
                }
            });
        end
    endrule

    rule outputResponseDataAndStartFillingSublines
            (cacheState == WaitingForMemoryResponse);

        case (memResponses.first().operation) matches
            tagged Read .read: begin
                // TODO: Check endianness...
                Vector#(8, Bit#(32)) lineData = unpack(read.data.data);
                // [4:2] is the address of the 32 bit part within 256 bit line
                let reqAddr = pack(responseInformation.first().addr);
                responseData.enq(lineData[reqAddr[4:2]]);
            end
            default: begin
                dynamicAssert(False, "Unexpected response from memory.");
                responseData.enq(?);
            end
        endcase
        cacheState <= WritingSublines;
    endrule

    rule writeSubline (cacheState == WritingSublines);
        let dataAddress = {
            tagIndexFromAddress(responseInformation.first().addr),
            pack(subLineToWrite)
        };
        case (memResponses.first().operation) matches
            tagged Read .read: begin
                Vector#(8, Bit#(32)) lineData = unpack(read.data.data);
                data.write(dataAddress, lineData[subLineToWrite]);
            end
            default:
                dynamicAssert(False, "Wow, everything is totally broken.");
        endcase

        if (subLineToWrite == 7) begin
            memResponses.deq();
            cacheState <= ServingRequests;
        end

        subLineToWrite <= subLineToWrite + 1;
    endrule

    interface Slave slave;

        interface CheckedPut request;
            //TODO: check this.
            method Bool canPut = responseInformation.notFull;

            method Action put(CheriMemRequest req);
                /*$display("Request to put received.");*/
                if (isValidRequest(req)) begin
                    /*$display("Request valid.");*/
                    tags.read.put(tagIndexFromAddress(req.addr));
                    data.read.put(dataIndexFromAddress(req.addr));
                end
                else
                    $display("REQUEST INVALID!!");
                responseInformation.enq(ResponseInformation {
                    addr: req.addr,
                    masterID: req.masterID,
                    transactionID: req.transactionID,
                    error: !isValidRequest(req)
                });
            endmethod
        endinterface

        interface CheckedGet response;
            method Bool canGet() =
                (responseInformation.notEmpty() && responseData.notEmpty());

            method CheriMemResponse peek() = cacheResponse;

            method ActionValue#(CheriMemResponse) get();
                // This is fine, because dequeue actually happens with next
                // clock edge.
                responseInformation.deq();
                responseData.deq();
                return cacheResponse;
            endmethod
        endinterface

    endinterface

    interface Master master;
        interface CheckedGet request = toCheckedGet(memRequests);
        interface CheckedPut response = toCheckedPut(memResponses);
    endinterface

endmodule
