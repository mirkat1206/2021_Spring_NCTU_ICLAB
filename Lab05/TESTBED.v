`timescale 1ns/1ps
`include "PATTERN.v"
`ifdef RTL
`include "MC.v"
`elsif GATE
`include "MC_SYN.v"
`endif

module TESTBED();

//Connection wires
wire			clk,rst_n,in_valid;
wire	[30:0]	in_data;
wire	[1:0]	size;
wire	[2:0]	action;

wire			out_valid;
wire	[30:0]	out_data;

initial begin
  `ifdef RTL
    $fsdbDumpfile("MC.fsdb");
    $fsdbDumpvars(0,"+mda");
  `endif
  `ifdef GATE
    $sdf_annotate("MC_SYN.sdf",My_MC);
	$fsdbDumpfile("MC_SYN.fsdb");
    $fsdbDumpvars(0,"+mda");
  `endif
end

MC My_MC(
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
