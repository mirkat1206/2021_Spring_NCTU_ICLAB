`timescale 1ns/1ps

`include "Usertype_PKG.sv"
`include "INF.sv"
`include "PATTERN.sv"
`include "PATTERN_bridge.sv"
`include "PATTERN_farm.sv"
`include "../00_TESTBED/pseudo_DRAM.sv"

`ifdef RTL
  `include "bridge.sv"
  `include "farm.sv"
`endif

`ifdef GATE
  `include "bridge_SYN.v"
  `include "bridge_Wrapper.sv"
  `include "farm_SYN.v"
  `include "farm_Wrapper.sv"
`endif

module TESTBED;
  
parameter simulation_cycle = 2.3;
  reg  SystemClock;

  INF            inf(SystemClock);
  PATTERN        test_p(.clk(SystemClock), .inf(inf.PATTERN));
  PATTERN_bridge test_pb(.clk(SystemClock), .inf(inf.PATTERN_bridge));
  PATTERN_farm   test_pf(.clk(SystemClock), .inf(inf.PATTERN_farm));
  pseudo_DRAM    dram_r(.clk(SystemClock), .inf(inf.DRAM)); 

  `ifdef RTL
	bridge dut_b(.clk(SystemClock), .inf(inf.bridge_inf) );
	farm   dut_p(.clk(SystemClock), .inf(inf.farm_inf) );
  `endif
  
  `ifdef GATE
	bridge_svsim dut_b(.clk(SystemClock), .inf(inf.bridge_inf) );
	farm_svsim   dut_p(.clk(SystemClock), .inf(inf.farm_inf) );
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
  
//------ Dump FSDB File ------------  
initial begin
  `ifdef RTL
    $fsdbDumpfile("HF.fsdb");
    $fsdbDumpvars(0,"+all");
    $fsdbDumpSVA;
  `elsif GATE
    $fsdbDumpfile("HF_SYN.fsdb");
    $sdf_annotate("../02_SYN/Netlist/bridge_SYN.sdf",dut_b.bridge);      
    $sdf_annotate("../02_SYN/Netlist/farm_SYN.sdf",dut_p.farm);      
    $fsdbDumpvars(0,"+all");
  `endif
end

endmodule