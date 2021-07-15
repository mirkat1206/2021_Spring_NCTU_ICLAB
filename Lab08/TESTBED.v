`timescale 1ns/1ps

`ifdef RTL
`include "SP.v"

`elsif GATE
`include "SP_SYN.v"

`endif

`ifdef CG
`include "PATTERN_CG.v"

`elsif NCG
`include "PATTERN.v"

`endif

module TESTBED();
	wire clk, rst_n, in_valid;
	wire [8:0] in_data;
	wire [2:0] in_mode;
	wire out_valid;
	wire [8:0] out_data;	

	
initial begin
	`ifdef RTL
		`ifdef CG
		$fsdbDumpfile("SP_SYN_CG.fsdb");
		`elsif NCG
		$fsdbDumpfile("SP_SYN.fsdb");
		`endif
		$fsdbDumpvars();
		$fsdbDumpvars(0,"+mda");
	`elsif GATE
		`ifdef CG
		$fsdbDumpfile("SP_SYN_CG.fsdb");
		`elsif NCG
		$fsdbDumpfile("SP_SYN.fsdb");
		`endif
		$sdf_annotate("SP_SYN.sdf",I_SP);      
		// $fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	`endif
end

SP I_SP
(
	// Input signals
	.clk(clk),
	.rst_n(rst_n),
	.cg_en(cg_en),
	.in_valid(in_valid),
	.in_data(in_data),
	.in_mode(in_mode),
	// Output signals
	.out_valid(out_valid),
	.out_data(out_data)
);


PATTERN I_PATTERN
(
	// Output signals
	.clk(clk),
	.rst_n(rst_n),
	.cg_en(cg_en),
	.in_valid(in_valid),
	.in_data(in_data),
	.in_mode(in_mode),
	// Input signals
	.out_valid(out_valid),
	.out_data(out_data)
);

endmodule
