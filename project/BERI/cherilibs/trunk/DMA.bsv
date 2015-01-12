
/*

DMA Operation

1) Transfer is initiated.
2) Internal ICache is queried for instruction at program counter.
3) Instruction is loaded
3) Memory request etc. is performed, program counter is updated, and cycle
continues.

*/

import DefaultValue::*;
import FIFO::*;
import FIFOF::*;
import FShow::*;

import MemTypes::*;
import MasterSlave::*;
import Library::*;

typedef enum {
    LoopReg0,
    LoopReg1,
    LoopReg2,
    LoopReg3
} LoopRegName deriving (Bits, Eq, FShow);

typedef UInt#(26) LoopRegValue;

typedef enum {
    Bits8    = 0,
    Bits16   = 1,
    Bits32   = 2,
    Bits64   = 3,
    Bits128  = 4,
    Bits256  = 5,
    Bits512  = 6,
    Bits1024 = 7
} TransferSize deriving (Bits, Eq, FShow);

typedef enum {
    Both,
    SourceOnly,
    DestOnly
} AddTarget deriving (Bits, Eq, FShow);

typedef union tagged {
    struct {
        LoopRegName target;
        LoopRegValue value;
    } SetLoopReg;

    struct {
        LoopRegName loopReg;
        Int#(26) offset;
    } Loop;

    struct {
        TransferSize size;
    } Transfer;

    struct {
        TransferSize size;
        LoopRegName loopReg;
        Int#(23) offset;
    } TransferAndLoop;

    struct {
        AddTarget target;
        Int#(26) amount;
    } Add;

    void Stop;

    void InvalidInstruction;

} DMAInstruction deriving (FShow);

instance Bits#(DMAInstruction, 32);

    function Bit#(32) pack(DMAInstruction ins);
        Bit#(32) ret = 0;
        case (ins) matches
            tagged SetLoopReg .data: begin
                ret[31:28] = 1;
                ret[27:26] = pack(data.target);
                ret[25:0]  = pack(data.value);
            end
            tagged Loop .data: begin
                ret[31:28] = 2;
                ret[27:26] = pack(data.loopReg);
                ret[25:0]  = pack(data.offset);
            end
            tagged Transfer .data: begin
                ret[31:28] = 3;
                ret[27:25] = pack(data.size);
            end
            tagged TransferAndLoop .data: begin
                ret[31:28] = 4;
                ret[27:25] = pack(data.size);
                ret[24:23] = pack(data.loopReg);
                ret[22:0]  = pack(data.offset);
            end
            tagged Add .data: begin
                ret[31:28] = 5;
                ret[27:26] = pack(data.target);
                ret[25:0]  = pack(data.amount);
            end
            tagged Stop: begin
                ret[31:28] = 6;
            end
        endcase
        return ret;
    endfunction

    function DMAInstruction unpack(Bit#(32) rawIns);
        case (rawIns[31:28])
            1: return tagged SetLoopReg {
                target: unpack(rawIns[27:26]),
                value:  unpack(rawIns[25:0])
            };
            2: return tagged Loop {
                loopReg: unpack(rawIns[27:26]),
                offset:  unpack(rawIns[25:0])
            };
            3: return tagged Transfer {
                size: unpack(rawIns[27:25])
            };
            4: return tagged TransferAndLoop {
                size:    unpack(rawIns[27:25]),
                loopReg: unpack(rawIns[24:23]),
                offset:  unpack(rawIns[22:0])
            };
            5: return tagged Add {
                target: unpack(rawIns[27:26]),
                amount: unpack(rawIns[25:0])
            };
            6: return tagged Stop;
            default: return tagged InvalidInstruction;
        endcase
    endfunction

endinstance

typedef enum {
    Read,
    Write,
    StoreConditional
} RequestType deriving (Bits, Eq, FShow);

interface DMADebug;
    method Action   forceEngineReady(Bool value);
    interface Reg#(Maybe#(Bool))    startTransaction;
    interface Reg#(Maybe#(Bool))    enableInterrupt;
    method Bit#(64) readExternalProgramCounter();
    method Bit#(64) readExternalSource();
    method Bit#(64) readExternalDestination();
endinterface

interface DMA;
    interface DMADebug debug;
    interface Slave#(CheriMemRequest, CheriMemResponse) configuration;
    interface Master#(CheriMemRequest, CheriMemResponse) memory;
endinterface

typedef union tagged {
    Bit#(32)    Read;
    void        Write;
} ResponseInformationData deriving (Bits, Eq, FShow);

typedef struct {
    CheriMasterID           masterID;
    TransactionId           transactionID;
    Bool                    error;
    ResponseInformationData data;
} ResponseInformation deriving (Bits, Eq, FShow);

module mkDMA(DMA);

    let addressMask = 'b11111; // 5 bits => 2^5 = 32 bytes => 256 bits

    Reg#(Bool) engineReady <- mkReg(True); // bit 0

    // These are maybes because they are just for debugging. In actual fact,
    // they are more like signals.
    Reg#(Maybe#(Bool)) startTransaction <- mkReg(tagged Invalid);
    Reg#(Maybe#(Bool)) enableInterrupt <- mkReg(tagged Invalid);

    // External means that these were written externally, and should be
    // preserved: They are not modified by the operation of the DMA.
    Reg#(Bit#(64)) externalProgramCounter <- mkRegU;
    Reg#(Bit#(64)) externalSource <- mkRegU;
    Reg#(Bit#(64)) externalDestination <- mkRegU;

    Reg#(Bit#(64)) programCounter <- mkRegU;

    // Length of this limits number of in-flight transactions
    FIFOF#(ResponseInformation) responseInformation <- mkLFIFOF;

    function ResponseInformation responseInformationFromRequest(CheriMemRequest req);
        ResponseInformationData data = (case (req.operation) matches
            tagged Read .*:     tagged Read zeroExtend(pack(engineReady));
            tagged Write .*:    tagged Write;
        endcase);
        return ResponseInformation {
            masterID:       req.masterID,
            transactionID:  req.transactionID,
            error:          False,
            data:           data
        };
    endfunction

    function CheriMemResponse responseFromInformation(ResponseInformation info);
        return MemoryResponse {
            masterID:       info.masterID,
            transactionID:  info.transactionID,
            error:          (info.error ? SlaveError : NoError),
            operation:      (case (info.data) matches
                tagged Read .value: return tagged Read {
                    data: Data { data: zeroExtend(value) },
                    last: True
                };
                tagged Write: return tagged Write;
            endcase)
        };
    endfunction

    interface DMADebug debug;
        method forceEngineReady = engineReady._write;
        method readExternalProgramCounter = externalProgramCounter._read;
        method readExternalSource = externalSource._read;
        method readExternalDestination = externalDestination._read;
        interface startTransaction = startTransaction;
        interface enableInterrupt = enableInterrupt;
    endinterface

    interface Slave configuration;

        interface CheckedPut request;
            method Bool canPut() = True;

            method Action put(CheriMemRequest req);
                Bit#(5) relativeAddress = truncate(pack(req.addr) & addressMask);

                case (req.operation) matches
                    tagged Write .properties: begin
                        let beIs32Bit = (pack(properties.byteEnable)[3:0] == '1);
                        let beIs64Bit = (pack(properties.byteEnable)[7:0] == '1);
                        Bit#(64) writeValue = truncate(properties.data.data);

                        if (relativeAddress == 'h4 && beIs32Bit) begin
                            startTransaction    <= tagged Valid unpack(writeValue[0]);
                            enableInterrupt     <= tagged Valid unpack(writeValue[1]);
                        end
                        else if (relativeAddress == 'h8 && beIs64Bit)
                            externalProgramCounter <= writeValue;
                        else if (relativeAddress == 'h10 && beIs64Bit)
                            externalSource <= writeValue;
                        else if (relativeAddress == 'h16 && beIs64Bit)
                            externalDestination <= writeValue;
                    end
                endcase

                responseInformation.enq(responseInformationFromRequest(req));

            endmethod
        endinterface

        interface CheckedGet response;
            method Bool canGet = responseInformation.notEmpty;

            method CheriMemResponse peek() = defaultValue();

            method ActionValue#(CheriMemResponse) get() if (True);
                let info <- popFIFOF(responseInformation);
                return responseFromInformation(info);
            endmethod
        endinterface

    endinterface

endmodule
