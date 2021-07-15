`timescale 1ns/10ps

`include "PATTERN.v"
`ifdef RTL
  `include "PN.v"
  `include "syn_XOR.v"
  `include "synchronizer.v"
`endif
`ifdef GATE
  `include "PN_SYN.v"
`endif 
	  		  	
module TESTBED;

wire         clk_1, clk_2, clk_3, rst_n, in_valid, mode, operator;
wire  [2:0]  in;
wire         out_valid;
wire  [63:0]  out;


initial begin
  `ifdef RTL
    $fsdbDumpfile("PN.fsdb");
	$fsdbDumpvars(0,"+mda");
  `endif
  `ifdef GATE
    $sdf_annotate("../02_SYN/Netlist/PN_SYN_pt.sdf", u_PN,,,"maximum");
    $fsdbDumpfile("PN_SYN.fsdb");
	$fsdbDumpvars(0,"+mda"); 
  `endif
end

PN u_PN(
    .clk_1(clk_1),
    .clk_2(clk_2),
    .clk_3(clk_3),
    .rst_n(rst_n),
    .in_valid(in_valid),
	  .in(in),
    .mode(mode),
    .operator(operator),
    .out_valid(out_valid),
    .out(out)
    );
	
PATTERN u_PATTERN(
    .clk_1(clk_1),
    .clk_2(clk_2),
    .clk_3(clk_3),
    .rst_n(rst_n),
    .in_valid(in_valid),
	  .in(in),
    .mode(mode),
    .operator(operator),
    .out_valid(out_valid),
    .out(out)
    );
  
endmodule
