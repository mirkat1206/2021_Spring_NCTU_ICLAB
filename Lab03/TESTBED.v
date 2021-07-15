`timescale 1ns/10ps

`include "PATTERN.v"
`ifdef RTL
  `include "SD.v"
`endif
`ifdef GATE
  `include "SD_SYN.v"
`endif
	  		  	
module TESTBED;

wire clk, rst_n, in_valid;
wire [3:0] in;
wire out_valid;
wire [3:0] out;


initial begin
  `ifdef RTL
    $fsdbDumpfile("SD.fsdb");
  $fsdbDumpvars(0,"+mda");
  `endif
  `ifdef GATE
    $sdf_annotate("SD_SYN.sdf", u_SD);
    $fsdbDumpfile("SD_SYN.fsdb");
  $fsdbDumpvars(0,"+mda"); 
  `endif
end

SD u_SD(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
	.in(in),
    .out_valid(out_valid),
    .out(out)
    );
	
PATTERN u_PATTERN(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
	.in(in),
    .out_valid(out_valid),
    .out(out)
    );
  
endmodule
