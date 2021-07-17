//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Lab06			: Series Processing (SP)
//   Author         : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : SP_wocg.v
//   Module Name : SP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module SP(
	// Input signals
	clk,
	rst_n,
	in_valid,
	in_data,
	in_mode,
	// Output signals
	out_valid,
	out_data
);
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
input clk, rst_n, in_valid;
input [2:0] in_mode;
input [8:0] in_data;
output reg out_valid;
output reg [8:0] out_data;
//================================================================
//  integer / genvar / parameter
//================================================================
integer i;
genvar idx;
//	FSM
parameter STATE_IDLE = 3'd0 ;
parameter STATE_MInv = 3'd1 ;
parameter STATE_MMul = 3'd2 ;
parameter STATE_Sort = 3'd3 ;
parameter STATE_Sum  = 3'd4 ;
parameter STATE_OUTPT= 3'd5 ;
//================================================================
//  Wire & Reg
//================================================================
//	FSM
reg [2:0] current_state, next_state;
//	INPUT
reg [2:0] data_cnt;
reg [2:0] mode;
// 	DATA
reg [8:0] a[0:5], b[0:5], c[0:5], d[0:5], e[0:5];

//	SUBMODULE
wire [8:0] next_c, next_e;
//	Step 1. Modular Inversion
reg has_sent_b;
wire out_valid_b;
wire [8:0] next_b;
//	Step 2. Modular Multiplication / Step 4. Sum
reg has_sent_mod;
reg [1:0] mm_stage;
wire [17:0] mul_in_s0[0:2], mul_in_s1[0:2];
reg [17:0] mul_in[0:2];
wire mul_out_valid[0:2];
wire [8:0] mul_out[0:2];
reg is_mod_finish[0:2];
wire is_all_mod_finish;
reg  [8:0] mul_out_s0[0:2], mul_out_s1[0:2];
//	Step 3. Sorting
reg flag_sort1, flag_sort2;
wire [8:0] next_d0, next_d1, next_d2, next_d3, next_d4, next_d5;
//================================================================
//	FSM
//================================================================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	current_state <= STATE_IDLE ;
	else 			current_state <= next_state ;
end
always @(*) begin
	next_state = current_state ;
	case(current_state)
		STATE_IDLE: begin
			if (data_cnt==6) begin
				if (mode[0]==1) 		next_state = STATE_MInv ;
				else if (mode[1]==1)	next_state = STATE_MMul ;
				else if (mode[2]==1)	next_state = STATE_Sort ;
				else 					next_state = STATE_Sum ;
			end
		end
		STATE_MInv: begin
			if (data_cnt==6) begin
				if (mode[1]==1)			next_state = STATE_MMul ;
				else if (mode[2]==1)	next_state = STATE_Sort ;
				else 					next_state = STATE_Sum ;
			end
		end
		STATE_MMul: begin
			if (mm_stage==3 && is_all_mod_finish==1) begin
				if (mode[2]==1)			next_state = STATE_Sort ;
				else 					next_state = STATE_Sum ;
			end
		end
		STATE_Sort:	if (flag_sort2==1)	next_state = STATE_Sum ;
		STATE_Sum: 	if (mm_stage==1 && is_all_mod_finish==1) 	next_state = STATE_OUTPT ;
		STATE_OUTPT:	if (data_cnt==6)	next_state = STATE_IDLE ;
	endcase
end

//================================================================
//	Step 1. Modular Inversion
//================================================================
// reg has_sent_b;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	has_sent_b <= 0 ;
	else begin
		if (next_state==STATE_MInv) begin
			if (has_sent_b==0)			has_sent_b <= 1 ;
			else if (out_valid_b==1)	has_sent_b <= 0 ;
		end
		else 	has_sent_b <= 0 ;
	end
end
ModularInversion U_MI( .clk(clk), .rst_n(rst_n), .in_valid( (!has_sent_b)&&(next_state==STATE_MInv) ), .in_a(a[0]), .out_valid(out_valid_b), .out_b(next_b) );
//================================================================
//	Step 2. Modular Multiplication / Step 4. Sum
//================================================================
// reg has_sent_mod;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	has_sent_mod <= 0 ;
	else begin
		if (next_state==STATE_MMul || next_state==STATE_Sum) begin
			if (has_sent_mod==0)			has_sent_mod <= 1 ;
			else if (is_all_mod_finish==1)	has_sent_mod <= 0 ;
		end
		else 	has_sent_mod <= 0 ;
	end
end
// reg [1:0] mm_stage;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	mm_stage <= 0 ;
	else begin
		if (next_state==STATE_MMul || next_state==STATE_Sum) begin
			if (is_all_mod_finish==1) 			mm_stage <= mm_stage + 1 ;
		end
		else 	mm_stage <= 0 ;
	end
end
// wire [17:0] mul_in_s0[0:2], mul_in_s1[0:2];
assign mul_in_s0[0] = b[1] * b[2] ;    // b[1]*b[2]
assign mul_in_s0[1] = b[3] * b[4] ;    // b[3]*b[4]
assign mul_in_s0[2] = b[5] * b[0] ;    // b[5]*b[0]
assign mul_in_s1[0] = mul_out_s0[0] * mul_out_s0[1] ;    // b[1]*b[2]*b[3]*b[4]
assign mul_in_s1[1] = mul_out_s0[1] * mul_out_s0[2] ;    // b[3]*b[4]*b[5]*b[0]
assign mul_in_s1[2] = mul_out_s0[2] * mul_out_s0[0] ;    // b[1]*b[2]*b[5]*b[0]
// reg [17:0] mul_in;
always @(*) begin
	if (next_state==STATE_MMul) begin
		case(mm_stage)
			2'd0: begin
				mul_in[0] = mul_in_s0[0] ;
				mul_in[1] = mul_in_s0[1] ;
				mul_in[2] = mul_in_s0[2] ;
			end
			2'd1: begin
				mul_in[0] = mul_in_s1[0] ;
				mul_in[1] = mul_in_s1[1] ;
				mul_in[2] = mul_in_s1[2] ;
			end
			2'd2: begin
				mul_in[0] = mul_out_s1[0] * b[5] ;		// c[0]
				mul_in[1] = mul_out_s1[1] * b[1] ;		// c[2]
				mul_in[2] = mul_out_s1[2] * b[3] ;		// c[4]
			end
			2'd3: begin
				mul_in[0] = mul_out_s1[0] * b[0] ;		// c[5]
				mul_in[1] = mul_out_s1[1] * b[2] ;		// c[1]
				mul_in[2] = mul_out_s1[2] * b[4] ;		// c[3]
			end
		endcase
	end
	else begin
		case(mm_stage)
			2'd0: begin
				mul_in[0] = a[0] + b[0] + c[0] + d[0] ;
				mul_in[1] = a[2] + b[2] + c[2] + d[2] ;
				mul_in[2] = a[4] + b[4] + c[4] + d[4] ;
			end
			default: begin
				mul_in[0] = a[5] + b[5] + c[5] + d[5] ;
				mul_in[1] = a[1] + b[1] + c[1] + d[1] ;
				mul_in[2] = a[3] + b[3] + c[3] + d[3] ;
			end
		endcase
	end
end
// wire mul_out_valid[0:2];
// wire [8:0] mul_out[0:2];
// reg is_mod_finish[0:2];
// wire is_all_mod_finish;
generate
for( idx=0 ; idx<3 ; idx=idx+1) begin : mod_func
	Modular509 U_mod( .clk(clk), .rst_n(rst_n), .in_valid( (!has_sent_mod)&&(next_state==STATE_MMul || next_state==STATE_Sum) ), .in(mul_in[idx]), .out_valid(mul_out_valid[idx]), .out(mul_out[idx]) );
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) 	is_mod_finish[idx] <= 0 ;
		else begin
			if (mul_out_valid[idx]==1) 		is_mod_finish[idx] <= 1 ;
			else if (is_all_mod_finish==1)	is_mod_finish[idx] <= 0 ;
		end
	end
end
endgenerate
assign is_all_mod_finish = is_mod_finish[0] && is_mod_finish[1] && is_mod_finish[2] ;
// reg  [8:0] mul_out_s0[0:2], mul_out_s1[0:2];
generate
for( idx=0 ; idx<3 ; idx=idx+1) begin
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) 	mul_out_s0[idx] <= 0 ;
		else if (mul_out_valid[idx]==1 && mm_stage==0)	mul_out_s0[idx] <= mul_out[idx] ;    // b[]*b[] mod p
	end
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) 	mul_out_s1[idx] <= 0 ;
		else if (mul_out_valid[idx]==1 && mm_stage==1)	mul_out_s1[idx] <= mul_out[idx] ;    // b[]*b[]*b[]*b[] mod p
	end
end	
endgenerate
//================================================================
//	Step 3. Sorting
//================================================================
Sort U_Sort( .clk(clk), .rst_n(rst_n), .in0(c[0]), .in1(c[1]), .in2(c[2]), .in3(c[3]), .in4(c[4]), .in5(c[5]), 
			 .out0(next_d0), .out1(next_d1), .out2(next_d2), .out3(next_d3), .out4(next_d4), .out5(next_d5) );
// reg flag_sort1, flag_sort2;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)		flag_sort1 <= 0 ;
	else begin
		if (current_state==STATE_Sort)	flag_sort1 <= 1 ;
		else 		flag_sort1 <= 0 ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)		flag_sort2 <= 0 ;
	else 			flag_sort2 <= flag_sort1 ;
end
//================================================================
//	DATA
//================================================================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for( i=0 ; i<6 ; i=i+1 )
			a[i] <= 0 ;
	end
	else begin
		if (in_valid==1) begin
			a[5] <= in_data ;
			for( i=0 ; i<5 ; i=i+1 )
				a[i] <= a[i+1] ;
		end
		else if (out_valid_b==1) begin
			a[5] <= a[0] ;
			for( i=0 ; i<5 ; i=i+1 )
				a[i] <= a[i+1] ;
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for( i=0 ; i<6 ; i=i+1 )
			b[i] <= 0 ;
	end
	else begin
		if (in_valid==1) begin
			b[5] <= in_data ;
			for( i=0 ; i<5 ; i=i+1 )
				b[i] <= b[i+1] ;
		end
		else if (out_valid_b==1) begin
			b[5] <= next_b ;
			for( i=0 ; i<5 ; i=i+1 )
				b[i] <= b[i+1] ;
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	c[0] <= 0 ;
	else begin
		if (in_valid==1 || out_valid_b==1) 				c[0] <= c[1] ;
		else if (mm_stage==2 && is_mod_finish[0]==1) 	c[0] <= mul_out[0] ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	c[2] <= 0 ;
	else begin
		if (in_valid==1 || out_valid_b==1) 				c[2] <= c[3] ;
		else if (mm_stage==2 && is_mod_finish[1]==1) 	c[2] <= mul_out[1] ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	c[4] <= 0 ;
	else begin
		if (in_valid==1 || out_valid_b==1) 				c[4] <= c[5] ;
		else if (mm_stage==2 && is_mod_finish[2]==1) 	c[4] <= mul_out[2] ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	c[1] <= 0 ;
	else begin
		if (in_valid==1 || out_valid_b==1) 				c[1] <= c[2] ;
		else if (mm_stage==3 && is_mod_finish[0]==1) 	c[1] <= mul_out[1] ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	c[3] <= 0 ;
	else begin
		if (in_valid==1 || out_valid_b==1) 				c[3] <= c[4] ;
		else if (mm_stage==3 && is_mod_finish[1]==1) 	c[3] <= mul_out[2] ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	c[5] <= 0 ;
	else begin
		if (in_valid==1) 			c[5] <= in_data ;
		else if (out_valid_b==1)	c[5] <= next_b ;
		else if (mm_stage==3 && is_mod_finish[2]==1) 	c[5] <= mul_out[0] ;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	d[0] <= 0 ;
	else begin
		if (in_valid==1 || out_valid_b==1) 				d[0] <= d[1] ;
		else if (mm_stage==2 && is_mod_finish[0]==1) 	d[0] <= mul_out[0] ;
		else if (current_state==STATE_Sort)				d[0] <= next_d0 ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	d[2] <= 0 ;
	else begin
		if (in_valid==1 || out_valid_b==1) 				d[2] <= d[3] ;
		else if (mm_stage==2 && is_mod_finish[1]==1) 	d[2] <= mul_out[1] ;
		else if (current_state==STATE_Sort)				d[2] <= next_d2 ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	d[4] <= 0 ;
	else begin
		if (in_valid==1 || out_valid_b==1) 				d[4] <= d[5] ;
		else if (mm_stage==2 && is_mod_finish[2]==1) 	d[4] <= mul_out[2] ;
		else if (current_state==STATE_Sort)				d[4] <= next_d4 ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	d[1] <= 0 ;
	else begin
		if (in_valid==1 || out_valid_b==1) 				d[1] <= d[2] ;
		else if (mm_stage==3 && is_mod_finish[0]==1) 	d[1] <= mul_out[1] ;
		else if (current_state==STATE_Sort)				d[1] <= next_d1 ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	d[3] <= 0 ;
	else begin
		if (in_valid==1 || out_valid_b==1) 				d[3] <= d[4] ;
		else if (mm_stage==3 && is_mod_finish[1]==1) 	d[3] <= mul_out[2] ;
		else if (current_state==STATE_Sort)				d[3] <= next_d3 ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	d[5] <= 0 ;
	else begin
		if (in_valid==1) 			d[5] <= in_data ;
		else if (out_valid_b==1)	d[5] <= next_b ;
		else if (mm_stage==3 && is_mod_finish[2]==1) 	d[5] <= mul_out[0] ;
		else if (current_state==STATE_Sort)				d[5] <= next_d5 ;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	e[0] <= 0 ;
	else begin
		if (in_valid==1 || out_valid_b==1) 				e[0] <= e[1] ;
		else if (mm_stage==2 && is_mod_finish[0]==1) 	e[0] <= mul_out[0] ;
		else if (current_state==STATE_Sort)				e[0] <= next_d0 ;
		else if (current_state==STATE_Sum && mm_stage==0 && is_mod_finish[0]==1) 	e[0] <= mul_out[0] ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	e[2] <= 0 ;
	else begin
		if (in_valid==1 || out_valid_b==1) 				e[2] <= e[3] ;
		else if (mm_stage==2 && is_mod_finish[1]==1) 	e[2] <= mul_out[1] ;
		else if (current_state==STATE_Sort)				e[2] <= next_d2 ;
		else if (current_state==STATE_Sum && mm_stage==0 && is_mod_finish[1]==1) 	e[2] <= mul_out[1] ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	e[4] <= 0 ;
	else begin
		if (in_valid==1 || out_valid_b==1) 				e[4] <= e[5] ;
		else if (mm_stage==2 && is_mod_finish[2]==1) 	e[4] <= mul_out[2] ;
		else if (current_state==STATE_Sort)				e[4] <= next_d4 ;
		else if (current_state==STATE_Sum && mm_stage==0 && is_mod_finish[2]==1) 	e[4] <= mul_out[2] ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	e[1] <= 0 ;
	else begin
		if (in_valid==1 || out_valid_b==1) 				e[1] <= e[2] ;
		else if (mm_stage==3 && is_mod_finish[0]==1) 	e[1] <= mul_out[1] ;
		else if (current_state==STATE_Sort)				e[1] <= next_d1 ;
		else if (current_state==STATE_Sum && mm_stage==1 && is_mod_finish[0]==1) 	e[1] <= mul_out[1] ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	e[3] <= 0 ;
	else begin
		if (in_valid==1 || out_valid_b==1) 				e[3] <= e[4] ;
		else if (mm_stage==3 && is_mod_finish[1]==1) 	e[3] <= mul_out[2] ;
		else if (current_state==STATE_Sort)				e[3] <= next_d3 ;
		else if (current_state==STATE_Sum && mm_stage==1 && is_mod_finish[1]==1) 	e[3] <= mul_out[2] ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	e[5] <= 0 ;
	else begin
		if (in_valid==1) 			e[5] <= in_data ;
		else if (out_valid_b==1)	e[5] <= next_b ;
		else if (mm_stage==3 && is_mod_finish[2]==1) 	e[5] <= mul_out[0] ;
		else if (current_state==STATE_Sort)				e[5] <= next_d5 ;
		else if (current_state==STATE_Sum && mm_stage==1 && is_mod_finish[2]==1) 	e[5] <= mul_out[0] ;
	end
end
//================================================================
//	INPUT
//================================================================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)		data_cnt <= 0 ;
	else begin
		if (data_cnt==6) 	data_cnt <= 0 ;
		else if (in_valid==1)	data_cnt <= data_cnt + 1 ;
		else if (out_valid_b==1)	data_cnt <= data_cnt + 1 ;
		else if (next_state==STATE_OUTPT)	data_cnt <= data_cnt + 1 ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	mode <= 0 ;
	else begin
		if (in_valid==1 && data_cnt==0)	
			mode <= in_mode ;
	end
end
//================================================================
//	OUTPUT                         
//================================================================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	out_valid <= 0 ;
	else begin
		if (next_state==STATE_OUTPT) 	out_valid <= 1 ;
		else 		out_valid <= 0 ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	out_data <= 0 ;
	else begin
		if (next_state==STATE_OUTPT)	out_data <= e[data_cnt];
		else 		out_data <= 0 ;
	end
end
endmodule


//================================================================
//	SUBMODULE
//================================================================
module Modular509(clk, rst_n, in_valid, in, out_valid, out);
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
input clk, rst_n;
input in_valid;
input [17:0] in;
output reg out_valid;
output [8:0] out;
//================================================================
//  integer / genvar / parameter
//================================================================
//	FSM
parameter S_IDLE  = 3'd0 ;
parameter S_INPUT = 3'd1 ;
parameter S_CALCU = 3'd2 ;
parameter S_OUTPT = 3'd3 ;
//================================================================
//    Wire & Registers 
//================================================================
//	FSM
reg [1:0] current_state, next_state;
//  DESIGN                         
reg [11:0] in_r;
wire [2:0] overflow;
wire [8:0] nonoverflow;
//================================================================
//	FSM
//================================================================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	current_state <= S_IDLE ;
	else 			current_state <= next_state ;
end
always @(*) begin
	next_state = current_state ;
	case(current_state)
		S_IDLE: 	if (in_valid==1) 	next_state = S_INPUT ;
		S_INPUT: 	next_state = S_CALCU ;
		S_CALCU: 	if (in_r<509)		next_state = S_OUTPT ;
		S_OUTPT: 	next_state = S_IDLE ;
	endcase
end
//================================================================
//  DESIGN                         
//================================================================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	in_r <= 0 ;
	else begin
		if (next_state==S_INPUT)		in_r <= in[8:0] + in[17:9]*3 ;
		else if (next_state==S_CALCU)	in_r <= (in_r>=509) ? in_r - 509 : in_r ;
	end
end
//================================================================
//  OUTPUT
//================================================================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	out_valid <= 0 ;
	else begin
		if (next_state==S_OUTPT) 	out_valid <= 1 ;
		else 						out_valid <= 0 ;
	end
end
assign out = in_r ;
endmodule



module ModularInversion(
	clk, 
	rst_n, 
	in_valid, 
	in_a, 
	out_valid, 
	out_b
);
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
input clk, rst_n;
input in_valid;
input [8:0] in_a;
output reg out_valid;
output reg [8:0] out_b;
//================================================================
//  integer / genvar / parameter
//================================================================
//	FSM
parameter S_IDLE  = 2'd0 ;
parameter S_CALCU = 2'd1 ;
parameter S_MODUL = 2'd2 ;
parameter S_OUTPT = 2'd3 ;
//================================================================
//    Wire & Registers 
//================================================================
//	FSM
reg [2:0] current_state, next_state;
//  DESIGN                         
reg [17:0] A, B;
reg [3:0] cnt;
//	MODULAR 507
wire out_valid_A, out_valid_B;
wire [8:0] next_A, next_B;
reg is_modA_finish, is_modB_finish;
wire is_mod_finish;
reg flag_sent;
//================================================================
//	FSM
//================================================================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	current_state <= S_IDLE ;
	else 			current_state <= next_state ;
end
always @(*) begin
	next_state = current_state ;
	case(current_state)
		S_IDLE: 	if (in_valid==1) 	next_state = S_CALCU ;
		S_CALCU: 	next_state = S_MODUL ;
		S_MODUL: 	if (is_mod_finish==1)	next_state = (cnt==10) ? S_OUTPT : S_CALCU ;
		S_OUTPT: 	next_state = S_IDLE ;
	endcase
end
//================================================================
//	MODULAR 507
//================================================================
Modular509 U_modA( .clk(clk), .rst_n(rst_n), .in_valid( (!flag_sent)&&(next_state==S_MODUL) ), .in(A), .out_valid(out_valid_A), .out(next_A) );
Modular509 U_modB( .clk(clk), .rst_n(rst_n), .in_valid( (!flag_sent)&&(next_state==S_MODUL) ), .in(B), .out_valid(out_valid_B), .out(next_B) );
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	is_modA_finish <= 0 ;
	else begin
		if (out_valid_A==1)				is_modA_finish <= 1 ;
		else if (next_state==S_CALCU)	is_modA_finish <= 0 ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	is_modB_finish <= 0 ;
	else begin
		if (out_valid_B==1)				is_modB_finish <= 1 ;
		else if (next_state==S_CALCU)	is_modB_finish <= 0 ;
	end
end
assign is_mod_finish = is_modA_finish && is_modB_finish ;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	flag_sent <= 0 ;
	else begin
		if (next_state==S_MODUL)		flag_sent <= 1 ;
		else if (next_state==S_CALCU)	flag_sent <= 0 ;
	end
end
//================================================================
//  DESIGN                         
//================================================================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	cnt <= 0 ;
	else begin
		if (next_state==S_CALCU)		cnt <= cnt + 1 ;
		else if (next_state==S_OUTPT)	cnt <= 0 ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	A <= 0 ;
	else begin
		if (in_valid==1) 						A <= 1 ;
		else if (next_state==S_CALCU && cnt!=3)	A <= A*B ;
		else if (out_valid_A==1)				A <= next_A ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	B <= 0 ;
	else begin
		if (in_valid==1) 				B <= in_a ;
		else if (next_state==S_CALCU)	B <= B*B ;
		else if (out_valid_B==1)		B <= next_B ;
	end
end
//================================================================
//  OUTPUT
//================================================================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	out_valid <= 0 ;
	else begin
		if (next_state==S_OUTPT)	out_valid <= 1 ;
		else 						out_valid <= 0 ;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	out_b <= 0 ;
	else begin
		if (next_state==S_OUTPT)	out_b <= A ;
		else 						out_b <= 0 ;
	end
end
endmodule



module Sort(clk, rst_n, in0, in1, in2, in3, in4, in5, out0, out1, out2, out3, out4, out5);
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
input clk, rst_n;
input [8:0] in0, in1, in2, in3, in4, in5;
output [8:0] out0, out1, out2, out3, out4, out5;
//================================================================
//    Wire & Registers 
//================================================================
wire [8:0] a[0:3], b[0:2], c[0:3], d[0:2], f[0:3], g[0:1];
reg [8:0] e[0:5];
//================================================================
//  DESIGN                         
//================================================================
//
assign a[0] = ( in0<in1 ) ? in0 : in1 ;
assign a[1] = ( in0<in1 ) ? in1 : in0 ;
assign a[2] = ( a[1]<in2 )? a[1] : in2 ;
assign a[3] = ( a[1]<in2 )? in2 : a[1] ;
assign b[0] = ( a[0]<a[2] ) ? a[0] : a[2] ;
assign b[1] = ( a[0]<a[2] ) ? a[2] : a[0] ;
assign b[2] = a[3] ;
//
assign c[0] = ( in3<in4 ) ? in3 : in4 ;
assign c[1] = ( in3<in4 ) ? in4 : in3 ;
assign c[2] = ( c[1]<in5 )? c[1] : in5 ;
assign c[3] = ( c[1]<in5 )? in5 : c[1] ;
assign d[0] = ( c[0]<c[2] ) ? c[0] : c[2] ;
assign d[1] = ( c[0]<c[2] ) ? c[2] : c[0] ;
assign d[2] = c[3] ;
//
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		e[0] <= 0 ;
		e[1] <= 0 ;
		e[2] <= 0 ;
		e[3] <= 0 ;
		e[4] <= 0 ;
		e[5] <= 0 ;
	end
	else begin
		e[0] <= ( b[0]<d[0] ) ? b[0] : d[0] ;
		e[1] <= ( b[0]<d[0] ) ? d[0] : b[0] ;
		e[2] <= ( b[1]<d[1] ) ? b[1] : d[1] ;
		e[3] <= ( b[1]<d[1] ) ? d[1] : b[1] ;
		e[4] <= ( b[2]<d[2] ) ? b[2] : d[2] ;
		e[5] <= ( b[2]<d[2] ) ? d[2] : b[2] ;
	end
end
/*
assign e[0] = ( b[0]<d[0] ) ? b[0] : d[0] ;
assign e[1] = ( b[0]<d[0] ) ? d[0] : b[0] ;
assign e[2] = ( b[1]<d[1] ) ? b[1] : d[1] ;
assign e[3] = ( b[1]<d[1] ) ? d[1] : b[1] ;
assign e[4] = ( b[2]<d[2] ) ? b[2] : d[2] ;
assign e[5] = ( b[2]<d[2] ) ? d[2] : b[2] ;
*/
//
assign out0 = e[0] ;
assign out5 = e[5] ;
//
assign f[0] = ( e[1]<e[2] ) ? e[1] : e[2] ;
assign f[1] = ( e[1]<e[2] ) ? e[2] : e[1] ;
assign f[2] = ( e[3]<e[4] ) ? e[3] : e[4] ;
assign f[3] = ( e[3]<e[4] ) ? e[4] : e[3] ;
//
assign out1 = f[0] ;
assign out4 = f[3] ;
//
assign g[0] = ( f[1]<f[2] ) ? f[1] : f[2] ;
assign g[1] = ( f[1]<f[2] ) ? f[2] : f[1] ;
//
assign out2 = g[0] ;
assign out3 = g[1] ;

endmodule
