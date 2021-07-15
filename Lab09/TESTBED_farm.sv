`timescale 1ns/100ps

`include "Usertype_PKG.sv"
`include "INF.sv"
`include "PATTERN_farm.sv"

`ifdef RTL
  `include "farm.sv"
`endif

module TESTBED;
  
  parameter simulation_cycle = 15.0;
  reg  SystemClock;

  INF  inf(SystemClock);
  PATTERN_farm test_p(.clk(SystemClock), .inf(inf.PATTERN_farm));
  
  `ifdef RTL
	farm dut(.clk(SystemClock), .inf(inf.farm_inf) );
  `endif
  
 //------ Generate Clock ------------
  initial begin
    SystemClock = 0;
	#30
    forever begin
      #(simulation_cycle/2.0)
        SystemClock = ~SystemClock;
    end
  end
  
//------ Dump VCD File ------------  
initial begin
  `ifdef RTL
    $fsdbDumpfile("farm.fsdb");
    $fsdbDumpvars(0,"+all");
    $fsdbDumpSVA;
  `endif
end

endmodule