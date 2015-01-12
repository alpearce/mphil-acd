/*-
 * Copyright (c) 2010 Greg Chadwick
 * Copyright (c) 2013 Jonathan Woodruff
 * All rights reserved.
*/

import MIPS :: *;
//import RegFile :: *;
import FIFOF::*;
import BRAMCore3 :: * ;
import ConfigReg :: *;


interface MIPSRegFile;
  method ActionValue#(MIPSReg) getRegA();
  method ActionValue#(MIPSReg) getRegB();
  method Action reqRegA(RegNum rn, ContextNum c);
  method Action reqRegB(RegNum rn, ContextNum c);
  
  method Action writeReg(RegNum rn, ContextNum c, MIPSReg data);
  
  method Action writePC(MIPSReg newPC, ContextNum c);
  method MIPSReg getPC(ContextNum c);
endinterface
(* synthesize *)
module mkRegFile(MIPSRegFile);
  Reg#(MIPSReg) pc[8];
  
  BRAM_TRIPLE_PORT#(Bit#(8), Bit#(64)) regFile <- mkBRAMCore3(256, False);
  
  FIFOF#(Bool)   zeroA <- mkUGFIFOF;
  FIFOF#(Bool)   zeroB <- mkUGFIFOF;

  Integer i;
  for(i = 0;i < 1;i = i + 1) begin // was 8
    pc[i] <- mkConfigReg(64'h9000000040000000 + fromInteger(i) * 4);
  end
    
  method ActionValue#(MIPSReg) getRegA();
    MIPSReg ret = ?;
    if (zeroA.notEmpty) begin
      ret = 0;
      zeroA.deq;
    end else ret = regFile.a.read();
    return ret;
  endmethod
  
  method ActionValue#(MIPSReg) getRegB();
    MIPSReg ret = ?;
    if (zeroB.notEmpty) begin
      ret = 0;
      zeroB.deq;
    end else ret = regFile.b.read();
    return ret;
  endmethod
  
  method Action reqRegA(RegNum rn, ContextNum c);
    regFile.a.put(False, {c, rn}, ?);
    if (rn == 0) zeroA.enq(True);
  endmethod
  
  method Action reqRegB(RegNum rn, ContextNum c);
    regFile.b.put(False, {c, rn}, ?);
    if (rn == 0) zeroB.enq(True);
  endmethod
  
  method Action writeReg(RegNum rn, ContextNum c, MIPSReg data);// if (init == False);
    regFile.write.put(True, {c, rn}, data);
  endmethod

  method Action writePC(MIPSReg nPC, ContextNum c);
    debug($display("Writing new PC: %X for context %d at time: %t", nPC, c, $time()));
    pc[c] <= nPC;
  endmethod
  
  method MIPSReg getPC(ContextNum c);
    return pc[c];
  endmethod
endmodule
