import CoProFPSynthesisableModules::*;
import CoProFPOpModules::*;

import FloatingPoint::*;
import List::*;
import StmtFSM::*;
import ClientServer::*;
import GetPut::*;

(* synthesize, options="-aggressive-conditions" *)
module [Module] mkDivTests();
    List#(Tuple3#(Float, Float, RoundMode)) tests = 
        cons(tuple3(one(False), zero(False), ?), 
        nil);
    int testCount = fromInteger(length(tests));

    let doubleServer <- mkConcreteDoubleDivServer();
    let singleServer <- mkUseDiadicDoubleForFloat(doubleServer);

    Reg#(int) testIn <- mkRegU;
    Reg#(int) testOut <- mkRegU;
    mkAutoFSM(par
        for (testIn <= 0; testIn < testCount; testIn <= testIn + 1) action
            singleServer.request.put(tests[testIn]);
        endaction

        for (testOut <= 0; testOut < testCount; testOut <= testOut + 1) action
            let res <- singleServer.response.get();
            $display("Result %D: %X", testOut, pack(tpl_1(res)));
        endaction
    endpar);
endmodule
