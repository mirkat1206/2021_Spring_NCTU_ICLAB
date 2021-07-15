//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Midterm Project: Advanced Microcontroller Bus Architecture (AMBA)
//   Author         : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifdef RTL
`define CYCLE_TIME 20
`endif
`ifdef GATE
`define CYCLE_TIME 20
`endif

`ifdef FUNC
`define PAT_NUM 10
`endif
`ifdef PERF
`define PAT_NUM 10
`endif

`include "../00_TESTBED/MEM_MAP_define.v"
`include "../00_TESTBED/pseudo_DRAM1.v"
`include "../00_TESTBED/pseudo_DRAM_read.v"

module PATTERN #(parameter ID_WIDTH=4, DATA_WIDTH=32, ADDR_WIDTH=32, DRAM_NUMBER=2, WRIT_NUMBER=1)(
// global signals 
        clk,  
        rst_n,  
// APB channel 
        PADDR,
       PRDATA,
        PSELx, 
      PENABLE, 
       PWRITE, 
       PREADY,  
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
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
// ---------------------------------------------------------------
// global signals 
output reg  clk, rst_n;
// ---------------------------------------------------------------
// APB channel 
output reg [ADDR_WIDTH-1:0] PADDR;
input wire [DATA_WIDTH-1:0] PRDATA;
output reg                  PSELx;
output reg                  PENABLE;
output reg                  PWRITE;
input wire                  PREADY;
// ---------------------------------------------------------------
// axi write address channel 
input wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_s_inf;
input wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_s_inf;
input wire [WRIT_NUMBER * 3 -1:0]            awsize_s_inf;
input wire [WRIT_NUMBER * 2 -1:0]           awburst_s_inf;
input wire [WRIT_NUMBER * 4 -1:0]             awlen_s_inf;
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
input wire [DRAM_NUMBER * ID_WIDTH-1:0]         arid_s_inf;
input wire [DRAM_NUMBER * ADDR_WIDTH-1:0]     araddr_s_inf;
input wire [DRAM_NUMBER * 4 -1:0]              arlen_s_inf;
input wire [DRAM_NUMBER * 3 -1:0]             arsize_s_inf;
input wire [DRAM_NUMBER * 2 -1:0]            arburst_s_inf;
input wire [DRAM_NUMBER-1:0]                 arvalid_s_inf;
output wire [DRAM_NUMBER-1:0]                arready_s_inf;
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
integer i, j, k, m, cycles, total_cycles, pat_file, gap;
integer idx, temp;
integer PATNUM, patcount, lala;
integer color_stage = 0, color, r = 5, g = 0, b = 0;
//================================================================
//   Wires & Registers 
//================================================================
reg [31:0] instruction;
reg [15:0] DRAM1_addr, DRAM_read_addr;
reg [1:0] op_code;
reg [31:0] matrix_A[0:17][0:17], matrix_B[1:16][1:16], golden_matrix[1:16][1:16];
//================================================================
//  clock
//================================================================
always  #(`CYCLE_TIME/2.0)  clk = ~clk ;
initial clk = 0 ;
//================================================================
//   DRAM 
//================================================================
pseudo_DRAM1 u_DRAM1(
// global signals 
      .clk(clk),
      .rst_n(rst_n),
// axi write address channel 
   .   awid_s_inf(   awid_s_inf[3:0]  ),
   . awaddr_s_inf( awaddr_s_inf[31:0] ),
   . awsize_s_inf( awsize_s_inf[2:0]  ),
   .awburst_s_inf(awburst_s_inf[1:0]  ),
   .  awlen_s_inf(  awlen_s_inf[3:0]  ),
   .awvalid_s_inf(awvalid_s_inf[0]    ),
   .awready_s_inf(awready_s_inf[0]    ),
// axi write data channel 
   .  wdata_s_inf(  wdata_s_inf[31:0] ),
   .  wlast_s_inf(  wlast_s_inf[0]    ),
   . wvalid_s_inf( wvalid_s_inf[0]    ),
   . wready_s_inf( wready_s_inf[0]    ),
// axi write response channel
   .    bid_s_inf(    bid_s_inf[3:0]  ),
   .  bresp_s_inf(  bresp_s_inf[1:0]  ),
   . bvalid_s_inf( bvalid_s_inf[0]    ),
   . bready_s_inf( bready_s_inf[0]    ),
// axi read address channel 
   .   arid_s_inf(   arid_s_inf[3:0]  ),
   . araddr_s_inf( araddr_s_inf[31:0] ),
   .  arlen_s_inf(  arlen_s_inf[3:0]  ),
   . arsize_s_inf( arsize_s_inf[2:0]  ),
   .arburst_s_inf(arburst_s_inf[1:0]  ),
   .arvalid_s_inf(arvalid_s_inf[0]    ),
   .arready_s_inf(arready_s_inf[0]    ), 
// axi read data channel 
   .    rid_s_inf(    rid_s_inf[3:0]  ),
   .  rdata_s_inf(  rdata_s_inf[31:0] ),
   .  rresp_s_inf(  rresp_s_inf[1:0]  ),
   .  rlast_s_inf(  rlast_s_inf[0]    ),
   . rvalid_s_inf( rvalid_s_inf[0]    ),
   . rready_s_inf( rready_s_inf[0]    ) 
);

pseudo_DRAM_read u_DRAM_read(
// global signals 
      .clk(clk),
      .rst_n(rst_n),
  // axi write address channel 
  // .   awid_s_inf(   awid_s_inf[7:4]  ),
  // . awaddr_s_inf( awaddr_s_inf[63:32]),
  // . awsize_s_inf( awsize_s_inf[5:3]  ),
  // .awburst_s_inf(awburst_s_inf[3:2]  ),
  // .  awlen_s_inf(  awlen_s_inf[7:4]  ),
  // .awvalid_s_inf(awvalid_s_inf[1]    ),
  // .awready_s_inf(awready_s_inf[1]    ),
  // axi write data channel 
  // .  wdata_s_inf(  wdata_s_inf[63:32]),
  // .  wlast_s_inf(  wlast_s_inf[1]    ),
  // . wvalid_s_inf( wvalid_s_inf[1]    ),
  // . wready_s_inf( wready_s_inf[1]    ),
  // axi write response channel
  // .    bid_s_inf(    bid_s_inf[7:4]  ),
  // .  bresp_s_inf(  bresp_s_inf[3:2]  ),
  // . bvalid_s_inf( bvalid_s_inf[1]    ),
  // . bready_s_inf( bready_s_inf[1]    ),
// axi read address channel 
   .   arid_s_inf(   arid_s_inf[7:4]   ),
   . araddr_s_inf( araddr_s_inf[63:32] ),
   .  arlen_s_inf(  arlen_s_inf[7:4]   ),
   . arsize_s_inf( arsize_s_inf[5:3]   ),
   .arburst_s_inf(arburst_s_inf[3:2]   ),
   .arvalid_s_inf(arvalid_s_inf[1]     ),
   .arready_s_inf(arready_s_inf[1]     ), 
// axi read data channel 
   .    rid_s_inf(    rid_s_inf[7:4]   ),
   .  rdata_s_inf(  rdata_s_inf[63:32] ),
   .  rresp_s_inf(  rresp_s_inf[3:2]   ),
   .  rlast_s_inf(  rlast_s_inf[1]     ),
   . rvalid_s_inf( rvalid_s_inf[1]     ),
   . rready_s_inf( rready_s_inf[1]     ) 
);
//================================================================
//  initial
//================================================================
initial begin
    rst_n = 1 ;
    // reset
    force clk = 0 ;
    total_cycles = 0 ;
    reset_task;
    // 
    @(negedge clk);
    for( patcount=16'h1004 ; patcount<16'h1fff ; patcount=patcount+4 ) begin
    // for( lala=0 ; lala<5 ; lala=lala+1 ) begin
        // patcount = 16'h1000 ;
        APB_setup_task;
        calculate_task;
        APB_wait_task;
        DRAM_check_task;
        // APB_reset_task;
        delay_task;
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
        if(color < 100) $display("\033[38;5;%2dmPASS PATTERN NO.%4h\033[00m", color, patcount);
        else $display("\033[38;5;%3dmPASS PATTERN NO.%4h\033[00m", color, patcount);
    end
    $finish;
end
//================================================================
//  check task
//================================================================
task calculate_task ; begin
  // calculate correct answer
    DRAM1_addr = { instruction[31:18] , 2'b00 } ;
    DRAM_read_addr = { instruction[15: 2] , 2'b00 } ;
    op_code = instruction[1:0] ;
    // debug
    /*$display("patcount       = %h", patcount);
    $display("PADDR          = %h", PADDR);
    $display("instruction    = %h", instruction);
    $display("DRAM1_addr     = %h", DRAM1_addr);
    $display("DRAM_read_addr = %h", DRAM_read_addr);
    $display("op_code        = %b", op_code);*/
    // read
    read_matrix_A_task;
    read_matrix_B_task;
    // calculate
    if (op_code==2'b00)       Multiplication_task;
    else if (op_code==2'b11)  Convolution_task;
    else begin
        $display("wrong op_code at PATTERN NO.%h", patcount);
        $finish;
    end
end endtask

task DRAM_check_task ; begin
if (PREADY===1'b1) begin
    // compare
    $display();
    for( i=1 ; i<=16 ; i=i+1 ) begin
        for( j=1 ; j<=16 ; j=j+1 ) begin
            idx =  4*( (i-1)*16 + (j-1) ) ;
            temp = { u_DRAM1.DRAM_r[ DRAM1_addr+idx+3 ] , u_DRAM1.DRAM_r[ DRAM1_addr+idx+2 ] , u_DRAM1.DRAM_r[ DRAM1_addr+idx+1 ] , u_DRAM1.DRAM_r[ DRAM1_addr+idx ] } ;
            // $write("%3d  ", temp );

            if ( temp!=golden_matrix[i][j] || PRDATA!==instruction ) begin
                fail;
                // Spec
                // When both PENABLE and PREADY signal are high, pattern will check the DRAM1 data and the PRDATA
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                $display ("                                                                SPEC FAIL!                                                                  ");
                $display ("                                               instruction = %h , PRDATA = %h                              ", instruction, PRDATA);
                $display ("                                         No.%4d : golden_matrix = %11d , u_DRAM1[%h] = %11d                                                  ", (i-1)*16+(j-1)+1, golden_matrix[i][j], DRAM1_addr+(i-1)*16+(j-1), temp);
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                repeat(5)  @(negedge clk);
                $finish;
            end
        end
        // $display();
    end
    APB_reset_task;   // pdf last page
    @(negedge clk);
    if (PREADY===1) begin
        fail;
        // Spec
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                SPEC FAIL!                                                                  ");
        $display ("                                                     PREADY last more than one cycle                                                        ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        repeat(5)  @(negedge clk);
        $finish;  
    end
end
else begin
    fail;
    // Spec
    $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
    $display ("                                                                SPEC FAIL!                                                                  ");
    $display ("                                              unexpecttedt PREADY value = %b                                                                ", PREADY );
    $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
    repeat(5)  @(negedge clk);
    $finish;
end
end endtask

task Multiplication_task ; begin
    for( i=1 ; i<=16 ; i=i+1 ) begin
        for( j=1 ; j<=16 ; j=j+1 ) begin
            temp = 0 ;
            for( k=1 ; k<=16 ; k=k+1 )
                temp = temp + matrix_A[i][k]*matrix_B[k][j] ;
            golden_matrix[i][j] = temp ;
            // $write("%3d  ", golden_matrix[i][j] );
        end
        // $display();
    end
end endtask

task Convolution_task ; begin
    for( i=1 ; i<=16 ; i=i+1 ) begin
        for( j=1 ; j<=16 ; j=j+1 ) begin
            temp = 0 ;
            for( k=1 ; k<=3 ; k=k+1 ) begin
                for( m=1 ; m<=3 ; m=m+1 )
                    temp = temp + matrix_A[i-2+k][j-2+m]*matrix_B[k][m] ;
            end
            golden_matrix[i][j] = temp ;
            // $write("%3d  ", golden_matrix[i][j] );
        end
        // $display();
    end
end endtask

task read_matrix_A_task ; begin
    for( i=1 ; i<=16 ; i=i+1 ) begin
        for( j=1 ; j<=16 ; j=j+1 ) begin
            idx = 4*( (i-1)*16 + (j-1) ) ;
            matrix_A[i][j] = { u_DRAM1.DRAM_r[DRAM1_addr+idx+3] , u_DRAM1.DRAM_r[DRAM1_addr+idx+2] , u_DRAM1.DRAM_r[DRAM1_addr+idx+1] , u_DRAM1.DRAM_r[DRAM1_addr+idx] } ;
            // $write("%4h:%3d  ", DRAM1_addr+idx, matrix_A[i][j] );
            // $write("%3d  ", matrix_A[i][j] );
        end
        // $display();
    end
    // $display();
end endtask

task read_matrix_B_task ; begin
    if (op_code==2'b00) begin     // op_code==2'b00 : multiplication
        for( i=1 ; i<=16 ; i=i+1 ) begin
            for( j=1 ; j<=16 ; j=j+1 ) begin
                idx = 4*( (i-1)*16 + (j-1) ) ;
                matrix_B[i][j] = { u_DRAM_read.DRAM_r[DRAM_read_addr+idx+3] , u_DRAM_read.DRAM_r[DRAM_read_addr+idx+2] , u_DRAM_read.DRAM_r[DRAM_read_addr+idx+1] , u_DRAM_read.DRAM_r[DRAM_read_addr+idx] } ;
                // $write("%4h:%3d  ", DRAM_read_addr+idx, matrix_B[i][j] );
                // $write("%3d  ", matrix_B[i][j] );
            end
            // $display();
        end
    end
    else if (op_code==2'b11) begin  // op_code==2'b11 : convolution
        for( i=1 ; i<=3 ; i=i+1 ) begin
            for( j=1 ; j<=3 ; j=j+1 ) begin
                idx = 4*( (i-1)*3 + (j-1) ) ;
                matrix_B[i][j] = { u_DRAM_read.DRAM_r[DRAM_read_addr+idx+3] , u_DRAM_read.DRAM_r[DRAM_read_addr+idx+2] , u_DRAM_read.DRAM_r[DRAM_read_addr+idx+1] , u_DRAM_read.DRAM_r[DRAM_read_addr+idx] } ;
                // $write("%4h: %3d  ", DRAM_read_addr+idx, matrix_B[i][j] );
                // $write("%3d  ", matrix_B[i][j] );
            end
            // $display();
        end
    end
    // $display();
end endtask
//================================================================
//  APB task
//================================================================
task APB_reset_task ; begin
    PADDR   = 'd0 ;
    PWRITE  = 1'b1 ;
    PSELx   = 1'd0 ;
    PENABLE = 1'd0 ;
end endtask

task APB_setup_task ; begin
    PADDR = patcount ;
    instruction = { u_DRAM_read.DRAM_r[patcount+3] , u_DRAM_read.DRAM_r[patcount+2] , u_DRAM_read.DRAM_r[patcount+1] , u_DRAM_read.DRAM_r[patcount] };
    PWRITE  = 1'b0 ;
    PSELx   = 1'b1 ; 
    @(negedge clk);
end endtask

task APB_wait_task ; begin
    PENABLE = 1'b1 ;
    cycles = 0 ;
    while(PREADY!==1'b1) begin
        cycles = cycles + 1 ;
        if (cycles==100000) begin
            fail;
            // Spec. 4
            // The latency of your design (latency between PENABLE and PREADY) in each pattern should not be larger than 100,000 cycles. (during functionality test) 
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                SPEC 4 FAIL!                                                                ");
            $display ("                                            The execution latency is limited in 100000 cycles.                                              ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            repeat(5)  @(negedge clk);
            $finish;
        end
        @(negedge clk);
    end
end endtask
//================================================================
//  env task
//================================================================
task reset_task ; begin
    #(10); rst_n = 0 ;
    APB_reset_task;
    for( i=0 ; i<=17 ; i=i+1 )
        for( j=0 ; j<=17 ; j=j+1 )
            matrix_A[i][j] = 0 ;
    for( i=1 ; i<=16 ; i=i+1 )
        for( j=1 ; j<=16 ; j=j+1 )
            matrix_B[i][j] = 0 ;
    #(10); rst_n = 1 ; 
    #(100); release clk;
end endtask

task delay_task ; begin
    gap = $urandom_range(1, 3) ;
    repeat(gap) @(negedge clk);
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



