`timescale 1ns/1ps
`include "PATTERN.v"
`include "CHIP.v"

module TESTBED();

//Connection wires
wire			clk,rst_n,in_valid;
wire	[31:0]	in_data;
wire	[1:0]	size;
wire	[2:0]	action;

wire			out_valid;
wire	[31:0]	out_data;

initial 
begin
	$sdf_annotate("CHIP.sdf",U_CHIP);
//	$fsdbDumpfile("CHIP.fsdb");
//	$fsdbDumpvars(0,"+mda");
end

CHIP U_CHIP(
        // input signals
		clk,
		rst_n,
		in_valid,
		in_data,
		size,
		action,
        // output signals
		out_valid,
		out_data
);

PATTERN My_PATTERN(
        // input signals
		clk,
		rst_n,
		in_valid,
		in_data,
		size,
		action,
        // output signals
		out_valid,
		out_data
);

endmodule
