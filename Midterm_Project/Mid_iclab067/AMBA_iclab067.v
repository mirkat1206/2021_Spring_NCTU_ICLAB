//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Midterm Project: Advanced Microcontroller Bus Architecture (AMBA)
//   Author         : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : AMBA.v
//   Module Name : AMBA
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module AMBA(
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
//  integer / genvar / parameter
//================================================================
integer i, j;
//  axi
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 32, DRAM_NUMBER = 2, WRIT_NUMBER = 1 ;
//  op_code
parameter OP_MULTI = 2'b00, OP_CONVO = 2'b11;
//  FSM
parameter STATE_IDLE  = 3'd0 ;
parameter STATE_INSTR = 3'd1 ;
parameter STATE_DATA  = 3'd2 ;
parameter STATE_CALCU = 3'd3 ;
parameter STATE_STORE = 3'd4 ;
parameter STATE_OUTPT = 3'd5 ;
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
// ---------------------------------------------------------------
// global signals 
input   clk, rst_n;
// ---------------------------------------------------------------
// APB channel 
input   wire [ADDR_WIDTH-1:0] PADDR;
output  reg  [DATA_WIDTH-1:0] PRDATA;
input   wire                  PSELx;
input   wire                  PENABLE;
input   wire                  PWRITE;
output  reg                   PREADY;
// ---------------------------------------------------------------
// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 4 -1:0]             awlen_m_inf;
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
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]        arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]    araddr_m_inf;
output  wire [DRAM_NUMBER * 4 -1:0]             arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]            arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]           arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]                arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]                arready_m_inf;
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
//  Reg : to save time
//================================================================
// ---------------------------------------------------------------
// APB channel 
// input   wire [ADDR_WIDTH-1:0] PADDR;
reg [ADDR_WIDTH-1:0] PADDR_r;
reg                  PENABLE_r;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) PADDR_r <= 0 ;
    else        PADDR_r <= PADDR ;
end
//================================================================
//  Wire : for convenience
//================================================================
// ---------------------------------------------------------------
// axi read address channel 
wire [ID_WIDTH-1:0]     arid_m_inf_w[0:1];
wire [ADDR_WIDTH-1:0] araddr_m_inf_w[0:1];
wire [4-1:0]           arlen_m_inf_w[0:1];
wire [3-1:0]          arsize_m_inf_w[0:1];
wire [2-1:0]         arburst_m_inf_w[0:1];
wire                 arvalid_m_inf_w[0:1];
assign    arid_m_inf = {    arid_m_inf_w[0] ,    arid_m_inf_w[1] } ;
assign  araddr_m_inf = {  araddr_m_inf_w[0] ,  araddr_m_inf_w[1] } ;
assign   arlen_m_inf = {   arlen_m_inf_w[0] ,   arlen_m_inf_w[1] } ;
assign  arsize_m_inf = {  arsize_m_inf_w[0] ,  arsize_m_inf_w[1] } ;
assign arburst_m_inf = { arburst_m_inf_w[0] , arburst_m_inf_w[1] } ;
assign arvalid_m_inf = { arvalid_m_inf_w[0] , arvalid_m_inf_w[1] } ;
wire                 arready_m_inf_w[0:1];
assign arready_m_inf_w[0] = arready_m_inf[1] ;
assign arready_m_inf_w[1] = arready_m_inf[0] ;
// ---------------------------------------------------------------
// axi read data channel 
wire [ID_WIDTH-1:0]     rid_m_inf_w[0:1];
wire [DATA_WIDTH-1:0] rdata_m_inf_w[0:1];
wire [2-1:0]          rresp_m_inf_w[0:1];
wire                  rlast_m_inf_w[0:1];
wire                 rvalid_m_inf_w[0:1];
assign    rid_m_inf_w[0] =    rid_m_inf[DRAM_NUMBER * ID_WIDTH-1:ID_WIDTH]     ;
assign    rid_m_inf_w[1] =    rid_m_inf[ID_WIDTH-1:0]                          ;
assign  rdata_m_inf_w[0] =  rdata_m_inf[DRAM_NUMBER * DATA_WIDTH-1:DATA_WIDTH] ;
assign  rdata_m_inf_w[1] =  rdata_m_inf[DATA_WIDTH-1:0]                        ;
assign  rresp_m_inf_w[0] =  rresp_m_inf[DRAM_NUMBER * 2-1:2]                   ;
assign  rresp_m_inf_w[1] =  rresp_m_inf[1:0]                                   ;
assign  rlast_m_inf_w[0] =  rlast_m_inf[1]                                     ;
assign  rlast_m_inf_w[1] =  rlast_m_inf[0]                                     ;
assign rvalid_m_inf_w[0] = rvalid_m_inf[1]                                     ;
assign rvalid_m_inf_w[1] = rvalid_m_inf[0]                                     ;
wire                 rready_m_inf_w[0:1];
assign rready_m_inf = { rready_m_inf_w[0] , rready_m_inf_w[1] } ;
//================================================================
//  CONSTANT axi signals
//================================================================
// ---------------------------------------------------------------
// axi write address channel 
assign    awid_m_inf = 0      ;
assign   awlen_m_inf = 15     ;
assign  awsize_m_inf = 3'b010 ;
assign awburst_m_inf = 2'b01  ;
// ---------------------------------------------------------------
// axi read address channel 
assign    arid_m_inf_w[0] = 0      ;
assign    arid_m_inf_w[1] = 0      ;
assign  arsize_m_inf_w[0] = 3'b010 ;
assign  arsize_m_inf_w[1] = 3'b010 ;
assign arburst_m_inf_w[0] = 2'b01  ;
assign arburst_m_inf_w[1] = 2'b01  ;
//================================================================
//  Wire & Reg
//================================================================
//  FSM
reg [2:0] current_state, next_state;
//  INSTRUCTION
wire [ADDR_WIDTH-1:0] DRAM1_base, DRAM_read_base;
wire [1:0] op_code;
//  DRAM_read : Read Channel
reg  [7:0]              length_read;
wire                 out_valid_read;
wire [DATA_WIDTH-1:0] out_data_read;
//  MATRIX read
reg                is_finished_read;
reg  [7:0]                 cnt_read;
reg  [DATA_WIDTH-1:0]   matrix_read[1:16][1:16];
//  DRAM_1 : Read Channel
wire [7:0]                 length_1;
wire                    out_valid_1;
wire [DATA_WIDTH-1:0]    out_data_1;
//   DRAM1 : Write Address Channel
wire [DATA_WIDTH*16-1:0] matrix_ans_row;
wire is_write_finish;
//  MATRIX 1
reg                   is_finished_1;
reg  [7:0]                    cnt_1;
reg  [DATA_WIDTH-1:0]      matrix_1[0:17][0:17];
//  ALU
reg  [4:0] now_i, now_j;
reg  [4:0] next_i, next_j;
reg [DATA_WIDTH-1:0] next_value;
wire [DATA_WIDTH-1:0] mrXm1[1:16];
wire [DATA_WIDTH-1:0] mrCm1[1:9];
wire [DATA_WIDTH-1:0] next_convo, next_multi;
//  MATRIX ans
reg  [DATA_WIDTH-1:0] matrix_ans[1:16][1:16];
// fuck it
wire                     fuck_valid;
wire [DATA_WIDTH-1:0]          fuck;
//================================================================
//  FSM
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     current_state <= STATE_IDLE ;
    else            current_state <= next_state ;
end
always @(*) begin
    next_state = current_state ;
    case(current_state)
        STATE_IDLE:     if (PENABLE==1)         next_state = STATE_INSTR ;
        STATE_INSTR:    if (out_valid_read==1)  next_state = STATE_DATA ;
        STATE_DATA:     if (is_finished_read==1 && is_finished_1==1)    next_state = STATE_CALCU ;
        STATE_CALCU:    if (now_i==16 && now_j==16)   next_state = STATE_STORE ;
        STATE_STORE:    if (now_i==16 && bvalid_m_inf==1)  next_state = STATE_OUTPT ;
        STATE_OUTPT:    next_state = STATE_IDLE ;
    endcase
end
//================================================================
//  INSTRUCTION
//================================================================
// output  wire [DATA_WIDTH-1:0] PRDATA;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   PRDATA <= 0 ;
    else begin
        if (current_state==STATE_INSTR && out_valid_read==1)  PRDATA <= out_data_read ;
    end
end
assign DRAM1_base     = { 16'd0 , PRDATA[31:18] , 2'b00 } ;
assign DRAM_read_base = { 16'd0 , PRDATA[15: 2] , 2'b00 } ;
assign op_code = PRDATA[1:0] ;
//================================================================
//  DRAM_read : Read Channel
//================================================================
r_DRAM_read r_DRAM_read( 
// global signals 
    .clk(clk), 
    .rst_n(rst_n), 
// APB channel 
    .PADDR(PADDR_r), 
// DRAM read address channel
   .araddr_m_inf( araddr_m_inf_w[0]), 
    .arlen_m_inf(  arlen_m_inf_w[0]), 
  .arvalid_m_inf(arvalid_m_inf_w[0]),
  .arready_m_inf(arready_m_inf_w[0]),
// DRAM read data channel
     .rdata_m_inf( rdata_m_inf_w[0]),
     .rlast_m_inf( rlast_m_inf_w[0]),
    .rvalid_m_inf(rvalid_m_inf_w[0]),
    .rready_m_inf(rready_m_inf_w[0]),
// others
    .en(current_state==STATE_INSTR || ( current_state==STATE_DATA && !is_finished_read ) ),
  .mode(current_state==STATE_INSTR),
              .base(DRAM_read_base),    
               .length(length_read),      
         .out_valid(out_valid_read),
           .out_data(out_data_read),
           // fuck it
           .fuck_valid(fuck_valid),
           .fuck(fuck)
);
// reg  [7:0]              length_read;
always @(*) begin
    if (current_state==STATE_INSTR)     length_read = 0 ;
    else begin
        case(op_code)
            OP_MULTI:   length_read = 255 ;
            OP_CONVO:   length_read = 8 ;
            default:    length_read = 0 ;
        endcase
    end
end
//================================================================
//  DRAM_1 : Read Channel
//================================================================
r_DRAM1 r_DRAM1( 
// global signals 
    .clk(clk), 
    .rst_n(rst_n), 
// DRAM read address channel
   .araddr_m_inf( araddr_m_inf_w[1]), 
    .arlen_m_inf(  arlen_m_inf_w[1]), 
  .arvalid_m_inf(arvalid_m_inf_w[1]),
  .arready_m_inf(arready_m_inf_w[1]),
// DRAM read data channel
     .rdata_m_inf( rdata_m_inf_w[1]),
     .rlast_m_inf( rlast_m_inf_w[1]),
    .rvalid_m_inf(rvalid_m_inf_w[1]),
    .rready_m_inf(rready_m_inf_w[1]),
// others
    .en(current_state==STATE_DATA && !is_finished_1),
                   .base(DRAM1_base),    
                   .length(length_1),      
// outputs           
             .out_valid(out_valid_1),
               .out_data(out_data_1),
// inputs   
      .in_valid(current_state==STATE_CALCU),
         .in_data(matrix_ans[16][16]),
         // fuck it
           .fuck_valid(fuck_valid),
           .fuck(fuck)
);
// wire [7:0]              length_1;
assign length_1 = 255 ;
//================================================================
//   DRAM1 : Write Address Channel
//================================================================
// wire [DATA_WIDTH*16-1:0] matrix_ans_row;
assign matrix_ans_row = {   matrix_ans[1][1 ] , matrix_ans[1][2 ] , matrix_ans[1][3 ] , matrix_ans[1][4 ] , 
                            matrix_ans[1][5 ] , matrix_ans[1][6 ] , matrix_ans[1][7 ] , matrix_ans[1][8 ] , 
                            matrix_ans[1][9 ] , matrix_ans[1][10] , matrix_ans[1][11] , matrix_ans[1][12] , 
                            matrix_ans[1][13] , matrix_ans[1][14] , matrix_ans[1][15] , matrix_ans[1][16] } ;
w_DRAM1 w_DRAM1(
// global signals 
       .clk(clk),
       .rst_n(rst_n),
// axi write address channel 
       .awaddr_m_inf( awaddr_m_inf),
      .awvalid_m_inf(awvalid_m_inf),
      .awready_m_inf(awready_m_inf),    
// DRAM write data channel 
         .wdata_m_inf( wdata_m_inf),
         .wlast_m_inf( wlast_m_inf),
        .wvalid_m_inf(wvalid_m_inf),
        .wready_m_inf(wready_m_inf),
// DRAM write response channel 
        .bvalid_m_inf(bvalid_m_inf),
        .bready_m_inf(bready_m_inf),
// others
      .base( DRAM1_base + (now_i-1)*4*16 ),
      .in_valid(next_state==STATE_STORE),
      .in_data(matrix_ans_row)
);
//================================================================
//  MATRIX read
//================================================================
// reg             is_finished_read;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     is_finished_read <= 0 ;
    else begin
        if (current_state==STATE_DATA && out_valid_read==1) begin
            case(op_code)
                OP_MULTI: if (cnt_read==255)    is_finished_read <= 1 ;
                OP_CONVO: if (cnt_read==8)      is_finished_read <= 1 ;
            endcase
        end
        else if (current_state==STATE_IDLE)     is_finished_read <= 0 ;
    end
end
// reg [7:0]               cnt_read;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     cnt_read <= 0 ;
    else begin
        if (current_state==STATE_DATA && out_valid_read==1) cnt_read <= cnt_read + 1 ;
        else if (current_state==STATE_IDLE)                 cnt_read <= 0 ;
    end
end
// reg [DATA_WIDTH-1:0] matrix_read[1:16][1:16];
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for( i=1 ; i<=16 ; i=i+1 ) 
            for( j=1 ; j<=16 ; j=j+1 )
                matrix_read[i][j] <= 0 ;
    end
    else begin
        if (current_state==STATE_DATA) begin
            case(op_code)
                OP_MULTI: begin
                    if (out_valid_read==1) begin
                        for( i=1 ; i<=16 ; i=i+1 )
                            for( j=1 ; j<=15 ; j=j+1)
                                matrix_read[i][j] <= matrix_read[i][j+1] ;
                        for( i=1 ; i<=15 ; i=i+1 )
                            matrix_read[i][16] <= matrix_read[i+1][1] ;
                        matrix_read[16][16] <= out_data_read ;
                    end
                end
                OP_CONVO: begin
                    if (out_valid_read==1) begin
                        for( i=1 ; i<=3 ; i=i+1 )
                            for( j=1 ; j<=2 ; j=j+1)
                                matrix_read[i][j] <= matrix_read[i][j+1] ;
                        for( i=1 ; i<=2 ; i=i+1 )
                            matrix_read[i][3] <= matrix_read[i+1][1] ;
                        matrix_read[3][3] <= out_data_read ;
                    end
                end
            endcase
        end
        else if (current_state==STATE_CALCU && op_code==OP_MULTI) begin
            for( i=1 ; i<=16 ; i=i+1 )
                for( j=1 ; j<16 ; j=j+1 )
                    matrix_read[i][j] <= matrix_read[i][j+1] ;
            for( i=1 ; i<=16 ; i=i+1 )
                matrix_read[i][16] <= matrix_read[i][1] ;
        end
    end
end
//================================================================
//  MATRIX 1
//================================================================
// reg             is_finished_1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     is_finished_1 <= 0 ;
    else begin
        if (current_state==STATE_DATA && out_valid_1==1 && cnt_1==255)  is_finished_1 <= 1 ;
        else if (current_state==STATE_IDLE)                             is_finished_1 <= 0 ;
    end
end
// reg [7:0]               cnt_1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     cnt_1 <= 0 ;
    else begin
        if (current_state==STATE_DATA && out_valid_1==1)    cnt_1 <= cnt_1 + 1 ;
        else if (current_state==STATE_IDLE)                 cnt_1 <= 0 ;
    end
end
// reg [DATA_WIDTH-1:0] matrix_1[0:17][0:17];
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for( i=0 ; i<=17 ; i=i+1 ) 
            for( j=0 ; j<=17 ; j=j+1 )
                matrix_1[i][j] <= 0 ;
    end
    else begin
        matrix_1[ 0][ 0] <= 0 ;
        matrix_1[ 0][17] <= 0 ;
        matrix_1[17][ 0] <= 0 ;
        matrix_1[17][17] <= 0 ;
        for( i=1 ; i<17 ; i=i+1 ) begin
            matrix_1[i][ 0] <= 0 ;
            matrix_1[i][17] <= 0 ;
        end
        for( j=1 ; j<17 ; j=j+1 ) begin
            matrix_1[ 0][j] <= 0 ;
            matrix_1[17][j] <= 0 ;
        end
        if (current_state==STATE_DATA) begin
            if (out_valid_1==1) begin
                for( i=1 ; i<=16 ; i=i+1 )
                    for( j=1 ; j<=15 ; j=j+1)
                        matrix_1[i][j] <= matrix_1[i][j+1] ;
                for( i=1 ; i<=15 ; i=i+1 )
                    matrix_1[i][16] <= matrix_1[i+1][1] ;
                matrix_1[16][16] <= out_data_1 ;
            end
        end
        else if (current_state==STATE_CALCU ) begin
            if (now_j==16) begin
                if (op_code==OP_MULTI) begin
                    for( i=1 ; i<16 ; i=i+1 )
                        for( j=1 ; j<=16 ; j=j+1 )
                            matrix_1[i][j] <= matrix_1[i+1][j] ;
                    for( j=1 ; j<=16 ; j=j+1 )
                        matrix_1[16][j] <= matrix_1[1][j] ;
                end
            end
        end
    end
end
//================================================================
//  MATRIX ans
//================================================================
// reg [DATA_WIDTH-1:0] matrix_ans[1:16][1:16];
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for( i=1 ; i<=16 ; i=i+1 ) 
            for( j=1 ; j<=16 ; j=j+1 )
                matrix_ans[i][j] <= 0 ;
    end
    else begin
        if (current_state==STATE_CALCU) begin
            for( i=1 ; i<=16 ; i=i+1 )
                for( j=1 ; j<=15 ; j=j+1)
                    matrix_ans[i][j] <= matrix_ans[i][j+1] ;
            for( i=1 ; i<=15 ; i=i+1 )
                matrix_ans[i][16] <= matrix_ans[i+1][1] ;
            matrix_ans[16][16] <= (op_code==OP_MULTI) ? next_multi : next_value ; 
        end
        else if (current_state==STATE_STORE && bvalid_m_inf==1) begin
            for( i=1 ; i<=15 ; i=i+1 ) 
                for( j=1 ; j<=16 ; j=j+1 )
                    matrix_ans[i][j] <= matrix_ans[i+1][j] ;
        end
    end
end
//================================================================
//  ALU
//================================================================
// reg  [4:0] now_i, now_j;
// reg  [4:0] next_i, next_j;
always @(*) begin
    next_i = now_i ;
    if (current_state==STATE_CALCU && now_j==16) begin
        if (now_i==16)    next_i = 1 ;
        else              next_i = now_i + 1 ;
    end
    else if (current_state==STATE_STORE && bvalid_m_inf==1) begin
        if (now_i==16)    next_i = 1 ;
        else              next_i = now_i + 1 ;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     now_i <= 1 ;
    else            now_i <= next_i ;
end
always @(*) begin
    next_j = now_j ;
    if (current_state==STATE_CALCU) begin
        if (now_j==16)    next_j = 1 ;
        else              next_j = now_j + 1 ;
    end    
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     now_j <= 1 ;
    else            now_j <= next_j ;
end
// wire [DATA_WIDTH-1:0]   mrXm1[1:16];
assign mrXm1[ 1] = matrix_1[1][ 1] * matrix_read[ 1][1] ;
assign mrXm1[ 2] = matrix_1[1][ 2] * matrix_read[ 2][1] ;
assign mrXm1[ 3] = matrix_1[1][ 3] * matrix_read[ 3][1] ;
assign mrXm1[ 4] = matrix_1[1][ 4] * matrix_read[ 4][1] ;
assign mrXm1[ 5] = matrix_1[1][ 5] * matrix_read[ 5][1] ;
assign mrXm1[ 6] = matrix_1[1][ 6] * matrix_read[ 6][1] ;
assign mrXm1[ 7] = matrix_1[1][ 7] * matrix_read[ 7][1] ;
assign mrXm1[ 8] = matrix_1[1][ 8] * matrix_read[ 8][1] ;
assign mrXm1[ 9] = matrix_1[1][ 9] * matrix_read[ 9][1] ;
assign mrXm1[10] = matrix_1[1][10] * matrix_read[10][1] ;
assign mrXm1[11] = matrix_1[1][11] * matrix_read[11][1] ;
assign mrXm1[12] = matrix_1[1][12] * matrix_read[12][1] ;
assign mrXm1[13] = matrix_1[1][13] * matrix_read[13][1] ;
assign mrXm1[14] = matrix_1[1][14] * matrix_read[14][1] ;
assign mrXm1[15] = matrix_1[1][15] * matrix_read[15][1] ;
assign mrXm1[16] = matrix_1[1][16] * matrix_read[16][1] ;
// wire [DATA_WIDTH-1:0]   mrCm1[1:9];
assign mrCm1[ 1] = matrix_1[next_i-1][next_j-1] * matrix_read[1][1] ;
assign mrCm1[ 2] = matrix_1[next_i-1][next_j  ] * matrix_read[1][2] ;
assign mrCm1[ 3] = matrix_1[next_i-1][next_j+1] * matrix_read[1][3] ;
assign mrCm1[ 4] = matrix_1[next_i  ][next_j-1] * matrix_read[2][1] ;
assign mrCm1[ 5] = matrix_1[next_i  ][next_j  ] * matrix_read[2][2] ;
assign mrCm1[ 6] = matrix_1[next_i  ][next_j+1] * matrix_read[2][3] ;
assign mrCm1[ 7] = matrix_1[next_i+1][next_j-1] * matrix_read[3][1] ;
assign mrCm1[ 8] = matrix_1[next_i+1][next_j  ] * matrix_read[3][2] ;
assign mrCm1[ 9] = matrix_1[next_i+1][next_j+1] * matrix_read[3][3] ;
// wire [DATA_WIDTH-1:0] next_convo, next_multi;
assign next_convo = mrCm1[1] + mrCm1[2]  + mrCm1[3]  + mrCm1[4]  + mrCm1[5]  + mrCm1[6]  + mrCm1[7]  + mrCm1[8] + mrCm1[9] ;
assign next_multi = mrXm1[1] + mrXm1[2]  + mrXm1[3]  + mrXm1[4]  + mrXm1[5]  + mrXm1[6]  + mrXm1[7]  + mrXm1[8] + 
                    mrXm1[9] + mrXm1[10] + mrXm1[11] + mrXm1[12] + mrXm1[13] + mrXm1[14] + mrXm1[15] + mrXm1[16] ;                    
// reg [DATA_WIDTH-1:0] next_value;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     next_value <= 0 ;
    else            next_value <= next_convo ;
end                    
//================================================================
//   OUTPUT
//================================================================
// output  reg                   PREADY;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   PREADY <= 0 ;
    else begin
        if (next_state==STATE_OUTPT)  PREADY <= 1 ;
        else  PREADY <= 0 ;
    end
end
endmodule





//================================================================================================
//   SUBMODULE
//================================================================================================





module r_DRAM_read(
// global signals 
       clk, rst_n,
// APB channel 
            PADDR,
// axi read address channel 
     araddr_m_inf,
      arlen_m_inf,
    arvalid_m_inf,   
    arready_m_inf,
// axi read data channel 
      rdata_m_inf,
      rlast_m_inf,
     rvalid_m_inf,
     rready_m_inf,
// others
               en,
             mode,
             base,
           length,
// outputs           
        out_valid,
        out_data,
// fuck it
        fuck_valid,
        fuck           
);
//================================================================
//  integer / genvar / parameter
//================================================================
integer i;
genvar idx;
//  axi
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 32, DRAM_NUMBER = 2, WRIT_NUMBER = 1 ;
//  mode
parameter MODE_INSTR = 1, MODE_DATA = 0 ;
//  FSM
parameter S_IDLE  = 3'd0 ;
parameter S_SEND  = 3'd1 ;
parameter S_WAIT  = 3'd2 ;
parameter S_OUTPT = 3'd3 ;
parameter S_HIT   = 3'd4 ;
parameter S_BUFFR = 3'd5 ;
parameter S_NXTHIT= 3'd6 ;
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
// global signals 
input   clk, rst_n;
// APB channel 
input  wire [ADDR_WIDTH-1:0] PADDR;
// axi read address channel 
output wire [ADDR_WIDTH-1:0] araddr_m_inf;
output reg  [4-1:0]           arlen_m_inf;
output reg                  arvalid_m_inf;
input  wire                 arready_m_inf;
// axi read data channel 
input  wire [DATA_WIDTH-1:0]  rdata_m_inf;
input  wire                   rlast_m_inf;
input  wire                  rvalid_m_inf;
output wire                  rready_m_inf;
// others
input  wire                            en;    
input  wire                          mode;    // 1 for instruction, 0 for data
input  wire [ADDR_WIDTH-1:0]         base;
input  wire [7:0]                  length;
// outputs           
output reg                      out_valid;
output reg  [DATA_WIDTH-1:0]     out_data;
// fuck it
output wire                     fuck_valid;
output wire [DATA_WIDTH-1:0]          fuck;
//================================================================
//  Wire & Reg
//================================================================
//  FSM
reg  [2:0] current_state, next_state;
//  IS HIT
wire is_instr_hit, is_data_hit, is_next_data_hit;
//  INSTRUCTION CACHE : address (1000~1fff) = { 0001_xxxx_xxxx_xx00 } = { 0001_{10'b"tag"}_00 }
reg                   valid_instr[0:3];
reg  [11:2]             tag_instr[0:3];
reg  [DATA_WIDTH-1:0] cache_instr[0:3];
//  DATA CACHE : address (2000~2fff) = { 0010_xxxx_xxxx_xx00 } = { 0002_{10'b"tag"}_00 }
reg  [ADDR_WIDTH-1:0]          address;
reg  [1023:0]               valid_data;
wire [11:2]                   tag_data;
//  FLAG
reg  has_last;
//  OUT_CNT
reg  [8:0] out_cnt;
//================================================================
//  SRAM
//================================================================
wire [DATA_WIDTH-1:0] Q_w;
MEM4 SRAM_read( .Q(Q_w), .CLK(clk), .CEN(1'b0), .WEN(!(current_state==S_OUTPT && mode==MODE_DATA)), .A(tag_data), .D(out_data), .OEN(1'b0) );
//================================================================
//  FSM
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     current_state <= S_IDLE ;
    else            current_state <= next_state ;
end
always @(*) begin
    next_state = current_state ;
    case(current_state)
        S_IDLE: begin
            if (en==1 && mode==MODE_INSTR) begin
                if (is_instr_hit)       next_state = S_OUTPT ;
                else                    next_state = S_SEND ;
            end
            else if (en==1 && mode==MODE_DATA) begin
                if (is_data_hit==1)     next_state = S_HIT ; //tk
                else                    next_state = S_SEND ;
            end
        end
        S_SEND: if (arready_m_inf==1)   next_state = S_WAIT ;
        S_WAIT: if (rvalid_m_inf==1)    next_state = S_OUTPT ;
        S_OUTPT: begin //tk
            if (out_cnt>length)         next_state = S_IDLE ;
            else if (rvalid_m_inf==1)   next_state = S_OUTPT ;
            else if (has_last==1) begin
                if (is_next_data_hit==1)     next_state = S_NXTHIT ;
                else                    next_state = S_SEND ;
            end       
            else                        next_state = S_WAIT ;
        end
        S_HIT: begin
            if (out_cnt>length)         next_state = S_BUFFR ;
            else if(is_next_data_hit==1)     next_state = S_HIT ;
            else                        next_state = S_BUFFR ;
        end
        S_BUFFR: begin
            if (out_cnt>length)         next_state = S_IDLE ;
            else                        next_state = S_SEND ;
        end
        S_NXTHIT:   next_state = S_HIT ;
    endcase
end
//================================================================
//  IS HIT
//================================================================
// wire is_instr_hit, is_data_hit;
assign is_instr_hit = (tag_instr[0]==PADDR[11:2] && valid_instr[0]==1) || (tag_instr[1]==PADDR[11:2] && valid_instr[1]==1) || 
                      (tag_instr[2]==PADDR[11:2] && valid_instr[2]==1) || (tag_instr[3]==PADDR[11:2] && valid_instr[3]==1) ;
assign is_data_hit  = (valid_data[tag_data]==1) ;
assign is_next_data_hit  = (valid_data[tag_data+1]==1) ;
//================================================================
//  INSTRUCTION CACHE : address (1000~1fff) = { 0001_xxxx_xxxx_xx00 } = { 0001_{10'b"tag"}_00 }
//================================================================
// reg                   valid_instr[0:3];
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for( i=0 ; i<4 ; i=i+1 )
            valid_instr[i] <= 0 ;
    end
    else begin
        if (current_state==S_OUTPT && mode==1 && is_instr_hit==0 ) begin
            valid_instr[0] <= 1 ;
            for( i=1 ; i<4 ; i=i+1 )
                valid_instr[i] <= valid_instr[i-1] ;
        end
    end
end
// reg  [11:2]             tag_instr[0:3];
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for( i=0 ; i<4 ; i=i+1 )
            tag_instr[i] <= 0 ;
    end
    else begin
        if (current_state==S_OUTPT && mode==1 && is_instr_hit==0 ) begin
            tag_instr[0] <= PADDR[11:2] ;
            for( i=1 ; i<4 ; i=i+1 )
                tag_instr[i] <= tag_instr[i-1] ;
        end
    end
end
// reg  [DATA_WIDTH-1:0] cache_instr[0:3];
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for( i=0 ; i<4 ; i=i+1 )
            cache_instr[i] <= 0 ;
    end
    else begin
        if (current_state==S_OUTPT && mode==1 && is_instr_hit==0 ) begin
            cache_instr[0] <= out_data ;
            for( i=1 ; i<4 ; i=i+1 )
                cache_instr[i] <= cache_instr[i-1] ;
        end
    end
end
//================================================================
//  DATA CACHE : address (2000~2fff) = { 0010_xxxx_xxxx_xx00 } = { 0002_{10'b"tag"}_00 }
//================================================================
// reg  [ADDR_WIDTH-1:0]          address;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     address <= 0 ;
    else begin
        if (mode==MODE_INSTR && current_state==S_OUTPT) 
            address <= { 16'd0 , out_data[15: 2] , 2'b00 } ;
        else begin
            if (next_state==S_HIT)  address <= address + 4 ;
            else                    address <= base + out_cnt*4 ;
        end
    end
end
assign fuck_valid = (mode==MODE_INSTR && current_state==S_OUTPT) ;
assign fuck = { 16'd0 , out_data[31: 18] , 2'b00 } ;
// reg  [1023:0]               valid_data;
generate
for( idx=0 ; idx<1024 ; idx=idx+1 ) begin : r_DRAM1_valid_data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) valid_data[idx] <= 0 ;
        else begin
            if (mode==MODE_DATA && out_valid==1 && tag_data==idx)     valid_data[idx] <= 1 ;
        end
    end
end
endgenerate
// wire [11:2]                   tag_data;
assign tag_data = address[11:2] ;
wire debug;
assign debug = valid_data[0];
//================================================================
//  AXI 4
//================================================================
// axi read address channel 
// output wire [ADDR_WIDTH-1:0] araddr_m_inf;
assign araddr_m_inf = (mode==MODE_INSTR) ? PADDR : address ;
// output reg  [4-1:0]           arlen_m_inf;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     arlen_m_inf <= 0 ;
    else begin
        if (mode==MODE_INSTR)   arlen_m_inf <= 0 ;
        else begin
            if ( (length-out_cnt+1)>=16 )   arlen_m_inf <= 15 ;
            else                            arlen_m_inf <= length - out_cnt ;
        end
    end
end
// output reg                  arvalid_m_inf;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     arvalid_m_inf <= 0 ;
    else begin
        if (next_state==S_SEND)     arvalid_m_inf <= 1 ;
        else                        arvalid_m_inf <= 0 ; 
    end
end
// axi read data channel 
// output wire                  rready_m_inf;
assign rready_m_inf = 1 ;
//================================================================
//  FLAG
//================================================================
// reg  has_last;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     has_last <= 0 ;
    else begin
        if (current_state==S_SEND)  has_last <= 0 ;
        else if (rlast_m_inf==1)    has_last <= 1 ;
    end
end
//================================================================
//  OUTPUT
//================================================================
// output reg                      out_valid;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     out_valid <= 0 ;
    else begin
        if (next_state==S_OUTPT || current_state==S_HIT) out_valid <= 1 ;
        // if (next_state==S_OUTPT || (current_state==S_HIT && is_data_hit==1) ) out_valid <= 1 ;
        else                                                out_valid <= 0 ;
    end
end
// output reg  [DATA_WIDTH-1:0]     out_data;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     out_data <= 0 ;
    else begin
        // if (next_state==S_OUTPT) begin
            case(mode)
                MODE_INSTR: begin
                    if (is_instr_hit==0)    out_data <= rdata_m_inf ;
                    else begin
                        if      (tag_instr[0]==PADDR[11:2])   out_data <= cache_instr[0] ;
                        else if (tag_instr[1]==PADDR[11:2])   out_data <= cache_instr[1] ;
                        else if (tag_instr[2]==PADDR[11:2])   out_data <= cache_instr[2] ;
                        else                                  out_data <= cache_instr[3] ;
                    end
                end
                MODE_DATA: begin
                    if (current_state==S_HIT)   out_data <= Q_w ;
                    else                        out_data <= rdata_m_inf ;
                end
            endcase
        // end
        // else    
    end
end
//================================================================
//  OUT_CNT
//================================================================
// reg  [8:0] out_cnt;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     out_cnt <= 0 ;
    else begin
        if (next_state==S_OUTPT || next_state==S_HIT)   out_cnt <= out_cnt + 1 ;
        else if (next_state==S_IDLE)                    out_cnt <= 0 ;
    end
end
endmodule





module r_DRAM1(
// global signals 
       clk, rst_n,
// axi read address channel 
     araddr_m_inf,
      arlen_m_inf,
    arvalid_m_inf,   
    arready_m_inf,
// axi read data channel 
      rdata_m_inf,
      rlast_m_inf,
     rvalid_m_inf,
     rready_m_inf,
// others
               en,
             base,
           length,
// outputs           
        out_valid,
        out_data,
// inputs   
         in_valid,
         in_data,
// fuck it
        fuck_valid,
        fuck         
);
//================================================================
//  integer / genvar / parameter
//================================================================
integer i;
genvar idx;
//  axi
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 32, DRAM_NUMBER = 2, WRIT_NUMBER = 1 ;
//  FSM
parameter S_IDLE  = 3'd0 ;
parameter S_SEND  = 3'd1 ;
parameter S_WAIT  = 3'd2 ;
parameter S_OUTPT = 3'd3 ;
parameter S_HIT   = 3'd4 ;
parameter S_BUFFR = 3'd5 ;
parameter S_NXTHIT= 3'd6 ;
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
// global signals 
input   clk, rst_n;
// axi read address channel 
output wire [ADDR_WIDTH-1:0] araddr_m_inf;
output reg  [4-1:0]           arlen_m_inf;
output reg                  arvalid_m_inf;
input  wire                 arready_m_inf;
// axi read data channel 
input  wire [DATA_WIDTH-1:0]  rdata_m_inf;
input  wire                   rlast_m_inf;
input  wire                  rvalid_m_inf;
output wire                  rready_m_inf;
// others
input  wire                            en;    
input  wire [ADDR_WIDTH-1:0]         base;
input  wire [7:0]                  length;
// outputs           
output reg                      out_valid;
output reg  [DATA_WIDTH-1:0]     out_data;
// inputs   
input  wire                      in_valid;
input  wire [DATA_WIDTH-1:0]      in_data;
// fuck it
input wire                     fuck_valid;
input wire [DATA_WIDTH-1:0]          fuck;
//================================================================
//  Wire & Reg
//================================================================
//  FSM
reg  [2:0] current_state, next_state;
//  IS HIT
wire is_data_hit;
wire is_next_data_hit;
//  DATA CACHE : address (1000~1fff) = { 0001_xxxx_xxxx_xx00 } = { 0002_{10'b"tag"}_00 }
reg  [ADDR_WIDTH-1:0]          address;
reg  [1023:0]               valid_data;
wire [11:2]                   tag_data;
//  FLAG
reg  has_last;
//  OUT_CNT
reg  [8:0] out_cnt;
//================================================================
//  SRAM
//================================================================
wire [DATA_WIDTH-1:0] Q_w;
reg in_valid_r;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   in_valid_r <= 0 ;  
    else          in_valid_r <= in_valid ;
end
MEM4 SRAM1( .Q(Q_w), .CLK(clk), .CEN(1'b0), .WEN(!in_valid_r), .A(tag_data), .D(in_data), .OEN(1'b0) );
//================================================================
//  FSM
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     current_state <= S_IDLE ;
    else            current_state <= next_state ;
end
always @(*) begin
    next_state = current_state ;
    case(current_state)
        S_IDLE: begin
            if (en==1) begin
                if (is_data_hit==1)     next_state = S_HIT ; //tk
                else                    next_state = S_SEND ;
            end
        end
        S_SEND: if (arready_m_inf==1)   next_state = S_WAIT ;
        S_WAIT: if (rvalid_m_inf==1)    next_state = S_OUTPT ;
        S_OUTPT: begin //tk
            if (out_cnt>length)         next_state = S_IDLE ;
            else if (rvalid_m_inf==1)   next_state = S_OUTPT ;
            else if (has_last==1) begin
                if (is_next_data_hit==1)     next_state = S_NXTHIT ;
                else                    next_state = S_SEND ;
            end       
            else                        next_state = S_WAIT ;
        end
        S_HIT: begin
            if (out_cnt>length)         next_state = S_BUFFR ;
            else if(is_next_data_hit==1)     next_state = S_HIT ;
            else                        next_state = S_BUFFR ;
        end
        S_BUFFR: begin
            if (out_cnt>length)         next_state = S_IDLE ;
            else                        next_state = S_SEND ;
        end
        S_NXTHIT:   next_state = S_HIT ;
    endcase
end
//================================================================
//  IS HIT
//================================================================
// wire is_data_hit;
assign is_data_hit  = (valid_data[tag_data]==1) ;
assign is_next_data_hit  = (valid_data[tag_data+1]==1) ;
//================================================================
//  DATA CACHE : address (2000~2fff) = { 0010_xxxx_xxxx_xx00 } = { 0002_{10'b"tag"}_00 }
//================================================================
// reg  [ADDR_WIDTH-1:0]          address;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     address <= 0 ;
    else begin
        if (fuck_valid==1)                              address <= fuck ;
        else if (in_valid_r==1 || next_state==S_HIT)    address <= address + 4 ;
        else                                            address <= base + out_cnt*4 ;
    end
end
// reg  [1023:0]               valid_data;
generate
for( idx=0 ; idx<1024 ; idx=idx+1 ) begin : r_DRAM1_valid_data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) valid_data[idx] <= 0 ;
        else begin
            if (in_valid_r==1 && tag_data==idx)     valid_data[idx] <= 1 ;
        end
    end
end
endgenerate
// wire [11:2]                   tag_data;
assign tag_data = address[11:2] ;
//================================================================
//  AXI 4
//================================================================
// axi read address channel 
// output wire [ADDR_WIDTH-1:0] araddr_m_inf;
assign araddr_m_inf = address ;
// output reg  [4-1:0]           arlen_m_inf;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     arlen_m_inf <= 0 ;
    else begin
        if ( (length-out_cnt+1)>=16 )   arlen_m_inf <= 15 ;
        else                            arlen_m_inf <= length - out_cnt ;
    end
end
// output reg                  arvalid_m_inf;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     arvalid_m_inf <= 0 ;
    else begin
        if (next_state==S_SEND)     arvalid_m_inf <= 1 ;
        else                        arvalid_m_inf <= 0 ; 
    end
end
// axi read data channel 
// output wire                  rready_m_inf;
assign rready_m_inf = 1 ;
//================================================================
//  FLAG
//================================================================
// reg  has_last;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     has_last <= 0 ;
    else begin
        if (current_state==S_SEND)  has_last <= 0 ;
        else if (rlast_m_inf==1)    has_last <= 1 ;
    end
end
//================================================================
//  OUTPUT
//================================================================
// output reg                      out_valid;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     out_valid <= 0 ;
    else begin
        if (next_state==S_OUTPT || current_state==S_HIT)    out_valid <= 1 ;
        else                                                out_valid <= 0 ;
    end
end
// output reg  [DATA_WIDTH-1:0]     out_data;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     out_data <= 0 ;
    else begin
        if (next_state==S_OUTPT)    out_data <= rdata_m_inf ;
        else if (next_state==S_HIT || next_state==S_BUFFR) out_data <= Q_w ;
    end
end
//================================================================
//  OUT_CNT
//================================================================
// reg  [8:0] out_cnt;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     out_cnt <= 0 ;
    else begin
        if (next_state==S_OUTPT || next_state==S_HIT)   out_cnt <= out_cnt + 1 ;
        else if (next_state==S_IDLE)                    out_cnt <= 0 ;
    end
end
endmodule





module w_DRAM1(
// global signals 
       clk, rst_n,
// axi write address channel 
     awaddr_m_inf,
    awvalid_m_inf,
    awready_m_inf,
// axi write data channel 
      wdata_m_inf,
      wlast_m_inf,
     wvalid_m_inf,
     wready_m_inf,
// axi write response channel
     bvalid_m_inf,
     bready_m_inf,
// others
             base,
         in_valid,
         in_data
);
//================================================================
//  integer / genvar / parameter
//================================================================
integer i;
//  axi
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 32, DRAM_NUMBER = 2, WRIT_NUMBER = 1 ;
//   FSM
parameter S_IDLE = 2'd0 ;
parameter S_ADDR = 2'd1 ;
parameter S_DATA = 2'd2 ;
parameter S_OUTPT = 2'd3 ;
//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
// global signals 
input   clk, rst_n;
// axi write address channel 
output wire [ADDR_WIDTH-1:0]    awaddr_m_inf;
output reg                     awvalid_m_inf;
input  wire                    awready_m_inf;
// axi write data channel 
output reg [DATA_WIDTH-1:0]      wdata_m_inf;
output reg                       wlast_m_inf;
output reg                      wvalid_m_inf;
input  wire                     wready_m_inf;
// axi write response channel
input  wire                     bvalid_m_inf;
output reg                      bready_m_inf;
// inputs
input  wire [ADDR_WIDTH-1:0]    base;
input  wire                     in_valid;
input  wire [16*DATA_WIDTH-1:0] in_data;
//================================================================
//  Wire & Reg
//================================================================
//  FSM
reg  [1:0] current_state, next_state;
//  OUT_CNT
reg  [3:0] out_cnt;
//================================================================
//   FSM
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   current_state <= S_IDLE ;
    else          current_state <= next_state ;
end
always @(*) begin
    next_state = current_state ;
    case(current_state)
        S_IDLE:     if (in_valid==1)        next_state = S_ADDR ;
        S_ADDR:     if (awready_m_inf==1)   next_state = S_DATA ;
        S_DATA:     if (wlast_m_inf==1)     next_state = S_OUTPT ;
        S_OUTPT:    if (bvalid_m_inf==1)    next_state = S_IDLE ;
    endcase
end
//================================================================
//  AXI 4
//================================================================
// axi write address channel 
assign awaddr_m_inf = base ;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   awvalid_m_inf <= 0 ;
    else begin
        if (next_state==S_ADDR)   awvalid_m_inf <= 1 ;
        else                      awvalid_m_inf <= 0 ;
    end
end
// axi write data channel 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   wdata_m_inf <= 0 ;
    else begin
        if (wready_m_inf==1) begin
            case(out_cnt)
                4'd14:  wdata_m_inf <= in_data[1 *DATA_WIDTH-1:0 *DATA_WIDTH] ;
                4'd13:  wdata_m_inf <= in_data[2 *DATA_WIDTH-1:1 *DATA_WIDTH] ;
                4'd12:  wdata_m_inf <= in_data[3 *DATA_WIDTH-1:2 *DATA_WIDTH] ;
                4'd11:  wdata_m_inf <= in_data[4 *DATA_WIDTH-1:3 *DATA_WIDTH] ;
                4'd10:  wdata_m_inf <= in_data[5 *DATA_WIDTH-1:4 *DATA_WIDTH] ;
                4'd9 :  wdata_m_inf <= in_data[6 *DATA_WIDTH-1:5 *DATA_WIDTH] ;
                4'd8 :  wdata_m_inf <= in_data[7 *DATA_WIDTH-1:6 *DATA_WIDTH] ;
                4'd7 :  wdata_m_inf <= in_data[8 *DATA_WIDTH-1:7 *DATA_WIDTH] ;
                4'd6 :  wdata_m_inf <= in_data[9 *DATA_WIDTH-1:8 *DATA_WIDTH] ;
                4'd5 :  wdata_m_inf <= in_data[10*DATA_WIDTH-1:9 *DATA_WIDTH] ;
                4'd4 :  wdata_m_inf <= in_data[11*DATA_WIDTH-1:10*DATA_WIDTH] ;
                4'd3 :  wdata_m_inf <= in_data[12*DATA_WIDTH-1:11*DATA_WIDTH] ;
                4'd2 :  wdata_m_inf <= in_data[13*DATA_WIDTH-1:12*DATA_WIDTH] ;
                4'd1 :  wdata_m_inf <= in_data[14*DATA_WIDTH-1:13*DATA_WIDTH] ;
                4'd0 :  wdata_m_inf <= in_data[15*DATA_WIDTH-1:14*DATA_WIDTH] ;
            endcase
        end
        else            wdata_m_inf <= in_data[16*DATA_WIDTH-1:15*DATA_WIDTH] ;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   wlast_m_inf <= 0 ;
    else begin
        if (out_cnt==14)  wlast_m_inf <= 1 ;
        else              wlast_m_inf <= 0 ;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   wvalid_m_inf <= 0 ;
    else begin
        if (next_state==S_DATA)   wvalid_m_inf <= 1 ;
        else                      wvalid_m_inf <= 0 ;
    end
end
// axi write response channel
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   bready_m_inf <= 0 ;
    else begin
        if (next_state==S_OUTPT)  bready_m_inf <= 1 ;
        else                      bready_m_inf <= 0 ;
    end
end
//================================================================
//  OUT_CNT
//================================================================
// reg  [8:0] out_cnt;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     out_cnt <= 0 ;
    else begin
        if (wready_m_inf==1)    out_cnt <= out_cnt + 1 ;
    end
end
endmodule
