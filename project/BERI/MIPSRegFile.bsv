/*-
 * Copyright (c) 2010 Gregory A. Chadwick
 * Copyright (c) 2013 Jonathan Woodruff
 * All rights reserved.
*/

import DebugUnit::*;
import MIPS :: *;
import RegFile :: *;
import FIFOF::*;
import FIFO::*;
import SpecialFIFOs::*;
import Vector::*;

typedef struct { 
  Bool    valid;
  MIPSReg register;
} SpecReg deriving (Bits, Eq);

typedef struct {
  Epoch   epoch; 
  Bool    valid;
  RegNum  regNum;
  Bool    pending;
} SpecRegTag deriving (Bits, Eq);

typedef struct {
  Epoch   epoch; 
  RegNum  a;
  RegNum  b;
  Bool    write;
  Bool    pendingWrite;
  RegNum  dest;
  Bool    fromDebug;
  Bool    conditionalUpdate;
} ReadReq deriving (Bits, Eq);

typedef struct {
  Bool aValid;
  RenameReg a;
  Bool aPending;
  Bool bValid;
  RenameReg b;
  Bool bPending;
  Bool conditionalUpdate;
  ReadRegs  regFileVals;
  RegNumAndPending write;
} RegReadReport deriving (Bits, Eq);

typedef struct {
  SpecReg   specReg;
  RenameReg regNum;
} RenameRegWrite deriving (Bits, Eq);

typedef struct {
  Bool      write;
  MIPSReg   data;
  RegNum    regNum;
} RegWrite deriving (Bits, Eq);

typedef struct {
  Bool       write;
  Bool       pending;
  RenameReg  regNum;
  SpecRegTag oldRegTag; // Tag of rename reg that previously held this architectural reg.
  RenameReg  oldRegNum;
} RegNumAndPending deriving (Bits, Eq);

`define ReRegs 8
`define LogReRegs 3

typedef Bit#(`LogReRegs)  RenameReg; // A renamed destination register address, one of 4 in the current design

interface MIPSRegFile;
  method Action reqRegs(RegNum regA, RegNum regB, Bool write, Bool pendingWrite, RegNum dest, Epoch ep, Bool debug, Bool conditionalUpdate);
  // These two methods, getRegs and writeRegSpeculative should be called in the same rule, Execute.
  method ActionValue#(ReadRegs) readRegs(Epoch ep);
  method Action writeRegSpeculative(RegNum regW, MIPSReg data, Bool write, Epoch ep);
  method Action writeReg(RegNum regW, MIPSReg data, Bool write, Bool committing);
endinterface

typedef enum {Init, Serving} RegFileState deriving (Bits, Eq);
//(*synthesize*) 
module mkMIPSRegFile#(DebugIfc dbg) (MIPSRegFile);
  SpecRegTag initialTag = SpecRegTag{valid:False, epoch:?, regNum:?};
  Reg#(Vector#(`ReRegs, SpecRegTag))     rnTags   <- mkReg(replicate(initialTag));
  Reg#(Vector#(`ReRegs, SpecReg))        rnRegs   <- mkReg(?);
  RegFile#(RegNum,    MIPSReg)     regFile  <- mkRegFile(0, 31); // BRAM
  
  FIFOF#(Bool)             limiter      <- mkSizedFIFOF(`ReRegs);
  FIFOF#(ReadReq)          readReq      <- mkFIFOF;
  FIFOF#(RegReadReport)    readReport   <- mkFIFOF;
  FIFOF#(RegNumAndPending) wbReRegWrite <- mkSizedFIFOF(4);
  FIFO#(RegWrite)          writeback    <- mkLFIFO;
  
  FIFOF#(RenameRegWrite)   pendVal      <- mkUGSizedFIFOF(4);
  Reg#(RenameReg)          nextReReg    <- mkReg(0);
  Reg#(RenameReg)          lastReReg    <- mkReg(0);
  
  rule readRegFiles;
    ReadReq rq = readReq.first;
    readReq.deq();
    
    ReadRegs ret = ReadRegs{regA: regFile.sub(rq.a), regB: regFile.sub(rq.b)};
    
    if (rq.fromDebug) begin
      if (rq.a==0) ret.regA = dbg.getOpA();
      if (rq.b==0) ret.regB = dbg.getOpB();
    end else begin
      if (rq.a==0) ret.regA = 0;
      if (rq.b==0) ret.regB = 0;
    end
    
    // Detect any dependencies on renamed registers and setup for forwarding in the readRegs method.
    RegReadReport report = RegReadReport{aValid:False, a:?, aPending: False, 
                                         bValid:False, b:?, bPending: False, conditionalUpdate:rq.conditionalUpdate,
                                         regFileVals:ret};
    for (Integer i=0; i<`ReRegs; i=i+1) begin
      SpecRegTag srt = rnTags[i];
      if (srt.valid && srt.epoch==rq.epoch) begin
        if (rq.a!=0 && srt.regNum==rq.a) begin
          report.aValid = True;
          report.a = fromInteger(i);
          report.aPending = srt.pending;
          debug($display("Reading A from rereg %d", i));
        end
        if (rq.b!=0 && srt.regNum==rq.b) begin
          report.bValid = True;
          report.b = fromInteger(i);
          report.bPending = srt.pending;
          debug($display("Reading B from rereg %d", i));
        end
      end
    end
    SpecRegTag oldRegTag = ?; // Rename register that previously held this architectural register.
    oldRegTag.valid = False;
    RenameReg oldRegNum = ?;
    // Record the write destination of this instruction in the rename tags table.
    Vector#(8, SpecRegTag) newReTags = rnTags;
    if (rq.write) begin
      // Invalidate any old entries
      for (Integer i=0; i<`ReRegs; i=i+1) begin
        if (newReTags[i].valid && newReTags[i].regNum==rq.dest) begin
          if (newReTags[i].epoch==rq.epoch) begin
            // Tag of rename register that previously held this architectural register.
            oldRegTag = newReTags[i]; 
            oldRegNum = fromInteger(i);
            debug($display("Old Register is %d", i));
          end
          newReTags[i].valid = False;
        end
      end
      newReTags[nextReReg] = SpecRegTag{valid: True, regNum: rq.dest, epoch: rq.epoch, pending: rq.pendingWrite};
    end else begin
      newReTags[nextReReg].valid = False;
    end
    report.write = RegNumAndPending{write: rq.write, regNum: nextReReg, pending: rq.pendingWrite,
                                    oldRegTag: oldRegTag, oldRegNum: oldRegNum};
    nextReReg <= nextReReg + 1;
    rnTags <= newReTags;
    readReport.enq(report);
    limiter.enq(True);
  endrule
  
  // Some booleans to help with composing the conditions for the readRegs method.
  // ReadRegs needs to wait until any pending operands that it needs are ready.
  RegReadReport    topRpt = readReport.first;
  RegNumAndPending topWrite = readReport.first.write;
  Bool             pipeEmpty = !wbReRegWrite.notEmpty && !pendVal.notEmpty;
  Bool a_is_pending = topRpt.aValid && 
                      topRpt.aPending && 
                      !rnRegs[topRpt.a].valid && 
                      !pipeEmpty;
  Bool b_is_pending = topRpt.bValid && 
                      topRpt.bPending && 
                      !rnRegs[topRpt.b].valid && 
                      !pipeEmpty;
  Bool old_is_pending = topRpt.conditionalUpdate &&
                        topWrite.oldRegTag.pending && 
                        !rnRegs[topWrite.oldRegNum].valid && 
                        !pipeEmpty;
  Bool a_is_ready = pendVal.notEmpty && 
                    pendVal.first.regNum==topRpt.a;
  Bool b_is_ready = pendVal.notEmpty && 
                    pendVal.first.regNum==topRpt.b;
  Bool old_is_ready = pendVal.notEmpty && 
                      pendVal.first.regNum==topWrite.oldRegNum;
  Bool read_is_ready = (!a_is_pending || a_is_ready) && 
                       (!b_is_pending || b_is_ready) && 
                       (!old_is_pending || old_is_ready);
  
  rule writePending(pendVal.notEmpty);
    Vector#(`ReRegs, SpecReg) newRnRegs = rnRegs;
    newRnRegs[pendVal.first.regNum] = pendVal.first.specReg;
    pendVal.deq();
    rnRegs <= newRnRegs;
    debug($display("wrote pending in dedicated rule"));
  endrule
  
  rule doRegisterWrite;
    RegWrite rw = writeback.first;
    if (rw.write) begin
      regFile.upd(rw.regNum,rw.data);
      debug($display("Wrote register %d", writeback.first.regNum));
    end
    writeback.deq();
    limiter.deq();
  endrule
  
  method Action reqRegs(RegNum regA, RegNum regB, Bool write, Bool pendingWrite, RegNum dest, Epoch ep, Bool debug, Bool conditionalUpdate);
    readReq.enq(ReadReq{a:regA, b:regB, write: write, 
                        pendingWrite: pendingWrite, 
                        dest: dest, epoch:ep, fromDebug: debug,
                        conditionalUpdate: conditionalUpdate});
  endmethod
  
  method ActionValue#(ReadRegs) readRegs(Epoch ep) if (read_is_ready);
    RegReadReport report = readReport.first();
    //readReport.deq();
    ReadRegs ret = report.regFileVals;
    // Return renamed register values if necissary
    if (report.aValid) begin
      if (rnRegs[report.a].valid) ret.regA = rnRegs[report.a].register;
      else if (a_is_ready) ret.regA = pendVal.first.specReg.register;
    end
    if (report.bValid) begin
      if (rnRegs[report.b].valid) ret.regB = rnRegs[report.b].register;
      else if (b_is_ready) ret.regB = pendVal.first.specReg.register;
    end
    return ret;
  endmethod
  
  method Action writeRegSpeculative(RegNum regW, MIPSReg data, Bool write, Epoch ep);
    Vector#(`ReRegs, SpecReg) newRnRegs = rnRegs;
    RegNumAndPending req = readReport.first.write;
    readReport.deq();
    // Roll in pending write
    if (pendVal.notEmpty) begin
      newRnRegs[pendVal.first.regNum] = pendVal.first.specReg;
      debug($display("wrote pending in write speculative"));
      pendVal.deq();
    end
    // Update rename registers with this write value.
    SpecReg regWrite = SpecReg{register: ?, valid: False};
    if (write) regWrite = SpecReg{register: data, valid: !req.pending};
    else if (req.write && req.oldRegTag.valid) begin
      regWrite = newRnRegs[req.oldRegNum];
      debug($display("Copying old register value %x", regWrite.register));
    end
    newRnRegs[req.regNum] = regWrite;
    rnRegs <= newRnRegs;
    lastReReg <= req.regNum;
    wbReRegWrite.enq(req);
  endmethod
  
  method Action writeReg(RegNum regW, MIPSReg data, Bool write, Bool committing) if (pendVal.notFull);
    Bool doWrite = (write && committing && regW!=0);
    // Do the BRAM write in the next cycle for frequency.
    writeback.enq(RegWrite{write: doWrite, data: data, regNum: regW});
    if (wbReRegWrite.first.pending && doWrite) 
            pendVal.enq(RenameRegWrite{specReg: SpecReg{valid: True, register: data},
                                       regNum: wbReRegWrite.first.regNum});
    wbReRegWrite.deq();
  endmethod
endmodule


