
import GetPut::*;
import FIFO::*;
import SpecialFIFOs::*;
import Vector::*;
import FShow::*;
import TraceTypes::*;
import ConfigReg::*;
import MEM::*;

typedef enum { Predict,
             Done
} PredictorState deriving (Bits, Eq, FShow);

typedef struct {
  Bit#(64) data; //TODO change based on what I end up storing here
  Bit#(64) delta; 
  Bit#(64) delta2; 
} St2dEntry deriving (Bits, Eq, FShow);

typedef struct {
  Int#(8) predictor;
  Bit#(256) data;
} Prediction deriving(Bits, Eq, FShow);

// the highly predictable trace data
typedef struct {
  Bool        valid; // 1 ; always true
  Bit#(4)   version; // 4 ; do i need to maintain original version? 
  Bit#(5)        ex; // 5
  Bit#(8)      asid; // 8
  Bool       branch; // 1
  Bit#(3)  reserved; // 3
  Bit#(32)     inst; // 32
  Bit#(64)       pc; // 64
} Trace deriving (Bits, Eq, FShow);  //118 bits

//TODO investigate whether predicting regs together or separate works better
typedef struct {
  Bool          valid;
  Bit#(4)     version;
  Bit#(3)     pc_pred;
  Bit#(3)   easy_pred; // if easy is wrong, just send the regular trace bc not enough version bits
  Bit#(1)  count_pred; // should just about always be right with st2d
  Bit#(3)     r1_pred; // for now just using four predictors
  Bit#(3)     r2_pred; // for now just using four predictors
  Bit#(64)      data1; // for pc or regs as needed
  Bit#(64)      data2; 
  Bit#(64)      data3;  
	Bit#(46)	  padding;
} CompressedTraceEntry deriving (Bits, Eq, FShow); // total = 210 (worst case) truncate to 18 (best case)

//THEN figure out how to make two bytes of the necessary data go away (probs ditch a predictor)


//typedef 17 PFCMSIZEBLG2;   /* must be at least 16, or change inlined hash function */
//typedef 65536 VDIM;  /* must be a power of two */
//typedef 19 VFCMSIZEBLG2;
//typedef 17 VDFCMSIZEBLG2; 
typedef 5 PUSEDSIZE;
typedef 11 VUSEDSIZE; //TODO change to smaller number later if we don't use more predictors
//typedef 262144 PFCMB0SIZE;  //(1<<pfcmsizeblg2)*2 = 2^18
//typedef 1048576 PFCMB2SIZE; // (1<<(pfcmsizeblg2+2))*2 = 2^20
//typedef 262144 VDFCMB0SIZE; // (1<<vdfcmsizeblg2)*2 = 2^18
//typedef 1048576 VDFCMB2SIZE; // (1<<(vdfcmsizeblg2+2))*2 = 2^20
//typedef 1048576 VFCMBSIZE; // (1<<vfcmsizeblg2)*2 = 2^20

// original code used 32'res, 64'x... this might not be rightfunction Integer hashVal
function Int#(32) hashVal(Trace x, Int#(32) n);
	Int#(32) res = 0;
	Bit#(118) xb = pack(x);
  while (xb > 0) begin
    res = res ^ unpack(truncate(xb));
    xb = xb >> n; 
  end
  return (res & ((1<<n)-1));
endfunction

function St2dEntry updateSt2d (St2dEntry oldEntry, Bit#(64) newData);
  St2dEntry newEntry;
  Bit#(64) newDelta = newData - oldEntry.data;
  Bit#(64) new2delta = (oldEntry.delta == newDelta) ? newDelta : oldEntry.delta2; 
  newEntry = St2dEntry{data: newData, delta: newDelta, delta2: new2delta};
  return newEntry;
endfunction

interface TracePredictor;
  method Action predictUpdate(Bit#(64) pc, TraceEntry trace); 
  method ActionValue#(Prediction) getPcPrediction();
  method ActionValue#(Prediction) getTracePrediction();
  method ActionValue#(Prediction) getR1Prediction();
  method ActionValue#(Prediction) getR2Prediction();
  method ActionValue#(Prediction) getCountPrediction();
//  method (Bit#(10)) getCount();
  method (TraceEntry) getOriginalTrace();
endinterface

/* Module for predicting the next PC and the next trace entry */ 
module mkTracePredictor(TracePredictor);

  // TODO - decide if mems should be keyed with int64s because pc size is int64
    // generally re-think all of the indexing

	Reg#(Int#(32)) pfcma0 <- mkReg(0);
  Reg#(Int#(32)) pfcma1 <- mkReg(0);
  Reg#(Int#(32)) pfcma2 <- mkReg(0);
	Vector#(PUSEDSIZE,Reg#(Int#(64))) pused <- replicateM(mkReg(0));
  MEM#(Bit#(32),Tuple2#(Bit#(64),Bit#(64))) pfcmb0 <- mkMEM(); // Original code initialized to i&1. Probably doesn't matter.
  MEM#(Bit#(32),Tuple2#(Bit#(64),Bit#(64))) pfcmb2 <- mkMEM(); 
  Vector#(VUSEDSIZE,Reg#(Int#(64))) vused <- replicateM(mkReg(0)); 
  Vector#(VUSEDSIZE,Reg#(Int#(64))) vusedr1 <- replicateM(mkReg(0)); 
  Vector#(VUSEDSIZE,Reg#(Int#(64))) vusedr2 <- replicateM(mkReg(0)); 
  Vector#(3,Reg#(Int#(64))) vused_count <- replicateM(mkReg(0)); 
  //MEM#(Bit#(16),Int#(32)) vfcma <- mkMEM(); // size = VDIM
  //MEM#(Bit#(20),Trace) vfcmb <- mkMEM(); // (1<<vfcmbsizeblg2) * 2
  //MEM#(Bit#(18),Trace) vdfcmb0 <- mkMEM(); // (1<<vdfcmbsizeblg2) * 2
  //MEM#(Bit#(20),Trace) vdfcbm2 <- mkMEM();
  //MEM#(Bit#(16),Vector#(3,Bit#(32))) vdfcma <- mkMEM();
  MEM#(Bit#(16),Vector#(4,Trace)) vlnv <- mkMEM(); //TODO experiment with size of key to see if that makes a difference
  MEM#(Bit#(16),Vector#(4,Bit#(64))) vlnv_reg1 <- mkMEM();
  MEM#(Bit#(16),Vector#(4,Bit#(64))) vlnv_reg2 <- mkMEM();
  MEM#(Bit#(16),St2dEntry) st2d_reg1 <- mkMEM();
  MEM#(Bit#(16),St2dEntry) st2d_reg2 <- mkMEM();
  MEM#(Bit#(16),St2dEntry) st2d_count <- mkMEM();
	//Reg#(St2dEntry) st2d_count <- mkRegU;
  
  Reg#(Bit#(64)) pc_reg <- mkReg(0);
  Reg#(Trace) trace_reg <- mkRegU;
  Reg#(Bit#(64)) r1data <- mkReg(0);
  Reg#(Bit#(64)) r2data <- mkReg(0);
  Reg#(Bit#(64)) count_reg <- mkReg(0); // easier to play nicely wiht other modules if we extend to 64 bits
  Reg#(TraceEntry) original_trace <- mkRegU; 

  Reg#(PredictorState) pstate <- mkConfigReg(Done); //pc predictor state
  Reg#(PredictorState) vstate <- mkConfigReg(Done); //trace predictor state

  FIFO#(Prediction) ppredictions <- mkFIFO1; 
  FIFO#(Prediction) vpredictions <- mkFIFO1; 
  FIFO#(Prediction) r1predictions <- mkFIFO1; 
  FIFO#(Prediction) r2predictions <- mkFIFO1; 
  FIFO#(Prediction) countpredictions <- mkFIFO1; 

	Int#(32) pfcmsizeblg2 = 17; 


	rule predictPC(pstate==Predict); 
    Int#(64) hicnt = -1; // use predictor with highest use count if multiple predictors are correct 
		Int#(32) pcode = 4; 
    Tuple2#(Bit#(64),Bit#(64)) pfcmb0_out <- pfcmb0.read.get();
    Tuple2#(Bit#(64),Bit#(64)) pfcmb2_out <- pfcmb2.read.get();
    
    if (tpl_1(pfcmb0_out) == pc_reg) begin
      pcode = 0;
      hicnt = pused[0];
    end
    if ((pused[1] > hicnt) && (tpl_2(pfcmb0_out) == pc_reg)) begin
      pcode = 1;
      hicnt = pused[1];
    end
    pfcmb0.write(pack(pfcma0),tuple2(pc_reg,tpl_1(pfcmb0_out)));

    if ((pused[2] > hicnt) && (tpl_1(pfcmb2_out) == pc_reg)) begin
      pcode = 2;
      hicnt = pused[2];
    end 
    if ((pused[3] > hicnt) && (tpl_2(pfcmb2_out) == pc_reg)) begin
      pcode = 3;
      hicnt = pused[3];
    end
    pfcmb2.write(pack(pfcma2),tuple2(pc_reg,tpl_1(pfcmb2_out)));

    Int#(32) phash = unpack(truncate(pc_reg ^ (pc_reg >> pfcmsizeblg2)));
    phash = phash & (1<<pfcmsizeblg2)-1;
    pfcma2 <= (pfcma1 << 1) ^ phash;
    pfcma1 <= (((((pfcma0 << pfcmsizeblg2) | pfcma0) >> 2) & ((1<<pfcmsizeblg2)-1)) << 1) ^ phash;
    pfcma0 <= phash;
    pused[pcode] <= (pused[pcode] + 1);
    Prediction pred = Prediction{predictor: truncate(pcode), data:extend(pc_reg)};
    ppredictions.enq(pred);
    pstate <= Done;
  endrule


  rule predictTrace (vstate==Predict);
    //Int#(64) idx = unpack(pc_reg) & (65536-1); //VDIM-1
    //TODO clean up vcodes to only use some sensible contiguous range
    
    Int#(64) hicnt = -1; 
    Int#(64) hicntr1 = -1; 
    Int#(64) hicntr2 = -1; 
    Int#(64) hicnt_count = -1; 
		Int#(64) vcode = 10;  //TODO change these to smaller numbers later
		Int#(64) vcoder1 = 10; 
		Int#(64) vcoder2 = 10; 
		Int#(64) vcode_count = 2; 
    
    Vector#(4,Trace) vlnv_out <- vlnv.read.get();
    Vector#(4,Bit#(64)) vlnv_reg1_out <- vlnv_reg1.read.get();
    Vector#(4,Bit#(64)) vlnv_reg2_out <- vlnv_reg2.read.get();
    St2dEntry st2d_reg1_out <- st2d_reg1.read.get();
    St2dEntry st2d_reg2_out <- st2d_reg2.read.get();
//    St2dEntry st2d_count_out = st2d_count;
    St2dEntry st2d_count_out <- st2d_count.read.get();
    //Trace s = trace_reg - vlnv_out[0];
    //Vector#(3,Bit#(64)) vlines = vdfcma.read.get();

    //Int#(64) vline = unpack(vdfcma[idx][0]<<1); 
    //vdfcmb0.read.put(vlines[0]);
    
    //if (vdfcmb0[vline] == s) begin
    //  vcode = 0;
    //  hicnt = vused[0];
    //end
    //if ((vused[1] > hicnt) && (vdfcmb0[vline+1] == s)) begin
    //  vcode = 1;
    //  hicnt = vused[1];
    //end
    //vdfcmb0[vline + 1] <= vdfcmb0[vline];
    //vdfcmb0[vline] <= s;

    //vline = unpack(vdfcma[idx][2]<<1);
    //if ((vused[2] > hicnt) && (vdfcmb2[vline] == s)) begin
    //  vcode = 2;
    //  hicnt = vused[2];
    //end
    //if ((vused[3] > hicnt) && (vdfcmb2[vline + 1] == s)) begin
    //  vcode = 3;
    //  hicnt = vused[3];
    //end
    //vdfcmb2[vline + 1] <= vdfcmb2[vline];
    //vdfcmb2[vline] <= s;

    //Int#(32) vhash = hashVal(s, 17); //VDFCMSIZEBLG TODO decide if int32 is good enough
    //vdfcma[idx][2] <= (vdfcma[idx][1] << 1) ^ extend(pack(vhash));
    //vdfcma[idx][1] <= (vdfcma[idx][0] << 1) ^ extend(pack(vhash));
    //vdfcma[idx][0] <= extend(pack(vhash));
   
    
    /* ------------- Easy data l4v predictor ------------- */ 
    if ((vused[4] > hicnt) && (trace_reg == vlnv_out[0])) begin
      vcode = 4;
      hicnt = vused[4];
    end
    if ((vused[5] > hicnt) && (trace_reg == vlnv_out[1])) begin 
      vcode = 5;
      hicnt = vused[5];
    end
    if ((vused[6] > hicnt) && (trace_reg == vlnv_out[2])) begin
      vcode = 6;
      hicnt = vused[6];
    end
    if ((vused[7] > hicnt) && (trace_reg == vlnv_out[3])) begin
      vcode = 7;
      hicnt = vused[7];
    end

    /* ------------- Reg 1 l4v predictor ------------- */ 
    if ((vusedr1[4] > hicntr1) && (r1data == vlnv_reg1_out[0])) begin
      vcoder1 = 4;
      hicntr1 = vusedr1[4];
    end
    if ((vusedr1[5] > hicntr1) && (r1data == vlnv_reg1_out[1])) begin 
      vcoder1 = 5;
      hicntr1 = vusedr1[5];
    end
    if ((vusedr1[6] > hicntr1) && (r1data == vlnv_reg1_out[2])) begin
      vcoder1 = 6;
      hicntr1 = vusedr1[6];
    end
    if ((vusedr1[7] > hicntr1) && (r1data == vlnv_reg1_out[3])) begin
      vcoder1 = 7;
      hicntr1 = vusedr1[7];
    end

    /* ------------- Reg 2 l4v predictor ------------- */ 
    if ((vusedr2[4] > hicntr2) && (r2data == vlnv_reg2_out[0])) begin
      vcoder2 = 4;
      hicntr2 = vusedr2[4];
    end
    if ((vusedr2[5] > hicntr2) && (r2data == vlnv_reg2_out[1])) begin 
      vcoder2 = 5;
      hicntr2 = vusedr2[5];
    end
    if ((vusedr2[6] > hicntr2) && (r2data == vlnv_reg2_out[2])) begin
      vcoder2 = 6;
      hicntr2 = vusedr2[6];
    end
    if ((vusedr2[7] > hicntr2) && (r2data == vlnv_reg2_out[3])) begin
      vcoder2 = 7;
      hicntr2 = vusedr2[7];
    end

    /* ------------- Reg 1 ST2D predictor ------------- */ 
    //TODO group count with one or both of the registers
    if ((vusedr1[8] > hicntr1) && (r1data == (st2d_reg1_out.data + st2d_reg1_out.delta))) begin
      vcoder1 = 8;
      hicntr1 = vusedr1[8];
    end
    if ((vusedr1[9] > hicntr1) && (r1data == (st2d_reg1_out.data + st2d_reg1_out.delta2))) begin
      vcoder1 = 9;
      hicntr1 = vusedr1[9];
    end
      
    /* ------------- Reg 2 ST2D predictor ------------- */ 
    if ((vusedr2[8] > hicntr2) && (r2data == (st2d_reg2_out.data + st2d_reg2_out.delta))) begin
      vcoder2 = 8;
      hicntr2 = vusedr2[8];
    end
    if ((vusedr2[9] > hicntr2) && (r2data == (st2d_reg2_out.data + st2d_reg2_out.delta2))) begin
      vcoder2 = 9;
      hicntr2 = vusedr2[9];
    end
    
    /* -------------Count ST2D predictor ------------- */ 
    if ((vused_count[0] > hicnt_count) && (count_reg == (st2d_count_out.data + st2d_count_out.delta))) begin
      vcode_count = 0;
      hicnt_count = vused_count[0];
    end
    if ((vused_count[1] > hicnt_count) && (count_reg == (st2d_count_out.data + st2d_count_out.delta2))) begin
      vcode_count = 1;
      hicnt_count = vused_count[1];
    end
//		$display("ALLISON count is: ", fshow(count_reg));
//	$display("ALLISON data is: ", fshow(st2d_count_out.data));
//		$display("ALLISON delta is: ", fshow(st2d_count_out.delta));

		Trace t0 = vlnv_out[0];
		Trace t1 = vlnv_out[1];
		Trace t2 = vlnv_out[2];
		Trace t3 = vlnv_out[3];
		//$display("ALLISON trace pred0", fshow(t0));
		//$display("ALLISON trace pred1", fshow(t1));
		//$display("ALLISON trace pred2", fshow(t2));
		//$display("ALLISON trace pred3", fshow(t3));

    Vector#(4,Trace) vlnv_update;
		vlnv_update[3] = vlnv_out[2];
		vlnv_update[2] = vlnv_out[1];
		vlnv_update[1] = vlnv_out[0];
		vlnv_update[0] =  trace_reg;
    vlnv.write(pc_reg[15:0], vlnv_update);

    Vector#(4,Bit#(64)) vlnv_reg1_update;
		vlnv_reg1_update[3] = vlnv_reg1_out[2];
		vlnv_reg1_update[2] = vlnv_reg1_out[1];
		vlnv_reg1_update[1] = vlnv_reg1_out[0];
		vlnv_reg1_update[0] =  r1data;
    vlnv_reg1.write(pc_reg[15:0], vlnv_reg1_update);

    Vector#(4,Bit#(64)) vlnv_reg2_update;
		vlnv_reg2_update[3] = vlnv_reg2_out[2];
		vlnv_reg2_update[2] = vlnv_reg2_out[1];
		vlnv_reg2_update[1] = vlnv_reg2_out[0];
		vlnv_reg2_update[0] =  r2data;
    vlnv_reg2.write(pc_reg[15:0], vlnv_reg2_update);

    //update st2d reg1 predictor
    St2dEntry st2d_update = updateSt2d(st2d_reg1_out, r1data);
    st2d_reg1.write(pc_reg[15:0], st2d_update);

    //update st2d reg2 predictor
    st2d_update = updateSt2d(st2d_reg2_out, r2data);
    st2d_reg2.write(pc_reg[15:0], st2d_update);

    //update st2d count predictor
    st2d_update = updateSt2d(st2d_count_out, count_reg);
    st2d_count.write(pc_reg[15:0], st2d_update);
//		st2d_count <= st2d_update;

   
    //vline = unpack(vfcma[idx] << 1);
    //if ((vused[8] > hicnt) && (trace_reg == vfcmb[vline])) begin
    //  vcode = 8;
    //  hicnt = vused[8];
    //end
    //if ((vused[9] > hicnt) && (trace_reg == vfcmb[vline+1])) begin
    //  vcode = 9;
    //  hicnt = vused[9];
    //end
    //vfcmb[vline+1] <= vfcmb[vline];
    //vfcmb[vline] <= trace_reg;
    //vfcma[idx] <= extend(pack(hashVal(trace_reg, 19))); //vfcmsizeblg2

    vused[vcode] <= vused[vcode] + 1;
    vusedr1[vcoder1] <= vusedr1[vcoder1] + 1;
    vusedr2[vcoder2] <= vusedr2[vcoder2] + 1;
    vused_count[vcode_count] <= vused_count[vcode_count] + 1;
                 
    Prediction pred = Prediction{predictor: truncate(vcode), data:extend(pack(trace_reg))};
    Prediction predr1 = Prediction{predictor: truncate(vcoder1), data:extend(r1data)};
    Prediction predr2 = Prediction{predictor: truncate(vcoder2), data:extend(r2data)};
    Prediction pred_count = Prediction{predictor: truncate(vcode_count), data:extend(count_reg)};
    vpredictions.enq(pred);
    r1predictions.enq(predr1);
    r2predictions.enq(predr2);
    countpredictions.enq(pred_count);
    vstate <= Done;
  endrule


  
  method Action predictUpdate (Bit#(64) pc, TraceEntry full_trace) if ((pstate == Done) && (vstate == Done));
    pc_reg <= pc;
    pfcmb0.read.put(pack(pfcma0));
    pfcmb2.read.put(pack(pfcma2));

    r1data <= full_trace.regVal1;
    r2data <= full_trace.regVal2;
   // count_reg <= extend(full_trace.count);
    original_trace <= full_trace;

    Trace trace = Trace{valid : full_trace.valid,  // 1 ; always true
                       version: full_trace.version,
                            ex: full_trace.ex,
                          asid: full_trace.asid,
                        branch: full_trace.branch,
                      reserved: full_trace.reserved,
                          inst: full_trace.inst,
                            pc: full_trace.pc};
    trace_reg <= trace;
    //Int#(64) idx = unpack(pc_reg) & (65536-1); //VDIM-1
    //anding with 16'1 should be the same as just truncating pc_reg
    vlnv.read.put(pc[15:0]); 
    vlnv_reg1.read.put(pc[15:0]); 
    vlnv_reg2.read.put(pc[15:0]); 
    st2d_reg1.read.put(pc[15:0]); 
    st2d_reg2.read.put(pc[15:0]); 
    st2d_count.read.put(pc[15:0]); 
    //vdfcma.read.put(pc_reg[15:0]);
    pstate <= Predict;
    vstate <= Predict;
  endmethod


  method ActionValue#(Prediction) getPcPrediction();
    Prediction ret = ppredictions.first();
    ppredictions.deq();
    return ret; 
  endmethod

  method ActionValue#(Prediction) getTracePrediction();
    Prediction ret = vpredictions.first();
    vpredictions.deq();
    return ret;  
  endmethod

  method ActionValue#(Prediction) getR1Prediction();
    Prediction ret = r1predictions.first();
    r1predictions.deq();
    return ret;  
  endmethod

  method ActionValue#(Prediction) getR2Prediction();
    Prediction ret = r2predictions.first();
    r2predictions.deq();
    return ret;  
  endmethod

  method ActionValue#(Prediction) getCountPrediction(); 
		Prediction ret = countpredictions.first(); 
		countpredictions.deq();
		return ret;
  endmethod

//  method getCount() = count;
  method getOriginalTrace() = original_trace;


endmodule

interface Compressor;
  interface Put#(TraceEntry) enq;
  interface Get#(TraceEntry) first_deq;
endinterface

module mkCompressor(Compressor);
  TracePredictor tp <- mkTracePredictor();
  FIFO#(TraceEntry) traceInputs <- mkFIFO;
  FIFO#(TraceEntry) compressedOutputs <- mkFIFO;
  Bit#(4) versions[8] = {5, 6, 7, 8, 9, 10, 14, 15}; 

  rule compress_trace;
    TraceEntry te = traceInputs.first();
//		$display("ALLISON enqueue", fshow(te));
		traceInputs.deq();
    tp.predictUpdate(te.pc, te);
  endrule

  rule enq_predictions; 
    Prediction pc_pred <- tp.getPcPrediction();
    Prediction trace_pred <- tp.getTracePrediction();
    Prediction r1_pred <- tp.getR1Prediction();
    Prediction r2_pred <- tp.getR2Prediction();
    Prediction count_pred <- tp.getCountPrediction();

//    Bit#(10) count = tp.getCount();
    Bit#(3) version_idx;
    version_idx[0] = pc_pred.predictor == 4 ? 1 : 0; 
    version_idx[1] = r1_pred.predictor == 10 ? 1 : 0; 
    version_idx[2] = r2_pred.predictor == 10 ? 1 : 0; 
    Bit#(4) ver = versions[version_idx]; 

    // Chop unnecessary data off in messagePacket later
    Bit#(64) d1 = pc_pred.predictor == 4 ? truncate(pc_pred.data) : 
																			r1_pred.predictor == 10 ? truncate(r1_pred.data) : truncate(r2_pred.data); 
    Bit#(64) d2 = r1_pred.predictor == 10 ? truncate(r1_pred.data) : truncate(r2_pred.data); 
    Bit#(64) d3 = truncate(r2_pred.data); 

    // only 8 available versions
    // if we get the easy data wrong, send it back. TODO data on how much we lose here.
    // also send the whole thing back if we get the count prediction wrong because we don't have enough version bits and we *should* almost never get count wrong
//		$display("ALLISON count pred", count_pred.predictor);
//		$display("ALLISON trace pred", trace_pred.predictor);
//		$display("ALLISON r1 pred", r1_pred.predictor);
//		$display("ALLISON r2 pred", r2_pred.predictor);
//		$display("ALLISON pc pred", pc_pred.predictor);
		// right now not counting count prediction for anything
    if (trace_pred.predictor == 10) begin
      TraceEntry ot = tp.getOriginalTrace();
      compressedOutputs.enq(ot);
    end
    else begin 
			CompressedTraceEntry cte = CompressedTraceEntry{
                                 valid: True,
                               version: ver,      
                               pc_pred: truncate(pack(pc_pred.predictor)),      
                             easy_pred: truncate(pack(trace_pred.predictor)),
                            count_pred: truncate(pack(count_pred.predictor)),
                               r1_pred: truncate(pack(r1_pred.predictor)),
                               r2_pred: truncate(pack(r2_pred.predictor)),
                                 data1: d1,
                                 data2: d2,
                                 data3: d3,
															 padding: 0};

			compressedOutputs.enq(unpack(pack(cte))); 
		end
  endrule

	interface Put enq = fifoToPut(traceInputs);
	interface Get first_deq = toGet(compressedOutputs);
  
endmodule

//*---The default trace type---*/
//typedef struct {
//  Bool        valid; // 1
//  Bit#(4)   version; // 4
//  Bit#(5)        ex; // 5
//  Bit#(10)    count; // 10
//  Bit#(8)      asid; // 8
//  Bool       branch; // 1
//  Bit#(3)  reserved; // 3
//  Bit#(32)     inst; // 32
//  Bit#(64)       pc; // 64
//  Bit#(64)  regVal1; // 64
//  Bit#(64)  regVal2; // 64
//} TraceEntry deriving (Bits, Eq, FShow); // total=256




