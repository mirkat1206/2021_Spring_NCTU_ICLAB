//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Final Project: Customized ISA Processor (CPU)
//   Author       : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
`ifdef RTL
    `define CYCLE_TIME 3.6
    `define RTL_GATE
`elsif GATE
    `define CYCLE_TIME 3.6
    `define RTL_GATE
`elsif CHIP
    `define CYCLE_TIME 3.6
    `define CHIP_POST 
`elsif POST
    `define CYCLE_TIME 3.6
    `define CHIP_POST 
`endif


`ifdef FUNC
`define MAX_WAIT_READY_CYCLE 2000
`endif
`ifdef PERF
`define MAX_WAIT_READY_CYCLE 100000
`endif


`include "../00_TESTBED/MEM_MAP_define.v"
`include "../00_TESTBED/pseudo_DRAM_data.v"
`include "../00_TESTBED/pseudo_DRAM_inst.v"

module PATTERN(
// global signals 
                clk,
              rst_n,
           IO_stall,
// axi write address channel 
         awid_s_inf,
       awaddr_s_inf,
       awsize_s_inf,
      awburst_s_inf,
        awlen_s_inf,
      awvalid_s_inf,
      awready_s_inf,
// axi write data channel 
        wdata_s_inf,
        wlast_s_inf,
       wvalid_s_inf,
       wready_s_inf,
// axi write response channel
          bid_s_inf,
        bresp_s_inf,
       bvalid_s_inf,
       bready_s_inf,
// axi read address channel 
         arid_s_inf,
       araddr_s_inf,
        arlen_s_inf,
       arsize_s_inf,
      arburst_s_inf,
      arvalid_s_inf,
      arready_s_inf, 
// axi read data channel
          rid_s_inf,
        rdata_s_inf,
        rresp_s_inf,
        rlast_s_inf,
       rvalid_s_inf,
       rready_s_inf 
);
//================================================================
//  PORT DECLARATION
//================================================================
parameter ID_WIDTH=4, DATA_WIDTH=16, ADDR_WIDTH=32, DRAM_NUMBER=2, WRIT_NUMBER=1;
// ---------------------------------------------------------------
// global signals 
output reg  clk, rst_n;
input IO_stall;
// ---------------------------------------------------------------
// axi write address channel 
input wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_s_inf;
input wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_s_inf;
input wire [WRIT_NUMBER * 3 -1:0]            awsize_s_inf;
input wire [WRIT_NUMBER * 2 -1:0]           awburst_s_inf;
input wire [WRIT_NUMBER * 7 -1:0]             awlen_s_inf;
input wire [WRIT_NUMBER-1:0]                awvalid_s_inf;
output wire [WRIT_NUMBER-1:0]               awready_s_inf;
// ---------------------------------------------------------------
// axi write data channel 
input wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_s_inf;
input wire [WRIT_NUMBER-1:0]                  wlast_s_inf;
input wire [WRIT_NUMBER-1:0]                 wvalid_s_inf;
output wire [WRIT_NUMBER-1:0]                wready_s_inf;
// ---------------------------------------------------------------
// axi write response channel
output wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_s_inf;
output wire [WRIT_NUMBER * 2 -1:0]             bresp_s_inf;
output wire [WRIT_NUMBER-1:0]                 bvalid_s_inf;
input wire [WRIT_NUMBER-1:0]                  bready_s_inf;
// ---------------------------------------------------------------
// axi read address channel 
input wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_s_inf;
input wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_s_inf;
input wire [DRAM_NUMBER * 7 -1:0]            arlen_s_inf;
input wire [DRAM_NUMBER * 3 -1:0]           arsize_s_inf;
input wire [DRAM_NUMBER * 2 -1:0]          arburst_s_inf;
input wire [DRAM_NUMBER-1:0]               arvalid_s_inf;
output wire [DRAM_NUMBER-1:0]              arready_s_inf;
// ---------------------------------------------------------------
// axi read data channel
output wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_s_inf;
output wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_s_inf;
output wire [DRAM_NUMBER * 2 -1:0]             rresp_s_inf;
output wire [DRAM_NUMBER-1:0]                  rlast_s_inf;
output wire [DRAM_NUMBER-1:0]                 rvalid_s_inf;
input wire [DRAM_NUMBER-1:0]                  rready_s_inf;
// ---------------------------------------------------------------
//================================================================
//  integer
//================================================================
integer color_stage = 0, color, r = 5, g = 0, b = 0;
integer patcount, golden_pc, golden_curr_pc, cycles, total_cycles, offset=16'h1000;
integer i, j, temp_address_int;
//================================================================
//   Wires & Registers 
//================================================================
reg signed [15:0] golden_reg[0:15];
reg signed [15:0] golden_DRAM_data[0:2047];
// 
reg [15:0] golden_inst;
reg [2:0] golden_opcode;
reg [3:0] golden_rs, golden_rt, golden_rd;
reg golden_func;
reg signed [4:0] golden_immediate;
reg [15:0] golden_address;
reg [15:0] temp_address;
//================================================================
//  clock
//================================================================
always  #(`CYCLE_TIME/2.0)  clk = ~clk ;
initial clk = 0 ;
//================================================================
//   DRAM 
//================================================================
pseudo_DRAM_data u_DRAM_data(
// global signals 
      .clk(clk),
      .rst_n(rst_n),
// axi write address channel 
      .awid_s_inf(   awid_s_inf[3:0]  ),
    .awaddr_s_inf( awaddr_s_inf[31:0] ),
    .awsize_s_inf( awsize_s_inf[2:0]  ),
   .awburst_s_inf(awburst_s_inf[1:0]  ),
     .awlen_s_inf(  awlen_s_inf[6:0]  ),
   .awvalid_s_inf(awvalid_s_inf[0]    ),
   .awready_s_inf(awready_s_inf[0]    ),
// axi write data channel 
     .wdata_s_inf(  wdata_s_inf[15:0] ),
     .wlast_s_inf(  wlast_s_inf[0]    ),
    .wvalid_s_inf( wvalid_s_inf[0]    ),
    .wready_s_inf( wready_s_inf[0]    ),
// axi write response channel
       .bid_s_inf(    bid_s_inf[3:0]  ),
     .bresp_s_inf(  bresp_s_inf[1:0]  ),
    .bvalid_s_inf( bvalid_s_inf[0]    ),
    .bready_s_inf( bready_s_inf[0]    ),
// axi read address channel 
      .arid_s_inf(   arid_s_inf[3:0]  ),
    .araddr_s_inf( araddr_s_inf[31:0] ),
     .arlen_s_inf(  arlen_s_inf[6:0]  ),
    .arsize_s_inf( arsize_s_inf[2:0]  ),
   .arburst_s_inf(arburst_s_inf[1:0]  ),
   .arvalid_s_inf(arvalid_s_inf[0]    ),
   .arready_s_inf(arready_s_inf[0]    ), 
// axi read data channel 
       .rid_s_inf(    rid_s_inf[3:0]  ),
     .rdata_s_inf(  rdata_s_inf[15:0] ),
     .rresp_s_inf(  rresp_s_inf[1:0]  ),
     .rlast_s_inf(  rlast_s_inf[0]    ),
    .rvalid_s_inf( rvalid_s_inf[0]    ),
    .rready_s_inf( rready_s_inf[0]    ) 
);

pseudo_DRAM_inst u_DRAM_inst(
// global signals 
      .clk(clk),
      .rst_n(rst_n),
// axi read address channel 
      .arid_s_inf(   arid_s_inf[7:4]   ),
    .araddr_s_inf( araddr_s_inf[63:32] ),
    .arlen_s_inf(  arlen_s_inf[13:7]   ),
    .arsize_s_inf( arsize_s_inf[5:3]   ),
   .arburst_s_inf(arburst_s_inf[3:2]   ),
   .arvalid_s_inf(arvalid_s_inf[1]     ),
   .arready_s_inf(arready_s_inf[1]     ), 
// axi read data channel 
       .rid_s_inf(    rid_s_inf[7:4]   ),
     .rdata_s_inf(  rdata_s_inf[31:16] ),
     .rresp_s_inf(  rresp_s_inf[3:2]   ),
     .rlast_s_inf(  rlast_s_inf[1]     ),
    .rvalid_s_inf( rvalid_s_inf[1]     ),
    .rready_s_inf( rready_s_inf[1]     ) 
);
//================================================================
//  initial
//================================================================
initial begin
    rst_n = 1 ;
    // reset
    force clk = 0 ;
    // SPEC: There is only 1 reset before the first pattern, thus, your design must be able to reset automatically. 
    reset_task;
    read_DRAM_data_task;
    total_cycles = 0 ;
    //
    @(negedge clk);
    golden_pc = 16'h1000 - 2 ;
    for( patcount=1 ; patcount<=1000 ; patcount=patcount+1 ) begin
        // 
        golden_pc = golden_pc + 2 ;
        golden_curr_pc = golden_pc ;
        golden_inst = { u_DRAM_inst.DRAM_r[golden_curr_pc+1] , u_DRAM_inst.DRAM_r[golden_curr_pc] } ;
        // $display("DRAM_inst @%2x : %4x", golden_curr_pc, golden_inst);
        golden_opcode  = golden_inst[15:13] ;
        golden_rs      = golden_inst[12:9] ;
        golden_rt      = golden_inst[8:5] ;
        golden_rd      = golden_inst[4:1] ;
        golden_func    = golden_inst[0] ;
        golden_immediate = golden_inst[4:0] ;
        golden_address = golden_inst[12:0];     // automatically pad '000' in front
        // 
        // $display("golden_opcode   = %3b", golden_opcode  );
        // $display("golden_rs       = %d", golden_rs      );
        // $display("golden_rt       = %d", golden_rt      );
        // $display("golden_rd       = %d", golden_rd      );
        // $display("golden_func     = %b", golden_func    );
        // $display("golden_immediate = %d", golden_immediate);
        // $display("golden_address  = %4x", golden_address );
        // 
        temp_address = (golden_reg[golden_rs]+golden_immediate)*2 + offset ;
        temp_address_int = (temp_address - 16'h1000 )/2 ;
        // 
        if (golden_opcode===3'b000 && golden_func===1'b0)
            Add_task;
        else if (golden_opcode===3'b000 && golden_func===1'b1)
            Sub_task;
        else if (golden_opcode===3'b001 && golden_func===1'b0)
            SetLessThan_task;
        else if (golden_opcode===3'b001 && golden_func===1'b1)
            Mult_task;
        else if (golden_opcode===3'b010)
            Load_task;
        else if (golden_opcode===3'b011)
            Store_task;
        else if (golden_opcode===3'b100)
            BranchOnEqual_task;
        else if (golden_opcode===3'b101)
            Jump_task;
        else begin
            $display("Error: Wrong instruection format in PATTERN NO.%4d\t\tgolden_pc NO.%4x", patcount+1, golden_curr_pc);
            $display("%16b", golden_inst);
        end
        // SPEC: The test pattern will check the value in all registers at clock negative edge if stall is low. 
        wait_IO_stall_task;
        // 
        case(color_stage)
            0: begin
                r = r - 1;
                g = g + 1;
                if(r == 0) color_stage = 1;
            end
            1: begin
                g = g - 1;
                b = b + 1;
                if(g == 0) color_stage = 2;
            end
            2: begin
                b = b - 1;
                r = r + 1;
                if(b == 0) color_stage = 0;
            end
        endcase
        color = 16 + r*36 + g*6 + b;
        if(color < 100) $display("\033[38;5;%2dmPASS\tPATTERN NO.%4d\t\tgolden_pc NO.%4x\033[00m\n", color, patcount, golden_curr_pc);
        else $display("\033[38;5;%3dmPASS\tPATTERN NO.%4d\t\tgolden_pc NO.%4x\033[00m\n", color, patcount, golden_curr_pc);
        // print_reg_task;
    end
    YOU_PASS_task;
    $finish;
end
//================================================================
//  check task
//================================================================
task wait_IO_stall_task ; begin
    cycles = 0 ;
    while(IO_stall===1) begin
        cycles = cycles + 1 ;
        if (cycles==`MAX_WAIT_READY_CYCLE) begin
            fail;
            // Spec. 6.  
            // IO_stall signal cannot be continuous high for 2000 cycles during functionality check, 
            // cannot be continuous high for 100000 during performance check. 
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                SPEC 6 FAIL!                                                                ");
            $display ("                                          The execution latency is limited in %d cycles.                                                    ", `MAX_WAIT_READY_CYCLE);
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            #(100);
            $finish;
        end
        @(negedge clk);        
    end
    total_cycles = total_cycles + cycles ;
    // 
    check_reg_task;
    // SPEC: The test pattern will check the value in data DRAM every 10 instruction at clock negative edge if IO_stall is low. 
    if (patcount%10==0)
        check_DRAM_data_task;
    // SPEC: Pull high when core is busy. It should be low for one cycle whenever  you  finished  an  instruction.
    @(negedge clk);
    if (IO_stall===0) begin
        fail;
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                SPEC ? FAIL!                                                                ");
        $display ("                                 IO_stall should be low for ONE cycle whenever you finished an instruction.                                 ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        #(100);
        $finish;
    end
end endtask

task check_reg_task ; begin
    print_reg_task;
    if( My_CPU.core_r0!==golden_reg[0] || My_CPU.core_r4!==golden_reg[4] || My_CPU.core_r8 !==golden_reg[ 8] || My_CPU.core_r12!==golden_reg[12] ||
        My_CPU.core_r1!==golden_reg[1] || My_CPU.core_r5!==golden_reg[5] || My_CPU.core_r9 !==golden_reg[ 9] || My_CPU.core_r13!==golden_reg[13] ||
        My_CPU.core_r2!==golden_reg[2] || My_CPU.core_r6!==golden_reg[6] || My_CPU.core_r10!==golden_reg[10] || My_CPU.core_r14!==golden_reg[14] ||
        My_CPU.core_r3!==golden_reg[3] || My_CPU.core_r7!==golden_reg[7] || My_CPU.core_r11!==golden_reg[11] || My_CPU.core_r15!==golden_reg[15]) begin
        fail;
        $display ("--------------------------------------------------------------------------------------------");
        $display ("                                           FAIL!                                            ");
        $display ("                                 core_reg is/are not equal.                                 ");        
        print_reg_task;
        $display ("--------------------------------------------------------------------------------------------");
        #(100);
        $finish; 
    end
end endtask

task check_DRAM_data_task ; begin
    j = 0 ;
    for( i=16'h1000 ; i<16'h2000 ; i=i+2 ) begin
        if (golden_DRAM_data[j]!=={ u_DRAM_data.DRAM_r[i+1] , u_DRAM_data.DRAM_r[i] }) begin
            fail;
            $display ("--------------------------------------------------------------------------------------------");
            $display ("                                           FAIL!                                            ");
            $display ("                                 DRAM_data is/are not equal.                                ");        
            $display ("      golden_DRAM_data[%4h(%4d)]: %4x(%8d) , your_DRAM_data[%4h(%4d)]: %4x(%8d)               ", i, j, golden_DRAM_data[j], golden_DRAM_data[j], i, j, { u_DRAM_data.DRAM_r[i+1] , u_DRAM_data.DRAM_r[i] }, { u_DRAM_data.DRAM_r[i+1] , u_DRAM_data.DRAM_r[i] });        
            $display ("--------------------------------------------------------------------------------------------");
            #(100);
            // $finish; 
        end
        j = j + 1 ;
    end
end endtask

task print_reg_task ; begin
    $display ("      core_r0 = %4d  golden_reg[0] = %4d  ,  core_r8  = %4d  golden_reg[8 ] = %4d    ", My_CPU.core_r0,  golden_reg[0], My_CPU.core_r8 , golden_reg[8 ]);
    $display ("      core_r1 = %4d  golden_reg[1] = %4d  ,  core_r9  = %4d  golden_reg[9 ] = %4d    ", My_CPU.core_r1,  golden_reg[1], My_CPU.core_r9 , golden_reg[9 ]);
    $display ("      core_r2 = %4d  golden_reg[2] = %4d  ,  core_r10 = %4d  golden_reg[10] = %4d    ", My_CPU.core_r2,  golden_reg[2], My_CPU.core_r10, golden_reg[10]);
    $display ("      core_r3 = %4d  golden_reg[3] = %4d  ,  core_r11 = %4d  golden_reg[11] = %4d    ", My_CPU.core_r3,  golden_reg[3], My_CPU.core_r11, golden_reg[11]);
    $display ("      core_r4 = %4d  golden_reg[4] = %4d  ,  core_r12 = %4d  golden_reg[12] = %4d    ", My_CPU.core_r4,  golden_reg[4], My_CPU.core_r12, golden_reg[12]);
    $display ("      core_r5 = %4d  golden_reg[5] = %4d  ,  core_r13 = %4d  golden_reg[13] = %4d    ", My_CPU.core_r5,  golden_reg[5], My_CPU.core_r13, golden_reg[13]);
    $display ("      core_r6 = %4d  golden_reg[6] = %4d  ,  core_r14 = %4d  golden_reg[14] = %4d    ", My_CPU.core_r6,  golden_reg[6], My_CPU.core_r14, golden_reg[14]);
    $display ("      core_r7 = %4d  golden_reg[7] = %4d  ,  core_r15 = %4d  golden_reg[15] = %4d    ", My_CPU.core_r7,  golden_reg[7], My_CPU.core_r15, golden_reg[15]);
end endtask
//================================================================
//  CPU task
//================================================================
task Add_task ; begin
    $display("Add_task");
    golden_reg[golden_rd] = golden_reg[golden_rs] + golden_reg[golden_rt] ;
end endtask

task Sub_task ; begin
    $display("Sub_task");
    golden_reg[golden_rd] = golden_reg[golden_rs] - golden_reg[golden_rt] ;
end endtask

task SetLessThan_task ; begin
    $display("SetLessThan_task");
    if (golden_reg[golden_rs]<golden_reg[golden_rt])
        golden_reg[golden_rd] = 1 ;
    else 
        golden_reg[golden_rd] = 0 ;
end endtask

task Mult_task ; begin
    $display("Mult_task");
    golden_reg[golden_rd] = golden_reg[golden_rs] * golden_reg[golden_rt] ;
end endtask

task Load_task ; begin
    $display("Load_task");
    golden_reg[golden_rt] = golden_DRAM_data[temp_address_int];
end endtask

task Store_task ; begin
    $display("Store_task");
    golden_DRAM_data[temp_address_int] = golden_reg[golden_rt] ;
end endtask

task BranchOnEqual_task ; begin
    $display("BranchOnEqual_task");
    if (golden_reg[golden_rs]===golden_reg[golden_rt])
        golden_pc = golden_curr_pc + golden_immediate*2 ;        
end endtask

task Jump_task ; begin
    $display("Jump_task");
    golden_pc = golden_address - 2 ;
end endtask
//================================================================
//  env task
//================================================================
task read_DRAM_data_task ; begin
    j = 0 ;
    for( i=16'h1000 ; i<16'h2000 ; i=i+2 ) begin
        golden_DRAM_data[j] = { u_DRAM_data.DRAM_r[i+1] , u_DRAM_data.DRAM_r[i] } ;
        // $display("%x(%4d): %4x", i, j, golden_DRAM_data[j]);
        j = j + 1 ;
    end
end endtask

task reset_task ; begin
    #(5); rst_n = 0 ;
    // SPEC: All the registers should be zero after the reset signal is asserted. 
    #(5);
    for( i=0 ; i<16 ; i=i+1 )
        golden_reg[i] = 0 ;
    check_reg_task;
    // 
    #(10); rst_n = 1 ; 
    #(100); release clk;
end endtask

//================================================================
//  pass/fail task0
//================================================================
task YOU_PASS_task ; begin
$display ("----------------------------------------------------------------------------------------------------------------------");
$display ("                                                  Congratulations!                                                    ");
$display ("                                           You have passed all patterns!                                              ");
$display ("                                                                                                                      ");
$display ("                                        Your execution cycles   = %5d cycles                                          ", total_cycles);
$display ("                                        Your clock period       = %.1f ns                                             ", `CYCLE_TIME);
$display ("                                        Total latency           = %.1f ns                                             ", total_cycles*`CYCLE_TIME );
$display ("----------------------------------------------------------------------------------------------------------------------");
$finish;    
end endtask

task fail ; begin
$display(":( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( ");
end endtask

endmodule

