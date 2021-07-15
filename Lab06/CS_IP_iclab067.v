//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Lab06			: CheckSum Soft IP (CS_IP)
//   Author         : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : CS_IP.v
//   Module Name : CS_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CS_IP
#(parameter WIDTH_DATA = 64, parameter WIDTH_RESULT = 1)
(
	// Input signals
    data,
    in_valid,
    clk,
    rst_n,
	// Output signals
    result,
    out_valid
);
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
input [(WIDTH_DATA-1):0] data;
input in_valid, clk, rst_n;
output reg [(WIDTH_RESULT-1):0] result;
output reg out_valid;
//================================================================
//  DESIGN
//================================================================
generate
// 64|1, 128|1, 256|1
if (WIDTH_RESULT==1) begin : w_r_1
	//================================================================
	//  BUFFER
	//================================================================
	reg flag;
	reg [(WIDTH_DATA-1):0] temp;
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)		flag <= 0 ;
		else 			flag <= in_valid ;
	end
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)		temp <= 0 ;
		else begin
			if (in_valid==1)
				temp <= data ;
		end
	end
	//================================================================
	//  OUTPUT
	//================================================================
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) out_valid <= 0 ;
		else 		out_valid <= flag ;
	end
	integer i;
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)		result <= 0 ;
		else begin
			if (flag==1) begin
				if (temp==0)	result <= 1 ;
				else 			result <= 0 ;
			end
		end
	end
end
// 64|64, 128|128, 256|256
else if (WIDTH_DATA==WIDTH_RESULT) begin : w_d_w_r
	//================================================================
	//  BUFFER
	//================================================================
	reg flag;
	reg [(WIDTH_DATA-1):0] temp;
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)		flag <= 0 ;
		else 			flag <= in_valid ;
	end
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)		temp <= 0 ;
		else begin
			if (in_valid==1)
				temp <= data ;
		end
	end
	//================================================================
	//  OUTPUT
	//================================================================
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)	out_valid <= 0 ;
		else 		out_valid <= flag ;
	end
	integer i;
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) result <= 0 ;
		else begin
			if (flag==1) begin
				for( i=0 ; i<WIDTH_RESULT ; i=i+1 )
					result[i] <= 1 - temp[i] ;
			end
			else 	result <= 0 ;
		end
	end
end
// 64|2, 64|4, 64|8, 64|16, 64|32
else if (WIDTH_DATA==64) begin : w_d_64
	wire [(WIDTH_RESULT-1):0] result_w;
	wire out_valid_w;
	CS_IP_64 #(.WIDTH_RESULT(WIDTH_RESULT))
		U1 ( .data(data), .in_valid(in_valid), .clk(clk), .rst_n(rst_n), .result(result_w), .out_valid(out_valid_w) );
	//================================================================
	//  OUTPUT
	//================================================================
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)	out_valid <= 0 ;
		else 		out_valid <= out_valid_w ;
	end
	integer i;
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) 	result <= 0 ;
		else begin
			if (out_valid_w==1) begin
				for( i=0 ; i<WIDTH_RESULT ; i=i+1 )
					result[i] <= 1 - result_w[i] ;
			end
			else 				result <= 0 ;
		end
	end
end
// 256|128
else if (WIDTH_RESULT==128) begin : w_d_256_w_r_128
	reg [(WIDTH_DATA-1):0] Data;
	reg flag1, flag2, flag3;
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			flag1 <= 0 ;
			flag2 <= 0 ;
			flag3 <= 0 ;
			out_valid <= 0 ;
		end
		else begin
			flag1 <= in_valid ;
			flag2 <= flag1 ;
			flag3 <= flag2 ;
			out_valid <= flag3 ;
		end
	end
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) 	Data <= 0 ;
		else begin
			if (in_valid==1)	Data <= data ;
			else if (flag1==1)	Data <= Data[255:128] + Data[127:0] ;
			else if (flag2==1)	Data <= Data[255:128] + Data[127:0] ;
			else 	Data <= 0 ;
		end
	end
	integer i;
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) 	result <= 0 ;
		else begin
			if (flag3==1) begin
				for( i=0 ; i<WIDTH_RESULT ; i=i+1 )
					result[i] <= 1 - Data[i] ;
			end
			else 		result <= 0 ;
		end
	end
end
// 128|2, 128|4, 128|8, 128|16, 128|32, 128|64
// 256|2, 256|4, 256|8, 256|16, 256|32, 256|64
else begin : w_d_others
	genvar idx;
	localparam NUM_GROUP = WIDTH_DATA/64 ;
	//================================================================
	//   Wires & Registers
	//================================================================
	reg [1:0] current_state, next_state;
	wire [(WIDTH_RESULT-1):0] result_w[(NUM_GROUP-1):0];
	wire out_valid_w[(NUM_GROUP-1):0];
	reg out_valid_r[(NUM_GROUP-1):0];
	wire flag_CS_IP_64;
	reg [(WIDTH_RESULT-1)+3:0] Data;
	wire [(WIDTH_RESULT-1)+3:0] next_Data;
	//================================================================
	//  FSM
	//================================================================
	localparam STATE_IDLE =  2'd0 ;
	localparam STATE_IP64 =  2'd1 ;
	localparam STATE_CALCU = 2'd2 ;
	localparam STATE_OUTPT = 2'd3 ;
	// reg [1:0] current_state, next_state;
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)	current_state <= STATE_IDLE ;
		else 		current_state <= next_state ;
	end
	always @(*) begin
		next_state = current_state ;
		case(current_state)
			STATE_IDLE:		if (flag_CS_IP_64==1)	next_state = STATE_IP64 ;
			STATE_IP64: 	next_state = STATE_CALCU ;
			STATE_CALCU: 	if (Data[(WIDTH_RESULT-1)+3:WIDTH_RESULT]==0)	next_state = STATE_OUTPT ;
			STATE_OUTPT:	next_state = STATE_IDLE ;
			default:		next_state = STATE_IDLE ;
		endcase
	end
	//================================================================
	//  CS_IP_64
	//================================================================
	// wire [(WIDTH_RESULT-1):0] result_w[(NUM_GROUP-1):0];
	// wire out_valid_w[(NUM_GROUP-1):0];
	// reg out_valid_r[(NUM_GROUP-1):0];
	for( idx=0 ; idx<NUM_GROUP ; idx=idx+1 ) begin : func
		CS_IP_64 #(.WIDTH_RESULT(WIDTH_RESULT))
			U1 ( .data(data[((idx+1)*64-1):(idx*64)]), .in_valid(in_valid), .clk(clk), .rst_n(rst_n), .result(result_w[idx]), .out_valid(out_valid_w[idx]) );

		always @(posedge clk or negedge rst_n) begin
			if (!rst_n) 	out_valid_r[idx] <= 0 ;
			else begin
				if (out_valid_w[idx]==1)			out_valid_r[idx] <= 1 ;
				else if (next_state==STATE_OUTPT)	out_valid_r[idx] <= 0 ;
			end
		end
	end
	// wire flag_CS_IP_64;
	if (WIDTH_DATA==128)		assign flag_CS_IP_64 = out_valid_r[0] && out_valid_r[1] ;
	else if (WIDTH_DATA==256)	assign flag_CS_IP_64 = out_valid_r[0] && out_valid_r[1] && out_valid_r[2] && out_valid_r[3] ;
	else/*if (WIDTH_DATA==384)*/assign flag_CS_IP_64 = out_valid_r[0] && out_valid_r[1] && out_valid_r[2] && out_valid_r[3] && out_valid_r[4] && out_valid_r[5] ;
	//================================================================
	//  DATA
	//================================================================
	// wire [(WIDTH_RESULT-1)+3:0] next_Data;
	assign next_Data = Data[(WIDTH_RESULT-1):0] + Data[(WIDTH_RESULT-1)+3:WIDTH_RESULT] ;
	// reg [(WIDTH_RESULT-1)+3:0] Data;l
	if (WIDTH_DATA==128) begin
		always @(posedge clk or negedge rst_n) begin
			if (!rst_n) 	Data <= 0 ;
			else begin
				if (next_state==STATE_IP64)			Data <= result_w[1] + result_w[0] ;
				else if (next_state==STATE_CALCU)	Data <= next_Data ;
			end
		end
	end
	else if (WIDTH_DATA==256) begin
		always @(posedge clk or negedge rst_n) begin
			if (!rst_n) 	Data <= 0 ;
			else begin
				if (next_state==STATE_IP64)			Data <= result_w[3] + result_w[2] + result_w[1] + result_w[0] ;
				else if (next_state==STATE_CALCU)	Data <= next_Data ;
			end
		end
	end
	else /*if (WIDTH_DATA==384)*/ begin
		always @(posedge clk or negedge rst_n) begin
			if (!rst_n) 	Data <= 0 ;
			else begin
				if (next_state==STATE_IP64)			Data <= result_w[5] + result_w[4] + result_w[3] + result_w[2] + result_w[1] + result_w[0] ;
				else if (next_state==STATE_CALCU)	Data <= next_Data ;
			end
		end
	end
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
			if (next_state==STATE_OUTPT) begin
				for( i=0 ; i<WIDTH_RESULT ; i=i+1 )
					result[i] <= 1 - Data[i] ;
			end
			else 		result <= 0 ;
		end
	end
end

endgenerate

endmodule

//================================================================
//  SUBMODULE
//================================================================
module CS_IP_64
#(parameter WIDTH_RESULT = 8)
(
	// Input signals
    data,
    in_valid,
    clk,
    rst_n,
	// Output signals
    result,
    out_valid
);
//================================================================
//  parameter                      
//================================================================
localparam WIDTH_DATA = 64 ;
localparam NUM_GROUP = WIDTH_DATA/WIDTH_RESULT ;
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
input [(WIDTH_DATA-1):0] data;
input in_valid, clk, rst_n;
output reg [(WIDTH_RESULT-1):0] result;
output reg out_valid;
//================================================================
//  DESIGN
//================================================================
generate
if (WIDTH_RESULT==64) begin : w_r_64
	//================================================================
	//  OUTPUT
	//================================================================
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) out_valid <= 0 ;
		else 		out_valid <= in_valid ;
	end
	integer i;
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)		result <= 0 ;
		else begin
			if (in_valid==1) 	result <= data ;
		end
	end
end
else begin : w_r_others
	//================================================================
	//   Wires & Registers 
	//================================================================
	reg [1:0] current_state, next_state;
	// reg [(WIDTH_RESULT-1)+5:0] Data;
	reg [(WIDTH_DATA-1):0] Data;
	wire [(WIDTH_RESULT-1)+5:0] first_Data;
	wire [(WIDTH_RESULT-1)+5:0] next_Data;
	// reg [(WIDTH_DATA-1):0] temp;
	reg flag;
	//================================================================
	//  FSM
	//================================================================
	localparam STATE_IDLE =  2'd0 ;
	localparam STATE_INPUT = 2'd1 ;
	localparam STATE_CALCU = 2'd2 ;
	localparam STATE_OUTPT = 2'd3 ;
	// reg [1:0] current_state, next_state;
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)	current_state <= STATE_IDLE ;
		else 		current_state <= next_state ;
	end
	always @(*) begin
		next_state = current_state ;
		case(current_state)
			STATE_IDLE:		if (flag==1)	next_state = STATE_INPUT ;
			STATE_INPUT:	next_state = STATE_CALCU ;
			STATE_CALCU: 	if (Data[(WIDTH_RESULT-1)+5:WIDTH_RESULT]==0)	next_state = STATE_OUTPT ;
			STATE_OUTPT:	next_state = STATE_IDLE ;
			default:		next_state = STATE_IDLE ;
		endcase
	end
	//================================================================
	//  DEAL WITH INPUT DELAY
	//================================================================
	// reg [(WIDTH_DATA-1):0] temp;
	/*always @(posedge clk or negedge rst_n) begin
		if (!rst_n) 	temp <= 0 ;
		else begin
			if (in_valid==1)	temp <= data ;
		end
	end*/
	// reg flag;
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) 	flag <= 0 ;
		else 			flag <= in_valid ;
	end
	//================================================================
	//  DATA
	//================================================================
	// wire [(WIDTH_RESULT-1)+5:0] next_Data;
	assign next_Data = Data[(WIDTH_RESULT-1):0] + Data[(WIDTH_RESULT-1)+5:WIDTH_RESULT] ;
	// reg [(WIDTH_RESULT-1)+5:0] Data;
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) 	Data <= 0 ;
		else begin
			if (in_valid==1)					Data <= data ;
			else if (next_state==STATE_INPUT)	Data <= first_Data ;
			else if (next_state==STATE_CALCU)	Data <= next_Data ;
		end
	end
	//================================================================
	//  NEXT_DATA
	//================================================================
	// wire [(WIDTH_RESULT-1)+5:0] first_Data;
	if (WIDTH_RESULT==32)		assign first_Data = Data[63:32] + Data[31:0] ;
	else if (WIDTH_RESULT==16)	assign first_Data = Data[63:48] + Data[47:32] + Data[31:16] + Data[15:0] ;
	else if (WIDTH_RESULT==8)	assign first_Data = Data[63:56] + Data[55:48] + Data[47:40] + Data[39:32] +
		 											Data[31:24] + Data[23:16] + Data[15:8]  + Data[7:0] ;
	else if (WIDTH_RESULT==4)	assign first_Data = Data[63:60] + Data[59:56] + Data[55:52] + Data[51:48] +
		 											Data[47:44] + Data[43:40] + Data[39:36] + Data[35:32] +
		 											Data[31:28] + Data[27:24] + Data[23:20] + Data[19:16] +
		 											Data[15:12] + Data[11:8]  + Data[7:4]   + Data[3:0] ;
	else if (WIDTH_RESULT==2)	assign first_Data = Data[63:62] + Data[61:60] + Data[59:58] + Data[57:56] +
		 											Data[55:54] + Data[53:52] + Data[51:50] + Data[49:48] +
		 											Data[47:46] + Data[45:44] + Data[43:42] + Data[41:40] +
		 											Data[39:38] + Data[37:36] + Data[35:34] + Data[33:32] +
		 											Data[31:30] + Data[29:28] + Data[27:26] + Data[25:24] +
		 											Data[23:22] + Data[21:20] + Data[19:18] + Data[17:16] +
		 											Data[15:14] + Data[13:12] + Data[11:10] + Data[9:8] +
		 											Data[7:6]   + Data[5:4]   + Data[3:2]   + Data[1:0] ;
	//================================================================
	//  OUTPUT
	//================================================================
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)		out_valid <= 0 ;
		else begin
			if (next_state==STATE_OUTPT) 	out_valid <= 1 ;
			else 		out_valid <= 0 ;
		end
	end
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) 	result <= 0 ; 
		else begin
			if (next_state==STATE_OUTPT)	result <= Data ;
		end
	end
end

endgenerate
endmodule