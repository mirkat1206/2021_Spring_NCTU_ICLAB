//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2016 ICLAB Spring Course
//   Lab02			: Ranking & Arithmetic
//   Author         : Chung-Tao Yang (h110811030@gmail.com)
//
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TESTBED.sv
//   Module Name : TESTBED
//   Release version : v1.0
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`include "PATTERN.v"

module TESTBED();

wire clk;
wire rst_n;

wire isstring;
wire ispattern;
wire [7:0] chardata;

wire out_valid;
wire match;
wire [4:0] match_index;

SME U_SME(
	.clk(clk),
	.rst_n(rst_n),
	.isstring(isstring),
	.ispattern(ispattern),
	.chardata(chardata),
	.out_valid(out_valid),
	.match(match),
	.match_index(match_index)
);

PATTERN U_PATTERN(
	.clk(clk),
	.rst_n(rst_n),
	.isstring(isstring),
	.ispattern(ispattern),
	.chardata(chardata),
	.out_valid(out_valid),
	.match(match),
	.match_index(match_index)
);

initial begin
	`ifdef RTL
		$fsdbDumpfile("SME.fsdb");
		$fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	`endif
	`ifdef GATE
		$sdf_annotate("SME_SYN.sdf",U_SME);
		$fsdbDumpfile("SME_SYN.fsdb");
		$fsdbDumpvars();
	`endif
end

endmodule
