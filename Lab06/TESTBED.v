//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2021 ICLAB Spring Course
//   Lab06       : CheckSum
//   Author      : Huan-Jung Lee (alexli1205.ee09g@nctu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TESTBED.v
//   Module Name : TESTBED
//   Release version : v1.0
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`timescale 1ns/1ps

`ifdef RTL
    `include "PATTERN.v"
    `include "CS.v"
`endif

`ifdef GATE
    `include "PATTERN.v"
    `include "CS_SYN.v"
`endif

module TESTBED;

parameter WIDTH_DATA_1 = 384, WIDTH_RESULT_1 = 8;
parameter WIDTH_DATA_2 = 128, WIDTH_RESULT_2 = 8;

//Connection wires
wire [(WIDTH_DATA_1 + WIDTH_DATA_2 - 1):0] data;
wire [(WIDTH_RESULT_1 + WIDTH_RESULT_2 -1):0] result;
wire clk,rst_n;
wire in_valid,out_valid;


initial begin
    `ifdef RTL
        $fsdbDumpfile("CS.fsdb");
        $fsdbDumpvars(0,"+mda");
    `endif
    `ifdef GATE
        $sdf_annotate("CS_SYN.sdf", My_CS);
        $fsdbDumpfile("CS_SYN.fsdb");
        $fsdbDumpvars(0,"+mda");
    `endif
end

`ifdef RTL
	CS #(.WIDTH_DATA_1(WIDTH_DATA_1), .WIDTH_RESULT_1(WIDTH_RESULT_1),
    .WIDTH_DATA_2(WIDTH_DATA_2), .WIDTH_RESULT_2(WIDTH_RESULT_2)) My_CS(
        .data(data),
        .in_valid(in_valid),
        .clk(clk),
        .rst_n(rst_n),
        .result(result),
        .out_valid(out_valid)
	);

	PATTERN #(.WIDTH_DATA_1(WIDTH_DATA_1), .WIDTH_RESULT_1(WIDTH_RESULT_1),
    .WIDTH_DATA_2(WIDTH_DATA_2), .WIDTH_RESULT_2(WIDTH_RESULT_2)) My_PATTERN(
        .data(data),
        .in_valid(in_valid),
        .clk(clk),
        .rst_n(rst_n),
        .result(result),
        .out_valid(out_valid)
	);

`elsif GATE
	CS My_CS(
        .data(data),
        .in_valid(in_valid),
        .clk(clk),
        .rst_n(rst_n),
        .result(result),
        .out_valid(out_valid)
	);

	PATTERN #(.WIDTH_DATA_1(WIDTH_DATA_1), .WIDTH_RESULT_1(WIDTH_RESULT_1),
    .WIDTH_DATA_2(WIDTH_DATA_2), .WIDTH_RESULT_2(WIDTH_RESULT_2)) My_PATTERN(
        .data(data),
        .in_valid(in_valid),
        .clk(clk),
        .rst_n(rst_n),
        .result(result),
        .out_valid(out_valid)
	);
`endif


endmodule
