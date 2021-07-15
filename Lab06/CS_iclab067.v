//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Lab06			: CheckSum (CS)
//   Author         : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : CS.v
//   Module Name : CS
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
//synopsys translate_off
`include "CS_IP.v"
//synopsys translate_on

module CS
#(parameter WIDTH_DATA_1 = 384, parameter WIDTH_RESULT_1 = 8,
parameter WIDTH_DATA_2 = 128, parameter WIDTH_RESULT_2 = 8)
(
    data,
    in_valid,
    clk,
    rst_n,
    result,
    out_valid
);
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
input [(WIDTH_DATA_1 + WIDTH_DATA_2 - 1):0] data;
input in_valid, clk, rst_n;
output reg [(WIDTH_RESULT_1 + WIDTH_RESULT_2 -1):0] result;
output reg out_valid;
//================================================================
//   Wires & Registers 
//================================================================
genvar idx, kdx;
//  FSM
reg [1:0] current_state, next_state;
//  STATE_CSIP
wire [7:0] result_w[1:0];
wire out_valid_w[1:0];
reg [7:0] result_r[1:0];
reg out_valid_r[1:0];
wire flag;
//  PRE_OUTPUT
wire [(WIDTH_RESULT_1 + WIDTH_RESULT_2 -1):0] next_result;
//================================================================
//  FSM
//================================================================
parameter STATE_IDLE  = 2'd0 ;
parameter STATE_CSIP = 2'd1 ;
// parameter STATE_CSIP2 = 2'd2 ;
parameter STATE_OUTPT = 2'd3 ;
// reg [1:0] current_state, next_state;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)	current_state <= STATE_IDLE ;
	else 		current_state <= next_state ;
end
always @(*) begin
	next_state = current_state ;
	case(current_state)
		STATE_IDLE:		if (in_valid==1)	next_state = STATE_CSIP ;
		STATE_CSIP: 	if (flag==1)	next_state = STATE_OUTPT ;
		STATE_OUTPT:	next_state = STATE_IDLE ;
		default:		next_state = STATE_IDLE ;
	endcase
end
//================================================================
//  STATE_CSIP1
//================================================================
// wire [7:0] result_w[1:0];
// wire out_valid_w[1:0];
CS_IP #(.WIDTH_DATA(384), .WIDTH_RESULT(8))
	CSIP384(	.data(data[511:128]),
    			.in_valid(in_valid),
    			.clk(clk),
    			.rst_n(rst_n),
    			.result(result_w[1]),
    			.out_valid(out_valid_w[1])	);
CS_IP #(.WIDTH_DATA(128), .WIDTH_RESULT(8))
	CSIP128(	.data(data[127:0]),
    			.in_valid(in_valid),
    			.clk(clk),
    			.rst_n(rst_n),
    			.result(result_w[0]),
    			.out_valid(out_valid_w[0])	);
// reg [7:0] result_r[1:0];
// reg out_valid_r[1:0];
generate
for( idx=0 ; idx<2 ; idx=idx+1 ) begin
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) 	out_valid_r[idx] <= 0 ;
		else begin
			if (out_valid_w[idx]==1)			out_valid_r[idx] <= 1 ;
			else if (next_state==STATE_OUTPT)	out_valid_r[idx] <= 0 ;
		end
	end
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) 	result_r[idx] <= 0 ;
		else begin
			if (out_valid_w[idx]==1)			result_r[idx] <= result_w[idx] ;
			else if (next_state==STATE_OUTPT)	result_r[idx] <= 0 ;
		end
	end
end
endgenerate
// wire flag;
assign flag = out_valid_r[1] && out_valid_r[0] ;
//================================================================
//  PRE_OUTPUT
//================================================================
// wire [(WIDTH_RESULT_1 + WIDTH_RESULT_2 -1):0] next_result;
assign next_result = { result_r[1] , result_r[0] };
//================================================================
//  OUTPUT
//================================================================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)		out_valid <= 0 ;
	else begin
		if (next_state==STATE_OUTPT)	out_valid <= 1 ;
		else 		out_valid <= 0 ;
	end
end
integer i;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	result <= 0 ;
	else begin
		if (next_state==STATE_OUTPT)	result <= next_result ;
		else 							result <= 0 ;
	end
end
endmodule
