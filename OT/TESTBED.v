`timescale 1ns/1ps
`include "PATTERN.v"

`ifdef RTL
  `include "TRIANGLE.v"
`endif
`ifdef GATE
  `include "TRIANGLE_SYN.v"
`endif
	  		  	
module TESTBED;

wire            clk, rst_n, in_valid;
wire    [4:0]  coord_x, coord_y;

wire            out_valid;
wire    [12:0]  out_length;
wire    [12:0]  out_incenter;


initial begin
  `ifdef RTL
    $fsdbDumpfile("TRIANGLE.fsdb");
    $fsdbDumpvars(0,"+mda");
  `endif
  `ifdef GATE
    $sdf_annotate("TRIANGLE_SYN.sdf", u_TRIANGLE);
    //$fsdbDumpfile("TRIANGLE_SYN.fsdb");
    //$fsdbDumpvars(0,"+mda");    
  `endif
end

TRIANGLE u_TRIANGLE(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .coord_x(coord_x),
    .coord_y(coord_y),
    .out_valid(out_valid),
    .out_length(out_length),
    .out_incenter(out_incenter)
);

PATTERN u_PATTERN(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .coord_x(coord_x),
    .coord_y(coord_y),
    .out_valid(out_valid),
    .out_length(out_length),
    .out_incenter(out_incenter)
);
  
 
endmodule
