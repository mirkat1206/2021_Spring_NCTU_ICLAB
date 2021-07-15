//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Final Project: Customized ISA Processor (CPU)
//   Author       : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : CPU.v
//   Module Name : CPU
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module CPU(
// global signals 
                clk,
              rst_n,
           IO_stall,
// axi write address channel 
         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
// axi write data channel                     
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
// axi write response channel
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
// axi read address channel                     
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
      arready_m_inf, 
// axi read data channel                    
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 
);
//================================================================
//  PORT DECLARATION
//================================================================
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;
// ---------------------------------------------------------------
// global signals
input  wire clk, rst_n;
output reg  IO_stall;
// ---------------------------------------------------------------
// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// ---------------------------------------------------------------
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// ---------------------------------------------------------------
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]                 bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// ---------------------------------------------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// ---------------------------------------------------------------
// axi read data channel
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// ---------------------------------------------------------------
//================================================================
//  integer / genvar / parameter
//================================================================
// 
parameter signed OFFSET = 16'h1000 ;
// 
integer i;
genvar idx;
//  FSM
/*
ADD           : S_INST_FETCH --> S_INST_DECODE --> S_EXECUTE --> S_WRITE_BACK --> S_INST_FETCH
SUB           : S_INST_FETCH --> S_INST_DECODE --> S_EXECUTE --> S_WRITE_BACK --> S_INST_FETCH
SetLessThan   : S_INST_FETCH --> S_INST_DECODE --> S_EXECUTE --> S_WRITE_BACK --> S_INST_FETCH
Mult          : S_INST_FETCH --> S_INST_DECODE --> S_EXECUTE --> S_WRITE_BACK --> S_INST_FETCH
Load          : S_INST_FETCH --> S_INST_DECODE --> S_EXECUTE --> S_DATA_LOAD  --> S_INST_FETCH
Store         : S_INST_FETCH --> S_INST_DECODE --> S_EXECUTE --> S_DATA_STORE --> S_INST_FETCH
BranchOnEqual : S_INST_FETCH --> S_INST_DECODE --> S_EXECUTE --> S_INST_FETCH
Jump          : S_INST_FETCH --> S_INST_DECODE --> S_EXECUTE --> S_INST_FETCH
*/
parameter S_IDLE = 3'd7 ;
parameter S_INST_FETCH  = 3'd0 ; 
parameter S_INST_DECODE = 3'd1 ;
parameter S_EXECUTE     = 3'd2 ;
parameter S_WRITE_BACK  = 3'd3 ;
parameter S_DATA_LOAD   = 3'd4 ;
parameter S_DATA_STORE  = 3'd5 ;
//================================================================
//   Wires & Registers 
//================================================================
// 
reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;
//  FSM
reg [2:0] curr_state, next_state;
// 
wire [15:0] inst, data;
wire [2:0] opcode;
wire [3:0] rs, rt, rd;
wire func;
wire signed [4:0] imm;
wire [15:0] address;
// 
reg signed [15:0] curr_pc, next_pc;
reg signed [15:0] rs_data, rt_data, rd_data;
wire signed [15:0] data_addr;
// 
reg in_valid_inst;
wire out_valid_inst;
//
reg in_valid_data;
wire out_valid_data;
//
reg in_valid_data_write;
wire out_finish_data;
//================================================================
//  FSM
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   curr_state <= S_IDLE ;
    else          curr_state <= next_state ;
end
always @(*) begin
    next_state = curr_state ;
    case(curr_state)
        S_IDLE:   next_state = S_INST_FETCH ;
        S_INST_FETCH:   if (out_valid_inst==1)    next_state = S_INST_DECODE ;
        S_INST_DECODE:  next_state = S_EXECUTE ;
        S_EXECUTE: begin
            if (opcode==3'b010)         next_state = S_DATA_LOAD ;
            else if (opcode==3'b011)    next_state = S_DATA_STORE ;
            else if (opcode[2]==1'b1)   next_state = S_INST_FETCH ;
            else                        next_state = S_WRITE_BACK ;
        end
        S_DATA_LOAD:  if (out_valid_data==1)    next_state = S_INST_FETCH ;
        S_DATA_STORE: if (out_finish_data==1)   next_state = S_INST_FETCH ;
        S_WRITE_BACK:   next_state = S_INST_FETCH ;
    endcase
end
//================================================================
//  DRAM_inst : Read Channel
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   in_valid_inst <= 0 ;
    else begin
        if (next_state==S_INST_FETCH && curr_state!=S_INST_FETCH)   in_valid_inst <= 1 ;
        else      in_valid_inst <= 0 ;
    end
end

r_DRAM_inst r_DRAM_inst(
// global signals 
                .clk(clk),
              .rst_n(rst_n),
// input/output signals 
           .in_valid(in_valid_inst),
            .in_addr(curr_pc[11:1]),
          .out_valid(out_valid_inst),
           .out_inst(inst),
// axi read address channel                     
         .arid_m_inf(arid_m_inf[DRAM_NUMBER * ID_WIDTH-1:ID_WIDTH]),
       .araddr_m_inf(araddr_m_inf[DRAM_NUMBER * ADDR_WIDTH-1:ADDR_WIDTH]),
        .arlen_m_inf(arlen_m_inf[DRAM_NUMBER * 7 -1:7]),
       .arsize_m_inf(arsize_m_inf[DRAM_NUMBER * 3 -1:3]),
      .arburst_m_inf(arburst_m_inf[DRAM_NUMBER * 2 -1:2]),
      .arvalid_m_inf(arvalid_m_inf[1]),
      .arready_m_inf(arready_m_inf[1]), 
// axi read data channel                    
          .rid_m_inf(rid_m_inf[DRAM_NUMBER * ID_WIDTH-1:ID_WIDTH]),
        .rdata_m_inf(rdata_m_inf[DRAM_NUMBER * DATA_WIDTH-1:DATA_WIDTH]),
        .rresp_m_inf(rresp_m_inf[DRAM_NUMBER * 2 -1:2]),
        .rlast_m_inf(rlast_m_inf[1]),
       .rvalid_m_inf(rvalid_m_inf[1]),
       .rready_m_inf(rready_m_inf[1]) 
);
//================================================================
//  DRAM_data : Read Channel
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   in_valid_data <= 0 ;
    else begin
        if (next_state==S_DATA_LOAD && curr_state!=S_DATA_LOAD)         in_valid_data <= 1 ;
        else if (next_state==S_DATA_STORE && curr_state!=S_DATA_STORE)  in_valid_data <= 1 ;
        else      in_valid_data <= 0 ;
    end
end

assign data_addr = (rs_data+imm)*2 + OFFSET ;

r_DRAM_data r_DRAM_data(
// global signals 
                .clk(clk),
              .rst_n(rst_n),
// input/output signals 
           .in_valid(in_valid_data),
            .in_addr(data_addr[11:1]),
            .in_write(curr_state==S_DATA_STORE),
            .in_data(rt_data),
          .out_valid(out_valid_data),
           .out_data(data),
// axi read address channel                     
         .arid_m_inf(arid_m_inf[ID_WIDTH-1:0]),
       .araddr_m_inf(araddr_m_inf[ADDR_WIDTH-1:0]),
        .arlen_m_inf(arlen_m_inf[7 -1:0]),
       .arsize_m_inf(arsize_m_inf[3 -1:0]),
      .arburst_m_inf(arburst_m_inf[2 -1:0]),
      .arvalid_m_inf(arvalid_m_inf[0]),
      .arready_m_inf(arready_m_inf[0]), 
// axi read data channel                    
          .rid_m_inf(rid_m_inf[ID_WIDTH-1:0]),
        .rdata_m_inf(rdata_m_inf[DATA_WIDTH-1:0]),
        .rresp_m_inf(rresp_m_inf[2 -1:0]),
        .rlast_m_inf(rlast_m_inf[0]),
       .rvalid_m_inf(rvalid_m_inf[0]),
       .rready_m_inf(rready_m_inf[0]) 
);
//================================================================
//  DRAM_data : Write Channel
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   in_valid_data_write <= 0 ;
    else begin
        if (next_state==S_DATA_STORE && curr_state!=S_DATA_STORE)  in_valid_data_write <= 1 ;
        else      in_valid_data_write <= 0 ;
    end
end


w_DRAM_data w_DRAM_data(
// global signals 
                .clk(clk),
              .rst_n(rst_n),
// input/output signals 
           .in_valid(in_valid_data_write),
            .in_addr(data_addr[11:1]),
            .in_data(rt_data),
         .out_finish(out_finish_data),
// axi write address channel 
         .awid_m_inf(awid_m_inf),
       .awaddr_m_inf(awaddr_m_inf),
       .awsize_m_inf(awsize_m_inf),
      .awburst_m_inf(awburst_m_inf),
        .awlen_m_inf(awlen_m_inf),
      .awvalid_m_inf(awvalid_m_inf),
      .awready_m_inf(awready_m_inf),
// axi write data channel                     
        .wdata_m_inf(wdata_m_inf),
        .wlast_m_inf(wlast_m_inf),
       .wvalid_m_inf(wvalid_m_inf),
       .wready_m_inf(wready_m_inf),
// axi write response channel
          .bid_m_inf(bid_m_inf),
        .bresp_m_inf(bresp_m_inf),
       .bvalid_m_inf(bvalid_m_inf),
       .bready_m_inf(bready_m_inf)
);
//================================================================
//   DESIGN
//================================================================
// 
assign opcode = inst[15:13] ;
assign rs     = inst[12: 9] ;
assign rt     = inst[ 8: 5] ;
assign rd     = inst[ 4: 1] ;
assign func   = inst[0] ;
assign imm    = inst[ 4: 0] ;
assign address = { 3'b000 , inst[12:0] } ;
// 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)                         curr_pc <= OFFSET ;
    else if (next_state==S_EXECUTE)     curr_pc <= next_pc ;
end
always @(*) begin
    if (opcode==3'b101)     next_pc = address ;
    else if (opcode==3'b100) begin
        if (rs_data==rt_data)   next_pc = curr_pc + 2 + imm*2 ; //
        else                    next_pc = curr_pc + 2 ;
    end 
    else    next_pc = curr_pc +  2;
end
// 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     IO_stall <= 1 ;
    else begin
        if (curr_state!=S_IDLE) begin
            if (next_state==S_INST_FETCH && curr_state!=S_INST_FETCH)
                IO_stall <= 0 ;
            else 
                IO_stall <= 1 ;
        end
    end
end
// 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     rs_data <= 0 ;
    else begin
        if (next_state==S_INST_DECODE) begin
            case(rs)
                0:      rs_data <= core_r0  ;
                1:      rs_data <= core_r1  ;
                2:      rs_data <= core_r2  ;
                3:      rs_data <= core_r3  ;
                4:      rs_data <= core_r4  ;
                5:      rs_data <= core_r5  ;
                6:      rs_data <= core_r6  ;
                7:      rs_data <= core_r7  ;
                8:      rs_data <= core_r8  ;
                9:      rs_data <= core_r9  ;
                10:     rs_data <= core_r10 ; 
                11:     rs_data <= core_r11 ; 
                12:     rs_data <= core_r12 ; 
                13:     rs_data <= core_r13 ; 
                14:     rs_data <= core_r14 ; 
                15:     rs_data <= core_r15 ; 
            endcase
        end         
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     rt_data <= 0 ;
    else begin
        if (next_state==S_INST_DECODE) begin
            case(rt)
                0:      rt_data <= core_r0  ;
                1:      rt_data <= core_r1  ;
                2:      rt_data <= core_r2  ;
                3:      rt_data <= core_r3  ;
                4:      rt_data <= core_r4  ;
                5:      rt_data <= core_r5  ;
                6:      rt_data <= core_r6  ;
                7:      rt_data <= core_r7  ;
                8:      rt_data <= core_r8  ;
                9:      rt_data <= core_r9  ;
                10:     rt_data <= core_r10 ; 
                11:     rt_data <= core_r11 ; 
                12:     rt_data <= core_r12 ; 
                13:     rt_data <= core_r13 ; 
                14:     rt_data <= core_r14 ; 
                15:     rt_data <= core_r15 ; 
            endcase
        end         
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     rd_data <= 0 ;
    else begin
        if (next_state==S_EXECUTE) begin
            if (opcode==3'b000) begin
                if (func==0)    rd_data <= rs_data + rt_data ;  // ADD
                else            rd_data <= rs_data - rt_data ;  // SUB
            end
            else if (opcode==3'b001) begin
                if (func==0)    rd_data <= (rs_data<rt_data) ? 1 : 0 ;  // SetLessThan
                else            rd_data <= rs_data * rt_data ;  // Mult
            end
            else    rd_data <= 0 ;
        end
    end
end
//================================================================
//   CORE_REG
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   core_r0 <= 0 ;
    else begin
        if (next_state==S_WRITE_BACK && rd==0)  core_r0 <= rd_data ;
        else if (out_valid_data==1 && rt==0)    core_r0 <= data ;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   core_r1 <= 0 ;
    else begin
        if (next_state==S_WRITE_BACK && rd==1)  core_r1 <= rd_data ;
        else if (out_valid_data==1 && rt==1)    core_r1 <= data ;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   core_r2 <= 0 ;
    else begin
        if (next_state==S_WRITE_BACK && rd==2)  core_r2 <= rd_data ;
        else if (out_valid_data==1 && rt==2)    core_r2 <= data ;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   core_r3 <= 0 ;
    else begin
        if (next_state==S_WRITE_BACK && rd==3)  core_r3 <= rd_data ;
        else if (out_valid_data==1 && rt==3)    core_r3 <= data ;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   core_r4 <= 0 ;
    else begin
        if (next_state==S_WRITE_BACK && rd==4)  core_r4 <= rd_data ;
        else if (out_valid_data==1 && rt==4)    core_r4 <= data ;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   core_r5 <= 0 ;
    else begin
        if (next_state==S_WRITE_BACK && rd==5)  core_r5 <= rd_data ;
        else if (out_valid_data==1 && rt==5)    core_r5 <= data ;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   core_r6 <= 0 ;
    else begin
        if (next_state==S_WRITE_BACK && rd==6)  core_r6 <= rd_data ;
        else if (out_valid_data==1 && rt==6)    core_r6 <= data ;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   core_r7 <= 0 ;
    else begin
        if (next_state==S_WRITE_BACK && rd==7)  core_r7 <= rd_data ;
        else if (out_valid_data==1 && rt==7)    core_r7 <= data ;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   core_r8 <= 0 ;
    else begin
        if (next_state==S_WRITE_BACK && rd==8)  core_r8 <= rd_data ;
        else if (out_valid_data==1 && rt==8)    core_r8 <= data ;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   core_r9 <= 0 ;
    else begin
        if (next_state==S_WRITE_BACK && rd==9)  core_r9 <= rd_data ;
        else if (out_valid_data==1 && rt==9)    core_r9 <= data ;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   core_r10 <= 0 ;
    else begin
        if (next_state==S_WRITE_BACK && rd==10)  core_r10 <= rd_data ;
        else if (out_valid_data==1 && rt==10)    core_r10 <= data ;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   core_r11 <= 0 ;
    else begin
        if (next_state==S_WRITE_BACK && rd==11)  core_r11 <= rd_data ;
        else if (out_valid_data==1 && rt==11)    core_r11 <= data ;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   core_r12 <= 0 ;
    else begin
        if (next_state==S_WRITE_BACK && rd==12)  core_r12 <= rd_data ;
        else if (out_valid_data==1 && rt==12)    core_r12 <= data ;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   core_r13 <= 0 ;
    else begin
        if (next_state==S_WRITE_BACK && rd==13)  core_r13 <= rd_data ;
        else if (out_valid_data==1 && rt==13)    core_r13 <= data ;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   core_r14 <= 0 ;
    else begin
        if (next_state==S_WRITE_BACK && rd==14)  core_r14 <= rd_data ;
        else if (out_valid_data==1 && rt==14)    core_r14 <= data ;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   core_r15 <= 0 ;
    else begin
        if (next_state==S_WRITE_BACK && rd==15)  core_r15 <= rd_data ;
        else if (out_valid_data==1 && rt==15)    core_r15 <= data ;
    end
end

endmodule





//================================================================================================
//   SUBMODULE
//================================================================================================





module r_DRAM_inst(
// global signals 
                clk,
              rst_n,
// input/output signals 
           in_valid,
            in_addr,
          out_valid,
           out_inst,
// axi read address channel                     
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
      arready_m_inf, 
// axi read data channel                    
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 
);
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;
// ---------------------------------------------------------------
// global signals
input  wire clk, rst_n;
// ---------------------------------------------------------------
// input/output signals 
input  in_valid;
input  [10:0] in_addr;
output reg out_valid;
output reg [15:0] out_inst;
// ---------------------------------------------------------------
// axi read address channel 
output  wire [ID_WIDTH-1:0]       arid_m_inf;
output  wire [ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [7 -1:0]            arlen_m_inf;
output  wire [3 -1:0]           arsize_m_inf;
output  wire [2 -1:0]          arburst_m_inf;
output  reg                    arvalid_m_inf;
input   wire                   arready_m_inf;
// ---------------------------------------------------------------
// axi read data channel
input   wire [ID_WIDTH-1:0]         rid_m_inf;
input   wire [DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [2 -1:0]             rresp_m_inf;
input   wire                      rlast_m_inf;
input   wire                     rvalid_m_inf;
output  wire                     rready_m_inf;
// ---------------------------------------------------------------
//================================================================
//  integer / genvar / parameter
//================================================================
//  FSM
parameter S_IDLE = 3'd0 ;
parameter S_HIT  = 3'd1 ;
parameter S_BUF  = 3'd2 ;
parameter S_SEND = 3'd3 ;
parameter S_WAIT = 3'd4 ;
parameter S_OUT  = 3'd5 ;
//================================================================
//  Wire & Reg
//================================================================
//  FSM
reg  [2:0] curr_state, next_state;
//  SRAM
reg [6:0] curr_addr;
wire [15:0] sram_out;
// 
reg is_valid;
reg [3:0] tag;
//================================================================
//  SRAM
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     curr_addr <= 0 ;
    else begin
        if (next_state==S_HIT)      curr_addr <= in_addr[6:0] ;
        else if (rvalid_m_inf==1)   curr_addr <= curr_addr + 1 ;
        else if (next_state==S_IDLE)    curr_addr <= 0 ;
    end
end

MYMEM SRAM_inst( .Q(sram_out), .CLK(clk), .CEN(1'b0), .WEN(curr_state!=S_WAIT), .A(curr_addr), .D(rdata_m_inf), .OEN(1'b0) );

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     is_valid <= 0 ;
    else if (curr_state==S_SEND)    is_valid <= 1 ;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     tag <= 0 ;
    else if (curr_state==S_SEND)    tag <= in_addr[10:7] ;
end
//================================================================
//  FSM
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     curr_state <= S_IDLE ;
    else            curr_state <= next_state ;
end
always @(*) begin
    next_state = curr_state ;
    case(curr_state)
        S_IDLE: begin
            if (in_valid==1) begin
                if (is_valid==1 && tag==in_addr[10:7])  
                    next_state = S_HIT ;
                else
                    next_state = S_SEND ;
            end 
        end
        S_HIT:  next_state = S_BUF ;
        S_BUF:  next_state = S_OUT ;
        S_SEND: if (arready_m_inf==1)   next_state = S_WAIT ;
        S_WAIT: if (rlast_m_inf==1)     next_state = S_OUT ;
        S_OUT:  next_state = S_IDLE ;
    endcase
end
//================================================================
//  AXI 4
//================================================================
// constant AXI 4 signals
assign arid_m_inf = 0 ;
assign arlen_m_inf = 7'b111_1111 ;
assign arsize_m_inf = 3'b001 ;
assign arburst_m_inf = 2'b01 ;
// 
assign araddr_m_inf = { 16'd0 , 4'b001 , in_addr[10:7] , 8'd0 } ;
assign rready_m_inf = (curr_state==S_WAIT) ? 1 : 0 ;
// 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     arvalid_m_inf <= 0 ;
    else begin
        if (next_state==S_SEND) arvalid_m_inf <= 1 ;
        else                    arvalid_m_inf <= 0 ;
    end
end
//================================================================
//  OUTPUT
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     out_inst <= 0 ;
    else begin
        if (curr_state==S_WAIT) begin
            if (rvalid_m_inf==1 && curr_addr==in_addr[6:0])
                out_inst <= rdata_m_inf ;
        end 
        else if (curr_state==S_BUF)
            out_inst <= sram_out ;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     out_valid <= 0 ;
    else begin
        if (next_state==S_OUT)  out_valid <= 1 ;
        else                    out_valid <= 0 ;
    end
end

endmodule





module r_DRAM_data(
// global signals 
                clk,
              rst_n,
// input/output signals 
           in_valid,
           in_write,
            in_addr,
            in_data,
          out_valid,
           out_data,
// axi read address channel                     
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
// axi read data channel                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 
);
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;
// ---------------------------------------------------------------
// global signals
input  wire clk, rst_n;
// ---------------------------------------------------------------
// input/output signals 
input  in_valid;
input  in_write;
input  [10:0] in_addr;
input  [15:0] in_data;
output reg out_valid;
output reg [15:0] out_data;
// ---------------------------------------------------------------
// axi read address channel 
output  wire [ID_WIDTH-1:0]       arid_m_inf;
output  wire [ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [7 -1:0]            arlen_m_inf;
output  wire [3 -1:0]           arsize_m_inf;
output  wire [2 -1:0]          arburst_m_inf;
output  reg                    arvalid_m_inf;
input   wire                   arready_m_inf;
// ---------------------------------------------------------------
// axi read data channel
input   wire [ID_WIDTH-1:0]         rid_m_inf;
input   wire [DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [2 -1:0]             rresp_m_inf;
input   wire                      rlast_m_inf;
input   wire                     rvalid_m_inf;
output  wire                     rready_m_inf;
// ---------------------------------------------------------------
//================================================================
//  integer / genvar / parameter
//================================================================
//  FSM
parameter S_IDLE = 3'd0 ;
parameter S_HIT  = 3'd1 ;
parameter S_BUF  = 3'd2 ;
parameter S_SEND = 3'd3 ;
parameter S_WAIT = 3'd4 ;
parameter S_OUT  = 3'd5 ;
parameter S_WRITE_SARM = 3'd6 ;
//================================================================
//  Wire & Reg
//================================================================
//  FSM
reg  [2:0] curr_state, next_state;
//  SRAM
reg [6:0] curr_addr;
wire [15:0] sram_out, sram_data;
// 
reg is_valid;
reg [3:0] tag;
//================================================================
//  SRAM
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     curr_addr <= 0 ;
    else begin
        if (next_state==S_HIT || next_state==S_WRITE_SARM)  curr_addr <= in_addr[6:0] ;
        else if (rvalid_m_inf==1)                           curr_addr <= curr_addr + 1 ;
        else if (next_state==S_IDLE)    curr_addr <= 0 ;
    end
end
assign sram_data = (curr_state==S_WRITE_SARM) ? in_data : rdata_m_inf ;

MYMEM SRAM_data( .Q(sram_out), .CLK(clk), .CEN(1'b0), .WEN(curr_state!=S_WAIT && curr_state!=S_WRITE_SARM), .A(curr_addr), .D(sram_data), .OEN(1'b0) );

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     is_valid <= 0 ;
    else if (curr_state==S_SEND)    is_valid <= 1 ;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     tag <= 0 ;
    else if (curr_state==S_SEND)    tag <= in_addr[10:7] ;
end
//================================================================
//  FSM
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     curr_state <= S_IDLE ;
    else            curr_state <= next_state ;
end
always @(*) begin
    next_state = curr_state ;
    case(curr_state)
        S_IDLE: begin
            if (in_valid==1) begin
                if (in_write==1 && tag==in_addr[10:7])
                    next_state = S_WRITE_SARM ;
                else if (is_valid==1 && tag==in_addr[10:7])  
                    next_state = S_HIT ;
                else if (in_write!=1)
                    next_state = S_SEND ;
            end 
        end
        S_HIT:  next_state = S_BUF ;
        S_BUF:  next_state = S_OUT ;
        S_SEND: if (arready_m_inf==1)   next_state = S_WAIT ;
        S_WAIT: if (rlast_m_inf==1)     next_state = S_OUT ;
        S_OUT:  next_state = S_IDLE ;
        S_WRITE_SARM:   next_state = S_IDLE ;
    endcase
end
//================================================================
//  AXI 4
//================================================================
// constant AXI 4 signals
assign arid_m_inf = 0 ;
assign arlen_m_inf = 7'b111_1111 ;
assign arsize_m_inf = 3'b001 ;
assign arburst_m_inf = 2'b01 ;
// 
assign araddr_m_inf = { 16'd0 , 4'b001 , in_addr[10:7] , 8'd0 } ;
assign rready_m_inf = (curr_state==S_WAIT) ? 1 : 0 ;
// 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     arvalid_m_inf <= 0 ;
    else begin
        if (next_state==S_SEND) arvalid_m_inf <= 1 ;
        else                    arvalid_m_inf <= 0 ;
    end
end
//================================================================
//  OUTPUT
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     out_data <= 0 ;
    else begin
        if (curr_state==S_WAIT) begin
            if (rvalid_m_inf==1 && curr_addr==in_addr[6:0])
                out_data <= rdata_m_inf ;
        end 
        else if (curr_state==S_BUF)
            out_data <= sram_out ;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     out_valid <= 0 ;
    else begin
        if (next_state==S_OUT)  out_valid <= 1 ;
        else                    out_valid <= 0 ;
    end
end

endmodule





module w_DRAM_data(
// global signals 
                clk,
              rst_n,
// input/output signals 
           in_valid,
            in_addr,
            in_data,
         out_finish,
// axi write address channel 
         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
// axi write data channel                     
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
// axi write response channel
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf
);
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;
// ---------------------------------------------------------------
// global signals
input  wire clk, rst_n;
// ---------------------------------------------------------------
// input/output signals 
input  in_valid;
input  [10:0] in_addr;
input  [15:0] in_data;
output reg out_finish;
// ---------------------------------------------------------------
// axi write address channel 
output  wire [ID_WIDTH-1:0]        awid_m_inf;
output  wire [ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [3 -1:0]            awsize_m_inf;
output  wire [2 -1:0]           awburst_m_inf;
output  wire [7 -1:0]             awlen_m_inf;
output  reg                     awvalid_m_inf;
input   wire                    awready_m_inf;
// ---------------------------------------------------------------
// axi write data channel 
output  reg  [DATA_WIDTH-1:0]     wdata_m_inf;
output  reg                       wlast_m_inf;
output  reg                      wvalid_m_inf;
input   wire                     wready_m_inf;
// ---------------------------------------------------------------
// axi write response channel
input   wire [ID_WIDTH-1:0]         bid_m_inf;
input   wire [2 -1:0]             bresp_m_inf;
input   wire                     bvalid_m_inf;
output  wire                     bready_m_inf;
// ---------------------------------------------------------------
//================================================================
//  integer / genvar / parameter
//================================================================
//  FSM
parameter S_IDLE = 2'd0 ;
parameter S_SEND = 2'd1 ;
parameter S_WAIT = 2'd2 ;
parameter S_OUT  = 2'd3 ;
//================================================================
//  Wire & Reg
//================================================================
//  FSM
reg  [1:0] curr_state, next_state;
//================================================================
//  FSM
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     curr_state <= S_IDLE ;
    else            curr_state <= next_state ;
end
always @(*) begin
    next_state = curr_state ;
    case(curr_state)
        S_IDLE: if (in_valid==1)        next_state = S_SEND ; 
        S_SEND: if (awready_m_inf==1)   next_state = S_WAIT ;
        S_WAIT: if (wready_m_inf==1 && wlast_m_inf==1)     next_state = S_OUT ;
        S_OUT:  if (bvalid_m_inf==1)    next_state = S_IDLE ;
    endcase
end
//================================================================
//  AXI 4
//================================================================
// constant AXI 4 signals
assign awid_m_inf = 0 ;
assign awlen_m_inf = 7'd0 ;
assign awsize_m_inf = 3'b001 ;
assign awburst_m_inf = 2'b01 ;
//
assign awaddr_m_inf = { 16'd0 , 4'b0001 , in_addr , 1'b0 } ;
assign bready_m_inf = (curr_state==S_OUT) ? 1 : 0 ;
// 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     awvalid_m_inf <= 0 ;
    else begin
        if (next_state==S_SEND)     awvalid_m_inf <= 1 ;
        else                        awvalid_m_inf <= 0 ;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     wdata_m_inf <= 0 ;
    else if (in_valid==1)    wdata_m_inf <= in_data ;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     wlast_m_inf <= 0 ;
    else begin
        if (next_state==S_WAIT)     wlast_m_inf <= 1 ;
        else                        wlast_m_inf <= 0 ;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     wvalid_m_inf <= 0 ;
    else begin
        if (next_state==S_WAIT)     wvalid_m_inf <= 1 ;
        else                        wvalid_m_inf <= 0 ;
    end
end
//================================================================
//  OUTPUT
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     out_finish <= 0 ;
    else begin
        // if (bvalid_m_inf==1)    out_finish <= 1 ;
        if (curr_state==S_OUT && next_state==S_IDLE)    out_finish <= 1 ;
        else                    out_finish <= 0 ;
    end
end

endmodule
