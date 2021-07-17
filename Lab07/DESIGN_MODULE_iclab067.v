//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Midterm Project: POLISH NOTATION (PN)
//   Author         : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : DESIGN_MODULE.v
//   Module Name : CLK_1_MODULE / CLK_2_MODULE / CLK_3_MODULE
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CLK_1_MODULE(
/* ----------------------- Input signals ----------------------- */
	clk_1,
	clk_2,
	rst_n,
	in_valid,
	in,
	mode,
	operator,
/* ---------------------- Output signals ----------------------- */
	clk1_in_0,  clk1_in_1,  clk1_in_2,  clk1_in_3,  clk1_in_4,  clk1_in_5,  clk1_in_6,  clk1_in_7,  clk1_in_8,  clk1_in_9, 
	clk1_in_10, clk1_in_11, clk1_in_12, clk1_in_13, clk1_in_14, clk1_in_15, clk1_in_16, clk1_in_17, clk1_in_18, clk1_in_19,
	clk1_op_0,  clk1_op_1,  clk1_op_2,  clk1_op_3,  clk1_op_4,  clk1_op_5,  clk1_op_6,  clk1_op_7,  clk1_op_8,  clk1_op_9, 
	clk1_op_10, clk1_op_11, clk1_op_12, clk1_op_13, clk1_op_14, clk1_op_15, clk1_op_16, clk1_op_17, clk1_op_18, clk1_op_19,
	clk1_expression_0, clk1_expression_1, clk1_expression_2,
	clk1_operators_0, clk1_operators_1, clk1_operators_2,
	clk1_mode,
	clk1_control_signal,
	clk1_flag_0,  clk1_flag_1,  clk1_flag_2,  clk1_flag_3,  clk1_flag_4,  clk1_flag_5,  clk1_flag_6,  clk1_flag_7, 
	clk1_flag_8,  clk1_flag_9,  clk1_flag_10, clk1_flag_11, clk1_flag_12, clk1_flag_13, clk1_flag_14, clk1_flag_15, 
	clk1_flag_16, clk1_flag_17, clk1_flag_18, clk1_flag_19
);
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================		
/* ----------------------- Input signals ----------------------- */
// global signals
input clk_1, clk_2, rst_n;
// design
input in_valid, operator, mode;
input [2:0] in;
/* ---------------------- Output signals ----------------------- */
// in
output reg [2:0] clk1_in_0,  clk1_in_1,  clk1_in_2,  clk1_in_3,  clk1_in_4,  clk1_in_5,  clk1_in_6,  clk1_in_7,  clk1_in_8,  clk1_in_9, 
				 clk1_in_10, clk1_in_11, clk1_in_12, clk1_in_13, clk1_in_14, clk1_in_15, clk1_in_16, clk1_in_17, clk1_in_18, clk1_in_19;
// operatior
output reg clk1_op_0,  clk1_op_1,  clk1_op_2,  clk1_op_3,  clk1_op_4,  clk1_op_5,  clk1_op_6,  clk1_op_7,  clk1_op_8,  clk1_op_9, 
		   clk1_op_10, clk1_op_11, clk1_op_12, clk1_op_13, clk1_op_14, clk1_op_15, clk1_op_16, clk1_op_17, clk1_op_18, clk1_op_19;
// in (20 cycles)
output reg [59:0] clk1_expression_0, clk1_expression_1, clk1_expression_2;
// operator (20 cycles)
output reg [19:0] clk1_operators_0, clk1_operators_1, clk1_operators_2;
// mode
output reg clk1_mode;
// 
output reg [19:0] clk1_control_signal;
// a flag signal to inform CLK_2_MODULE that it can read input signal from CLK_1_MODULE.
output reg clk1_flag_0,  clk1_flag_1,  clk1_flag_2,  clk1_flag_3,  clk1_flag_4,  clk1_flag_5,  clk1_flag_6,  clk1_flag_7, 
	   	   clk1_flag_8,  clk1_flag_9,  clk1_flag_10, clk1_flag_11, clk1_flag_12, clk1_flag_13, clk1_flag_14, clk1_flag_15, 
	   	   clk1_flag_16, clk1_flag_17, clk1_flag_18, clk1_flag_19;
//================================================================
//  integer / genvar / parameter
//================================================================
integer i;
genvar idx;
//================================================================
//  Wire & Reg
//================================================================
reg in_valid_r, operator_r, mode_r;
reg [2:0] in_r;
reg is_finish_r;
// 
wire in_valid_w, operator_w, mode_w;
wire [2:0] in_w;
wire is_finish_w;
//================================================================
//  DESIGN                         
//================================================================
//---------------------------------------------------------------------
//   TA hint:
//	  Please write a synchroniser using syn_XOR or doubole flop synchronizer design in CLK_1_MODULE to generate a flag signal to inform CLK_2_MODULE that it can read input signal from CLK_1_MODULE.
//	  You don't need to include syn_XOR.v file or synchronizer.v file by yourself, we have already done that in top module CDC.v
//	  example:
//   syn_XOR syn_1(.IN(inflag_clk1),.OUT(clk1_flag_0),.TX_CLK(clk_1),.RX_CLK(clk_2),.RST_N(rst_n));             
//---------------------------------------------------------------------	
//================================================================
//  STEP 1 : Filter Unknown Value
//================================================================
always @(posedge clk_1 or negedge rst_n) begin
	if (!rst_n) 	in_valid_r <= 0 ;
	else 			in_valid_r <= in_valid ;
end
always @(posedge clk_1 or negedge rst_n) begin
	if (!rst_n) 			operator_r <= 0 ;
	else begin
		if (in_valid==1)	operator_r <= operator ;
		else 				operator_r <= 0 ;
	end
end
always @(posedge clk_1 or negedge rst_n) begin
	if (!rst_n) 			mode_r <= 0 ;
	else begin
		if (in_valid==1 && in_valid_r==0)	mode_r <= mode ;
		else 				mode_r <= 0 ;
	end
end
always @(posedge clk_1 or negedge rst_n) begin
	if (!rst_n) 			in_r <= 0 ;
	else begin
		if (in_valid==1)	in_r <= in ;
		else 				in_r <= 0 ;
	end
end
always @(posedge clk_1 or negedge rst_n) begin
	if (!rst_n) 			is_finish_r <= 0 ;
	else begin
		if (in_valid==0 && in_valid_r==1)	is_finish_r <= 1 ;
		else 				is_finish_r <= 0 ;
	end
end
//================================================================
//  STEP 2 : Double Flop (2-FF) Synchronizer
//================================================================
syn_XOR syn_in_valid( .IN(in_valid_r) , .OUT(in_valid_w) , .TX_CLK(clk_1) , .RX_CLK(clk_2) , .RST_N(rst_n) );
syn_XOR syn_operator( .IN(operator_r) , .OUT(operator_w) , .TX_CLK(clk_1) , .RX_CLK(clk_2) , .RST_N(rst_n) );
syn_XOR syn_mode( .IN(mode_r) , .OUT(mode_w) , .TX_CLK(clk_1) , .RX_CLK(clk_2) , .RST_N(rst_n) );
generate
for( idx=0 ; idx<3 ; idx=idx+1 )
	syn_XOR syn_in( .IN(in_r[idx]) , .OUT(in_w[idx]) , .TX_CLK(clk_1) , .RX_CLK(clk_2) , .RST_N(rst_n) );
endgenerate
syn_XOR syn_is_finish( .IN(is_finish_r) , .OUT(is_finish_w) , .TX_CLK(clk_1) , .RX_CLK(clk_2) , .RST_N(rst_n) );
//================================================================
//  STEP 3 : Output
//================================================================
always @(posedge clk_2 or negedge rst_n) begin
	if (!rst_n) 	clk1_flag_0 <= 0 ;
	else 			clk1_flag_0 <= in_valid_w ;
end

always @(posedge clk_2 or negedge rst_n) begin
	if (!rst_n)		clk1_op_0 <= 0 ;
	else 			clk1_op_0 <= operator_w ;
end

always @(posedge clk_2 or negedge rst_n) begin
	if (!rst_n) 	clk1_mode <= 0 ;
	else 			clk1_mode <= mode_w ;
end

always @(posedge clk_2 or negedge rst_n) begin
	if (!rst_n) 	clk1_in_0 <= 0 ;
	else 			clk1_in_0 <= in_w ;
end

always @(posedge clk_2 or negedge rst_n) begin
	if (!rst_n) 	clk1_flag_1 <= 0 ;
	else 			clk1_flag_1 <= is_finish_w ;
end

endmodule



module CLK_2_MODULE(
/* ----------------------- Input signals ----------------------- */
	clk_2,
	clk_3,
	rst_n,
	clk1_in_0,  clk1_in_1,  clk1_in_2,  clk1_in_3,  clk1_in_4,  clk1_in_5,  clk1_in_6,  clk1_in_7,  clk1_in_8,  clk1_in_9, 
	clk1_in_10, clk1_in_11, clk1_in_12, clk1_in_13, clk1_in_14, clk1_in_15, clk1_in_16, clk1_in_17, clk1_in_18, clk1_in_19,
	clk1_op_0,  clk1_op_1,  clk1_op_2,  clk1_op_3,  clk1_op_4,  clk1_op_5,  clk1_op_6,  clk1_op_7,  clk1_op_8,  clk1_op_9, 
	clk1_op_10, clk1_op_11, clk1_op_12, clk1_op_13, clk1_op_14, clk1_op_15, clk1_op_16, clk1_op_17, clk1_op_18, clk1_op_19,
	clk1_expression_0, clk1_expression_1, clk1_expression_2,
	clk1_operators_0, clk1_operators_1, clk1_operators_2,
	clk1_mode,
	clk1_control_signal,
	clk1_flag_0,  clk1_flag_1,  clk1_flag_2,  clk1_flag_3,  clk1_flag_4,  clk1_flag_5,  clk1_flag_6,  clk1_flag_7, 
	clk1_flag_8,  clk1_flag_9,  clk1_flag_10, clk1_flag_11, clk1_flag_12, clk1_flag_13, clk1_flag_14, clk1_flag_15, 
	clk1_flag_16, clk1_flag_17, clk1_flag_18, clk1_flag_19,
/* ---------------------- Output signals ----------------------- */
	clk2_out_0, clk2_out_1, clk2_out_2, clk2_out_3,
	clk2_mode,
	clk2_control_signal,
	clk2_flag_0, clk2_flag_1, clk2_flag_2, clk2_flag_3, clk2_flag_4, clk2_flag_5, clk2_flag_6, clk2_flag_7
);
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================	
/* ----------------------- Input signals ----------------------- */
// global signals
input clk_2, clk_3, rst_n;
// in
input [2:0] clk1_in_0,  clk1_in_1,  clk1_in_2,  clk1_in_3,  clk1_in_4,  clk1_in_5,  clk1_in_6,  clk1_in_7,  clk1_in_8,  clk1_in_9, 
	 	    clk1_in_10, clk1_in_11, clk1_in_12, clk1_in_13, clk1_in_14, clk1_in_15, clk1_in_16, clk1_in_17, clk1_in_18, clk1_in_19;
// operatior
input clk1_op_0,  clk1_op_1,  clk1_op_2,  clk1_op_3,  clk1_op_4,  clk1_op_5,  clk1_op_6,  clk1_op_7,  clk1_op_8,  clk1_op_9, 
  	  clk1_op_10, clk1_op_11, clk1_op_12, clk1_op_13, clk1_op_14, clk1_op_15, clk1_op_16, clk1_op_17, clk1_op_18, clk1_op_19;
// in (20 cycles)
input [59:0] clk1_expression_0, clk1_expression_1, clk1_expression_2;
// operator (20 cycles)
input [19:0] clk1_operators_0, clk1_operators_1, clk1_operators_2;
// mode
input clk1_mode;
input [19 :0] clk1_control_signal;
// a flag signal to inform CLK_2_MODULE that it can read input signal from CLK_1_MODULE.
input clk1_flag_0,  clk1_flag_1,  clk1_flag_2,  clk1_flag_3,  clk1_flag_4,  clk1_flag_5,  clk1_flag_6,  clk1_flag_7, 
	  clk1_flag_8,  clk1_flag_9,  clk1_flag_10, clk1_flag_11, clk1_flag_12, clk1_flag_13, clk1_flag_14, clk1_flag_15, 
	  clk1_flag_16, clk1_flag_17, clk1_flag_18, clk1_flag_19;
/* ---------------------- Output signals ----------------------- */
// 
output reg [63:0] clk2_out_0, clk2_out_1, clk2_out_2, clk2_out_3;
// mode
output reg clk2_mode;
// 
output reg [8:0] clk2_control_signal;
// a flag signal to inform CLK_3_MODULE that it can read input signal from CLK_2_MODULE.
output reg clk2_flag_0, clk2_flag_1, clk2_flag_2, clk2_flag_3, clk2_flag_4, clk2_flag_5, clk2_flag_6, clk2_flag_7;
//================================================================
//  integer / genvar / parameter
//================================================================
integer i;
genvar idx;
// 	mode
parameter MODE_PREFIX  = 0 ;
parameter MODE_POSTFIX = 1 ;
// 	operators
parameter OP_ADD = 3'b000 ;
parameter OP_SUB = 3'b001 ;
parameter OP_MUL = 3'b010 ;
parameter OP_ABS = 3'b011 ;
parameter OP_TWO = 3'b100 ;
//  FSM    
parameter STATE_IDLE  = 3'd0 ;
parameter STATE_INPUT = 3'd1 ;
parameter STATE_CALCU = 3'd2 ;
parameter STATE_OUTPT = 3'd3 ;
parameter STATE_REV_SHIFT = 3'd4 ;
parameter STATE_REV_CALCU = 3'd5 ;
parameter STATE_REV_BACK  = 3'd6 ;
//================================================================
//  Wire & Reg
//================================================================
//  FSM    
reg [2:0] current_state, next_state;
//  INFORMATIONS    
reg is_finish;                     
reg [4:0] in_cnt;
reg mode;
reg operator_vec[20:0];
reg signed [31:0] in_vec[20:0];
//  CHECK
wire [0:2] op_012;
wire is_hit;
wire signed [31:0] a, b, op;
//  STATE_CALCU                         
reg [31:0] next_value;
// 	STATE_OUTPT
reg out_valid_r;
wire out_valid_w;
reg signed [31:0] out_r;
wire [31:0] out_w;
//  STATE_REV
reg [4:0] rev_cnt;
//================================================================
//  DESIGN                         
//================================================================
//---------------------------------------------------------------------
//   TA hint:
//	  Please write a synchroniser using syn_XOR or doubole flop synchronizer design in CLK_2_MODULE to generate a flag signal to inform CLK_3_MODULE that it can read input signal from CLK_2_MODULE.
//	  You don't need to include syn_XOR.v file or synchronizer.v file by yourself, we have already done that in top module CDC.v
//	  example:
//   syn_XOR syn_2(.IN(inflag_clk2),.OUT(clk2_flag_0),.TX_CLK(clk_2),.RX_CLK(clk_3),.RST_N(rst_n));             
//---------------------------------------------------------------------	
//================================================================
//  FSM                         
//================================================================
always @(posedge clk_2 or negedge rst_n) begin
	if (!rst_n) 	current_state <= STATE_IDLE ;
	else 			current_state <= next_state ;
end
always @(*) begin
	next_state = current_state ;
	case(current_state) 
		STATE_IDLE:	begin
			if (clk1_flag_0==1)					next_state = STATE_INPUT ;
			else if (is_finish==1) begin
				if (in_cnt==1)	next_state = STATE_OUTPT ;
				else 			next_state = STATE_REV_SHIFT ;
			end
		end	
		STATE_INPUT: begin
			if (is_hit==1)	next_state = STATE_CALCU ;
			else 			next_state = STATE_IDLE ;
		end
		STATE_CALCU: begin
			if (clk1_flag_0==1)		next_state = STATE_INPUT ;
			else if (is_hit==1)		next_state = STATE_CALCU ;
			else 					next_state = STATE_IDLE ;
		end	
		STATE_OUTPT: 	next_state = STATE_IDLE ;
		// 
		STATE_REV_SHIFT: 	if (is_hit==1)	next_state = STATE_REV_CALCU ;
		STATE_REV_CALCU: begin
			if (in_cnt==1)		next_state = STATE_OUTPT ;
			else if (is_hit==0)	next_state = STATE_REV_BACK ;
		end	
		STATE_REV_BACK:		if (is_hit==1)	next_state = STATE_REV_CALCU ;
	endcase
end
//================================================================
//  INFORMATIONS                         
//================================================================
// reg is_finish;      
always @(posedge clk_2 or negedge rst_n) begin
	if (!rst_n) 	is_finish <= 0 ;
	else begin
		if (clk1_flag_1==1)					is_finish <= 1 ;
		else if (next_state==STATE_OUTPT)	is_finish <= 0 ;
	end
end               
// reg [4:0] in_cnt;
always @(posedge clk_2 or negedge rst_n) begin
	if (!rst_n) 	in_cnt <= 0 ;
	else begin
		if (clk1_flag_0==1) 				in_cnt <= in_cnt + 1 ;
		else if (next_state==STATE_CALCU || next_state==STATE_REV_CALCU)	in_cnt <= in_cnt - 2 ;
		else if (next_state==STATE_OUTPT)	in_cnt <= 0 ;
	end
end
// reg mode;
always @(posedge clk_2 or negedge rst_n) begin
	if (!rst_n) 	mode <= 0 ;
	else begin
		if (clk1_flag_0==1 && in_cnt==0)	mode <= clk1_mode ;
	end
end
// reg operator_vec[0:20];
always @(posedge clk_2 or negedge rst_n) begin
	if (!rst_n) begin
		for( i=0 ; i<=20 ; i=i+1 )
			operator_vec[i] <= 0 ;
	end
	else begin
		if (next_state==STATE_INPUT) begin
			operator_vec[0] <= clk1_op_0 ;
			for( i=1 ; i<=20 ; i=i+1 )
				operator_vec[i] <= operator_vec[i-1] ;
		end
		else if (next_state==STATE_CALCU) begin
			operator_vec[0] <= 0 ;
			for( i=1 ; i<=18 ; i=i+1 )
				operator_vec[i] <= operator_vec[i+2] ;
		end
		else if (next_state==STATE_REV_SHIFT) begin
			operator_vec[20] <= operator_vec[0] ;
			for( i=0 ; i<=19 ; i=i+1 )
				operator_vec[i] <= operator_vec[i+1] ;
		end
		else if (next_state==STATE_REV_CALCU) begin
			operator_vec[0] <= 0 ;
			for( i=1 ; i<=18 ; i=i+1 )
				if ( (20-i)>rev_cnt )
					operator_vec[i] <= operator_vec[i+2] ;
		end
		else if (next_state==STATE_REV_BACK) begin
			operator_vec[0] <= operator_vec[20] ;
			for( i=1 ; i<=20 ; i=i+1 )
				operator_vec[i] <= operator_vec[i-1] ;
		end
		else if (next_state==STATE_OUTPT) begin
			for( i=0 ; i<=20 ; i=i+1 )
				operator_vec[i] <= 0 ;
		end
	end
end
// reg signed [31:0] in_vec[0:20];
always @(posedge clk_2 or negedge rst_n) begin
	if (!rst_n) begin
		for( i=0 ; i<=20 ; i=i+1 )
			in_vec[i] <= 0 ;
	end
	else begin
		if (next_state==STATE_INPUT) begin
			in_vec[0] <= clk1_in_0 ;
			for( i=1 ; i<=20 ; i=i+1 )
				in_vec[i] <= in_vec[i-1] ;
		end
		else if (next_state==STATE_CALCU) begin
			in_vec[0] <= next_value ;
			for( i=1 ; i<=18 ; i=i+1 )
				in_vec[i] <= in_vec[i+2] ;
		end
		else if (next_state==STATE_REV_SHIFT) begin
			in_vec[20] <= in_vec[0] ;
			for( i=0 ; i<=19 ; i=i+1 )
				in_vec[i] <= in_vec[i+1] ;
		end
		else if (next_state==STATE_REV_CALCU) begin
			in_vec[0] <= next_value ;
			for( i=1 ; i<=18 ; i=i+1 )
				if ( (20-i)>rev_cnt )
					in_vec[i] <= in_vec[i+2] ;
		end
		else if (next_state==STATE_REV_BACK) begin
			in_vec[0] <= in_vec[20] ;
			for( i=1 ; i<=20 ; i=i+1 )
				in_vec[i] <= in_vec[i-1] ;
		end
		else if (next_state==STATE_OUTPT) begin
			for( i=0 ; i<=20 ; i=i+1 )
				in_vec[i] <= 0 ;
		end
	end
end
//================================================================
//  STATE_REV
//================================================================
always @(posedge clk_2 or negedge rst_n) begin
	if (!rst_n) 	rev_cnt <= 0 ;
	else begin
		if (next_state==STATE_REV_SHIFT)		rev_cnt <= rev_cnt + 1 ;
		else if (next_state==STATE_REV_BACK)	rev_cnt <= rev_cnt - 1 ;
		else if (next_state==STATE_OUTPT)		rev_cnt <= 0 ;
	end
end
//================================================================
//  CHECK                         
//================================================================
assign op_012 = { operator_vec[2] , operator_vec[1] , operator_vec[0] } ;
assign is_hit = (mode==MODE_PREFIX) ? (op_012==3'b100) : (op_012==3'b001) ;
//================================================================
//  ALU                         
//================================================================
assign a  = (mode==MODE_PREFIX) ? in_vec[1] : in_vec[2] ;
assign b  = (mode==MODE_PREFIX) ? in_vec[0] : in_vec[1] ;
assign op = (mode==MODE_PREFIX) ? in_vec[2] : in_vec[0] ;
always @(*) begin
	case(op)
		OP_ADD:		next_value = a + b ;
		OP_SUB:		next_value = a - b ;
		OP_MUL:		next_value = a * b ;
		OP_ABS:		next_value = ((a+b)>=0) ? (a+b) : (a+b)*(-1) ;
		OP_TWO:		next_value = ( a - b )<<1 ;
		default: 	next_value = 0 ;
	endcase
end
//================================================================
//  STATE_OUTPT                         
//================================================================
always @(posedge clk_2 or negedge rst_n) begin
	if (!rst_n) 						out_valid_r <= 0 ;
	else begin 
		if (next_state==STATE_OUTPT)	out_valid_r <= 1 ;
		else 							out_valid_r <= 0 ;
	end
end
syn_XOR syn_out_valid( .IN(out_valid_r) , .OUT(out_valid_w) , .TX_CLK(clk_2) , .RX_CLK(clk_3) , .RST_N(rst_n) );
always @(posedge clk_2 or negedge rst_n) begin
	if (!rst_n) 						out_r <= 0 ;
	else begin 
		if (next_state==STATE_OUTPT) 	out_r <= in_vec[0] ;
		else 							out_r <= 0 ;
	end
end
generate
for( idx=0 ; idx<32 ; idx=idx+1 )
	syn_XOR syn_out( .IN(out_r[idx]) , .OUT(out_w[idx]) , .TX_CLK(clk_2) , .RX_CLK(clk_3) , .RST_N(rst_n) );
endgenerate
//================================================================
//  OUTPUT                         
//================================================================
always @(posedge clk_3 or negedge rst_n) begin
	if (!rst_n) 	clk2_flag_0 <= 0 ;
	else 			clk2_flag_0 <= out_valid_w ;
end
always @(posedge clk_3 or negedge rst_n) begin
	if (!rst_n)		clk2_out_0 <= 0 ;
	else 			clk2_out_0 <= { {32{out_w[31]}} , out_w } ;
end
endmodule



module CLK_3_MODULE(
/* ----------------------- Input signals ----------------------- */
	// global signals
	clk_3,
	rst_n,
	clk2_out_0, clk2_out_1, clk2_out_2, clk2_out_3,
	clk2_mode,
	clk2_control_signal,
	clk2_flag_0, clk2_flag_1, clk2_flag_2, clk2_flag_3, clk2_flag_4, clk2_flag_5, clk2_flag_6, clk2_flag_7,
/* ---------------------- Output signals ----------------------- */
	out_valid,
	out	
);
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================			
/* ----------------------- Input signals ----------------------- */
input clk_3, rst_n;
// 
input [63:0] clk2_out_0, clk2_out_1, clk2_out_2, clk2_out_3;
// mode
input clk2_mode;
// 
input [8:0] clk2_control_signal;
// a flag signal to inform CLK_3_MODULE that it can read input signal from CLK_2_MODULE.
input clk2_flag_0, clk2_flag_1, clk2_flag_2, clk2_flag_3, clk2_flag_4, clk2_flag_5, clk2_flag_6, clk2_flag_7;
/* ---------------------- Output signals ----------------------- */
output reg out_valid;
output reg [63:0] out; 		
//================================================================
//  DESIGN                         
//================================================================
always @(posedge clk_3 or negedge rst_n) begin
	if (!rst_n) 	out_valid <= 0 ;
	else 			out_valid <= clk2_flag_0 ;
end
always @(posedge clk_3 or negedge rst_n) begin
	if (!rst_n) 				out <= 0 ;
	else begin
		if (clk2_flag_0==1)		out <= clk2_out_0 ;
		else 					out <= 0 ;
	end
end

endmodule
