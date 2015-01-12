module RunMegafunctionTest(input clk, input rst);
	
	//mkTestMegafunctions mf(.CLK(clk), .RST_N(rst));
	//mkTest mf(.CLK(clk), .RST_N(rst));
	//mkCompositeOpTests test(clk, rst);
	mkMegafunctionServerTests tests(clk, rst);

endmodule