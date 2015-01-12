import CoProFPConversionModules::*;
import PopFIFO::*;

import StmtFSM::*;
import FloatingPoint::*;
import FIFO::*;
import List::*;
import GetPut::*;
import ClientServer::*;

(* synthesize *)
module mkConversionTests();
    let dut <- mkWordToFloatServer();
    FIFO#(Float) enteredTests <- mkFIFO();

    let tests = cons(33558633, 
                cons(-23, nil));
    int testCount = fromInteger(length(tests));
    
    Reg#(int) count <- mkReg(0);
    mkAutoFSM(seq
        for (count <= 0; count < testCount; count <= count + 1) seq
            action
                enteredTests.enq(tests[count]);
                dut.request.put(tests[count]);
            endaction
        endseq
    endseq);

    rule outputResults;
        let test <- popFIFO(enteredTests);
        let res <- dut.response.get();
        $display("Converted %d to %x", test, res);
    endrule
endmodule
