`timescale 1ns/1ps
`include "PATTERN.v"
`ifdef RTL
	`include "DH.v"
`elsif GATE
	`include "DH_SYN.v"
`elsif POST
    `include "CHIP.v"
`endif

module TESTBED();
	
// input signals
wire clk, rst_n, IN_VALID_1, IN_VALID_2;
wire signed[5:0] ALPHA_I, THETA_JOINT_1, THETA_JOINT_2, THETA_JOINT_3, THETA_JOINT_4;
wire [2:0] A_I, D_I;
// output signals
wire OUT_VALID;
wire signed[8:0] OUT_X, OUT_Y, OUT_Z; 

initial begin
	`ifdef RTL
		$fsdbDumpfile("DH.fsdb");
		$fsdbDumpvars(0,"+mda");
	`elsif GATE
		//$fsdbDumpfile("DH_SYN.fsdb");
		$sdf_annotate("DH_SYN.sdf",I_DH);      
		//$fsdbDumpvars(0,"+mda");
	`elsif POST
		$sdf_annotate("CHIP.sdf",My_CHIP);
		$fsdbDumpfile("CHIP_POST.fsdb");
		$fsdbDumpvars(0,"+mda");
	`endif
end
`ifdef RTL
DH I_DH(
	// Input signals
	.clk(clk),
	.rst_n(rst_n),
	.IN_VALID_1(IN_VALID_1),
	.IN_VALID_2(IN_VALID_2),
	.ALPHA_I(ALPHA_I),
	.A_I(A_I),
	.D_I(D_I),
	.THETA_JOINT_1(THETA_JOINT_1),
	.THETA_JOINT_2(THETA_JOINT_2),
	.THETA_JOINT_3(THETA_JOINT_3),
	.THETA_JOINT_4(THETA_JOINT_4),
	// Output signals
	.OUT_VALID(OUT_VALID),
	.OUT_X(OUT_X),
	.OUT_Y(OUT_Y),
	.OUT_Z(OUT_Z)
);
`elsif GATE
DH I_DH(
	// Input signals
	.clk(clk),
	.rst_n(rst_n),
	.IN_VALID_1(IN_VALID_1),
	.IN_VALID_2(IN_VALID_2),
	.ALPHA_I(ALPHA_I),
	.A_I(A_I),
	.D_I(D_I),
	.THETA_JOINT_1(THETA_JOINT_1),
	.THETA_JOINT_2(THETA_JOINT_2),
	.THETA_JOINT_3(THETA_JOINT_3),
	.THETA_JOINT_4(THETA_JOINT_4),
	// Output signals
	.OUT_VALID(OUT_VALID),
	.OUT_X(OUT_X),
	.OUT_Y(OUT_Y),
	.OUT_Z(OUT_Z)
);
`elsif POST
CHIP My_CHIP(
	// Input signals
	.clk(clk),
	.rst_n(rst_n),
	.IN_VALID_1(IN_VALID_1),
	.IN_VALID_2(IN_VALID_2),
	.ALPHA_I(ALPHA_I),
	.A_I(A_I),
	.D_I(D_I),
	.THETA_JOINT_1(THETA_JOINT_1),
	.THETA_JOINT_2(THETA_JOINT_2),
	.THETA_JOINT_3(THETA_JOINT_3),
	.THETA_JOINT_4(THETA_JOINT_4),
	// Output signals
	.OUT_VALID(OUT_VALID),
	.OUT_X(OUT_X),
	.OUT_Y(OUT_Y),
	.OUT_Z(OUT_Z)
);
`endif

PATTERN I_PATTERN(
	// Input signals
	.clk(clk),
	.rst_n(rst_n),
	.IN_VALID_1(IN_VALID_1),
	.IN_VALID_2(IN_VALID_2),
	.ALPHA_I(ALPHA_I),
	.A_I(A_I),
	.D_I(D_I),
	.THETA_JOINT_1(THETA_JOINT_1),
	.THETA_JOINT_2(THETA_JOINT_2),
	.THETA_JOINT_3(THETA_JOINT_3),
	.THETA_JOINT_4(THETA_JOINT_4),
	// Output signals
	.OUT_VALID(OUT_VALID),
	.OUT_X(OUT_X),
	.OUT_Y(OUT_Y),
	.OUT_Z(OUT_Z)
);

endmodule
