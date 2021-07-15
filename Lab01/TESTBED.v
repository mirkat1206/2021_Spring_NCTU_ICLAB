//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2018 Fall
//   Lab01-Practice		: Code Calculator
//   Author     		: Po-Yu, Huang (hpy35269.eecs02@g2.nctu.edu.com)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TESETBED.v
//   Module Name : TESETBED
//   Release version : V1.0 (Release Date: 2016-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`timescale 1ns/10ps
`include "PATTERN.v"
`ifdef RTL
  `include "SMC.v"
`endif
`ifdef GATE
  `include "SMC_SYN.v"
`endif
	  		  	
module TESTBED; 

//Connection wires
wire [2:0] W_0, V_GS_0, V_DS_0;
wire [2:0] W_1, V_GS_1, V_DS_1;
wire [2:0] W_2, V_GS_2, V_DS_2;
wire [2:0] W_3, V_GS_3, V_DS_3;
wire [2:0] W_4, V_GS_4, V_DS_4;
wire [2:0] W_5, V_GS_5, V_DS_5;
wire [1:0] mode;
wire [9:0] out_n;
initial begin
  `ifdef RTL
    $fsdbDumpfile("SMC.fsdb");
	$fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();
  `endif
  `ifdef GATE
    $sdf_annotate("SMC_SYN.sdf", DUT_SMC);
    $fsdbDumpfile("SMC_SYN.fsdb");
	$fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();    
  `endif
end

SMC DUT_SMC(
.W_0(W_0), .V_GS_0(V_GS_0), .V_DS_0(V_DS_0),
.W_1(W_1), .V_GS_1(V_GS_1), .V_DS_1(V_DS_1),
.W_2(W_2), .V_GS_2(V_GS_2), .V_DS_2(V_DS_2),
.W_3(W_3), .V_GS_3(V_GS_3), .V_DS_3(V_DS_3),
.W_4(W_4), .V_GS_4(V_GS_4), .V_DS_4(V_DS_4),
.W_5(W_5), .V_GS_5(V_GS_5), .V_DS_5(V_DS_5),
.mode(mode),
.out_n(out_n)
);

PATTERN My_PATTERN(
.W_0(W_0), .V_GS_0(V_GS_0), .V_DS_0(V_DS_0),
.W_1(W_1), .V_GS_1(V_GS_1), .V_DS_1(V_DS_1),
.W_2(W_2), .V_GS_2(V_GS_2), .V_DS_2(V_DS_2),
.W_3(W_3), .V_GS_3(V_GS_3), .V_DS_3(V_DS_3),
.W_4(W_4), .V_GS_4(V_GS_4), .V_DS_4(V_DS_4),
.W_5(W_5), .V_GS_5(V_GS_5), .V_DS_5(V_DS_5),
.mode(mode),
.out_n(out_n)
);
 
endmodule
