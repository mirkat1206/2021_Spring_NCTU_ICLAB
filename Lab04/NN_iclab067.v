//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Lab04			: Artificial Neural Network (NN)
//   Author         : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : NN.v
//   Module Name : NN
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
// synopsys translate_off
`include "/usr/synthesis/dw/sim_ver/DW_fp_add.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_sub.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_addsub.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_mult.v"
// synopsys translate_on

module NN(
	// Input signals
	clk,
	rst_n,
	in_valid_d,
	in_valid_t,
	in_valid_w1,
	in_valid_w2,
	data_point,
	target,
	weight1,
	weight2,
	// Output signals
	out_valid,
	out
);
//================================================================
//  parameters
//================================================================
// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
input  clk, rst_n, in_valid_d, in_valid_t, in_valid_w1, in_valid_w2;
input [inst_sig_width+inst_exp_width:0] data_point, target;
input [inst_sig_width+inst_exp_width:0] weight1, weight2;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;
//================================================================
//  integer / genvar / parameters
//================================================================
// 
integer i;
genvar idx;
//  
parameter LEARNING_RATE = 32'b0_0111_0101_00000110001001001101111 ;
parameter FP_ZERO = 32'b0_0000_0000_00000000000000000000000 ;
parameter FP_ONE = 32'b0_0111_1111_00000000000000000000000 ;
//================================================================
//   Wires & Registers 
//================================================================
//  INPUT
reg flag;
reg [inst_sig_width+inst_exp_width:0] w1_r[0:11], w2_r[0:2];
reg [inst_sig_width+inst_exp_width:0] dp_r[0:3], tg_r;
//  PRE_OUTPUT
reg state_bits [0:9];
//	FORWARD
// step 1 (state_bits[3]) : mult
wire [inst_sig_width+inst_exp_width:0] h1_0_w[0:3], h1_1_w[0:3], h1_2_w[0:3];
reg  [inst_sig_width+inst_exp_width:0] h1_0_r[0:3], h1_1_r[0:3], h1_2_r[0:3];
// step 2 (state_bits[4]) : add + compare
wire [inst_sig_width+inst_exp_width:0] sum_h1_w[0:2];
reg  [inst_sig_width+inst_exp_width:0] sum_h1_r[0:2];
wire [inst_sig_width+inst_exp_width:0] y1_w[0:2];
reg  [inst_sig_width+inst_exp_width:0] y1_r[0:2];
// step 3 (state_bits[5]) : mult
wire [inst_sig_width+inst_exp_width:0] h2_w[0:2];
reg  [inst_sig_width+inst_exp_width:0] h2_r[0:2];
// step 4 (state_bits[6]) : add
wire [inst_sig_width+inst_exp_width:0] y2_w;
reg  [inst_sig_width+inst_exp_width:0] y2_r;
//	BACKWORD
// step 5 (state_bits[7]) : sub
wire [inst_sig_width+inst_exp_width:0] delta2_w;
reg  [inst_sig_width+inst_exp_width:0] delta2_r;
// step 6 (state_bits[8]) : mult
wire [inst_sig_width+inst_exp_width:0] w2_delta2_w[0:2];
reg  [inst_sig_width+inst_exp_width:0] w2_delta2_r[0:2];
// step 7 (state_bits[9]) : compare(delta1) + mult(lrn_dp_w)
wire [inst_sig_width+inst_exp_width:0] delta1_w[0:2];
reg  [inst_sig_width+inst_exp_width:0] delta1_r[0:2];
wire [inst_sig_width+inst_exp_width:0] lrn_dp_w[0:3];
reg  [inst_sig_width+inst_exp_width:0] lrn_dp_r[0:3];
wire [inst_sig_width+inst_exp_width:0] lrn_y1_w[0:2];
reg  [inst_sig_width+inst_exp_width:0] lrn_y1_r[0:2];
//	UPDATE
// step 8 (state_bits[0]) : mult
wire [inst_sig_width+inst_exp_width:0] fix_w1_0_w[0:3], fix_w1_1_w[0:3], fix_w1_2_w[0:3];
reg  [inst_sig_width+inst_exp_width:0] fix_w1_0_r[0:3], fix_w1_1_r[0:3], fix_w1_2_r[0:3];
wire [inst_sig_width+inst_exp_width:0] fix_w2_w[0:2];
reg  [inst_sig_width+inst_exp_width:0] fix_w2_r[0:2];
// step 9 (state_bits[1]) : sub
wire [inst_sig_width+inst_exp_width:0] next_w1_w[0:11];
wire [inst_sig_width+inst_exp_width:0] next_w2_w[0:2];
// reg [inst_sig_width+inst_exp_width:0] w1_r[0:11], w2_r[0:2];
//================================================================
//  OUTPUT : out_valid & out
//================================================================
// step 4 (state_bits[6]) : add
// output reg	out_valid;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)		out_valid <= 0 ;
	else begin
		out_valid <= state_bits[6] ;
	end
end
// output reg [inst_sig_width+inst_exp_width:0] out;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	out <= 0 ;
	else begin
		if (state_bits[6]==1'b1)	out <= y2_w ;
		else  		out <= 0 ;
	end
end
//================================================================
//  PRE_OUTPUT
//================================================================
// use shift-register
// reg state_bits [0:9];
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for( i=0 ; i<8 ; i=i+1 )
			state_bits[i] <= 0 ;
	end
	else begin
		state_bits[0] <= in_valid_t ;
		for( i=1 ; i<10 ; i=i+1 ) 
			state_bits[i] <= state_bits[i-1] ;
	end
end
//================================================================
//	FORWARD
//================================================================
// step 1 (state_bits[3]) : mult
// wire [inst_sig_width+inst_exp_width:0] h1_0_w[0:3], h1_1_w[0:3], h1_2_w[0:3];
generate
for( idx=0 ; idx<4 ; idx=idx+1 ) begin
	fp_MULT MULT_h1_0( .inst_a(w1_r[ idx+0 ]), .inst_b(dp_r[idx]), .z_inst(h1_0_w[idx]) );
	fp_MULT MULT_h1_1( .inst_a(w1_r[ idx+4 ]), .inst_b(dp_r[idx]), .z_inst(h1_1_w[idx]) );
	fp_MULT MULT_h1_2( .inst_a(w1_r[ idx+8 ]), .inst_b(dp_r[idx]), .z_inst(h1_2_w[idx]) );
end
endgenerate
// reg [inst_sig_width+inst_exp_width:0] h1_0_r[0:3], h1_1_r[0:3], h1_2_r[0:3];
generate
for( idx=0 ; idx<4 ; idx=idx+1 ) begin
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)		h1_0_r[idx] <= 0 ;
		else begin
			if (state_bits[3]==1'b1)
				h1_0_r[idx] <= h1_0_w[idx] ;
		end
	end
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)		h1_1_r[idx] <= 0 ;
		else begin
			if (state_bits[3]==1'b1)
				h1_1_r[idx] <= h1_1_w[idx] ;
		end
	end
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)		h1_2_r[idx] <= 0 ;
		else begin
			if (state_bits[3]==1'b1)
				h1_2_r[idx] <= h1_2_w[idx] ;
		end
	end
end
endgenerate
// step 2 (state_bits[4]) : add + compare
// wire [inst_sig_width+inst_exp_width:0] sum_h1_w[0:2];
generate
	fp_SUM4 SUM4_h1_0( .inst_a(h1_0_r[0]), .inst_b(h1_0_r[1]), .inst_c(h1_0_r[2]), .inst_d(h1_0_r[3]), .z_inst(sum_h1_w[0]) );
	fp_SUM4 SUM4_h1_1( .inst_a(h1_1_r[0]), .inst_b(h1_1_r[1]), .inst_c(h1_1_r[2]), .inst_d(h1_1_r[3]), .z_inst(sum_h1_w[1]) );
	fp_SUM4 SUM4_h1_2( .inst_a(h1_2_r[0]), .inst_b(h1_2_r[1]), .inst_c(h1_2_r[2]), .inst_d(h1_2_r[3]), .z_inst(sum_h1_w[2]) );
endgenerate
// reg [inst_sig_width+inst_exp_width:0] sum_h1_r[0:2];
generate
for( idx=0 ; idx<3 ; idx=idx+1 )
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)		sum_h1_r[idx] <= 0 ;
		else begin
			if (state_bits[4]==1'b1)
				sum_h1_r[idx] <= sum_h1_w[idx] ;
		end
	end	
endgenerate
// wire [inst_sig_width+inst_exp_width:0] y1_w[0:2];
generate
for( idx=0 ; idx<3 ; idx=idx+1 )
	assign y1_w[idx] = (sum_h1_w[idx][31]==1'b1) ? FP_ZERO : sum_h1_w[idx] ;
endgenerate
// reg [inst_sig_width+inst_exp_width:0] y1_r[0:2];
generate
for( idx=0 ; idx<3 ; idx=idx+1 )
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)		y1_r[idx] <= 0 ;
		else begin
			if (state_bits[4]==1'b1)
				y1_r[idx] <= y1_w[idx] ;
		end
	end
endgenerate
// step 3 (state_bits[5]) : mult
// wire [inst_sig_width+inst_exp_width:0] h2_w[0:2];
generate
for( idx=0 ; idx<3 ; idx=idx+1 )
	fp_MULT MULT_h2( .inst_a(w2_r[idx]), .inst_b(y1_r[idx]), .z_inst(h2_w[idx]) );
endgenerate
// reg [inst_sig_width+inst_exp_width:0] h2_r[0:2];
generate
for( idx=0 ; idx<3 ; idx=idx+1 )
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) 	h2_r[idx] <= 0 ;
		else begin
			if (state_bits[5]==1'b1)
				h2_r[idx] <= h2_w[idx] ;
		end
	end	
endgenerate
// step 4 (state_bits[6]) : add
// wire [inst_sig_width+inst_exp_width:0] y2_w;
fp_SUM3 SUM3_h2( .inst_a(h2_r[0]), .inst_b(h2_r[1] ), .inst_c(h2_r[2]), .z_inst(y2_w) );
// reg [inst_sig_width+inst_exp_width:0] y2_r;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	y2_r <= 0 ;
	else begin
		if (state_bits[6]==1'b1)
			y2_r <= y2_w ;
	end
end
//================================================================
//	BACKWORD
//================================================================
// step 5 (state_bits[7]) : sub
// wire [inst_sig_width+inst_exp_width:0] delta2_w;
fp_SUB SUB_delta2( .inst_a(y2_r), .inst_b(tg_r), .z_inst(delta2_w) );
// reg [inst_sig_width+inst_exp_width:0] delta2_r;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)		delta2_r <= 0 ;
	else begin
		if (state_bits[7]==1'b1)
			delta2_r <= delta2_w ;
	end
end
// step 6 (state_bits[8]) : mult
// wire [inst_sig_width+inst_exp_width:0] w2_delta2_w[0:2];
generate
for( idx=0 ; idx<3 ; idx=idx+1 )
	fp_MULT MULT_w2_delta2( .inst_a(w2_r[idx]), .inst_b(delta2_r), .z_inst(w2_delta2_w[idx]) );
endgenerate
// reg [inst_sig_width+inst_exp_width:0] w2_delta2_r[0:2];
generate
for( idx=0 ; idx<3 ; idx=idx+1 )
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) 	w2_delta2_r[idx] <= 0 ;
		else begin
			if (state_bits[8]==1'b1)
				w2_delta2_r[idx] <= w2_delta2_w[idx] ;
		end
	end
endgenerate
// step 7 (state_bits[9]) : compare(delta1) + mult(lrn_dp_w)
// wire [inst_sig_width+inst_exp_width:0] delta1_w[0:2];
generate
for( idx=0 ; idx<3 ; idx=idx+1 )
	assign delta1_w[idx] = (sum_h1_w[idx][31]==1'b1) ? FP_ZERO : w2_delta2_r[idx] ;	
endgenerate
// reg [inst_sig_width+inst_exp_width:0] delta1_r[0:2];
generate
for( idx=0 ; idx<3 ; idx=idx+1 )
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) 	delta1_r[idx] <= 0 ;
		else begin
			if (state_bits[9]==1'b1)
				delta1_r[idx] <= delta1_w[idx] ;
		end
	end	
endgenerate
// wire [inst_sig_width+inst_exp_width:0] lrn_dp_w[0:3];
generate
for( idx=0 ; idx<4 ; idx=idx+1 )
	fp_MULT MULT_lrn_dp( .inst_a(LEARNING_RATE), .inst_b(dp_r[idx]), .z_inst(lrn_dp_w[idx]) );
endgenerate
// reg [inst_sig_width+inst_exp_width:0] lrn_dp_r[0:3];
generate
for( idx=0 ; idx<4 ; idx=idx+1 )
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) 	lrn_dp_r[idx] <= 0 ;
		else begin
			if (state_bits[9]==1'b1)
				lrn_dp_r[idx] <= lrn_dp_w[idx] ;
		end
	end	
endgenerate
// wire [inst_sig_width+inst_exp_width:0] lrn_y1_w[0:2];
generate
for( idx=0 ; idx<3 ; idx=idx+1 )
	fp_MULT MULT_lrn_y1( .inst_a(LEARNING_RATE), .inst_b(y1_r[idx]), .z_inst(lrn_y1_w[idx]) );
endgenerate
// reg [inst_sig_width+inst_exp_width:0] lrn_y1_r[0:2];
generate
for( idx=0 ; idx<3 ; idx=idx+1 )
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) 	lrn_y1_r[idx] <= 0 ;
		else begin
			if (state_bits[9]==1'b1)
				lrn_y1_r[idx] <= lrn_y1_w[idx] ;
		end
	end	
endgenerate
//================================================================
//	UPDATE
//================================================================
// step 8 (state_bits[0]) : mult
// wire [inst_sig_width+inst_exp_width:0] fix_w1_0_w[0:3], fix_w1_1_w[0:3], fix_w1_2_w[0:3];
generate
for( idx=0 ; idx<4 ; idx=idx+1 ) begin
	fp_MULT MULT_fix_w1_0( .inst_a(lrn_dp_r[idx]), .inst_b(delta1_r[0]), .z_inst(fix_w1_0_w[idx]) );
	fp_MULT MULT_fix_w1_1( .inst_a(lrn_dp_r[idx]), .inst_b(delta1_r[1]), .z_inst(fix_w1_1_w[idx]) );
	fp_MULT MULT_fix_w1_2( .inst_a(lrn_dp_r[idx]), .inst_b(delta1_r[2]), .z_inst(fix_w1_2_w[idx]) );
end	
endgenerate
// reg [inst_sig_width+inst_exp_width:0] fix_w1_0_r[0:3], fix_w1_1_r[0:3], fix_w1_2_r[0:3];
generate
for( idx=0 ; idx<4 ; idx=idx+1 ) begin
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) 	fix_w1_0_r[idx] <= 0 ;
		else begin
			if (state_bits[0]==1'b1)
				fix_w1_0_r[idx] <= fix_w1_0_w[idx] ;
		end
	end
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) 	fix_w1_1_r[idx] <= 0 ;
		else begin
			if (state_bits[0]==1'b1)
				fix_w1_1_r[idx] <= fix_w1_1_w[idx] ;
		end
	end
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) 	fix_w1_2_r[idx] <= 0 ;
		else begin
			if (state_bits[0]==1'b1)
				fix_w1_2_r[idx] <= fix_w1_2_w[idx] ;
		end
	end
end	
endgenerate
// wire [inst_sig_width+inst_exp_width:0] fix_w2_w[0:2];
generate
for( idx=0 ; idx<3 ; idx=idx+1 )
	fp_MULT MULT_fix_w2( .inst_a(lrn_y1_r[idx]), .inst_b(delta2_r), .z_inst(fix_w2_w[idx]) ); 
endgenerate
// reg [inst_sig_width+inst_exp_width:0] fix_w2_r[0:2];
generate
for( idx=0 ; idx<3 ; idx=idx+1 )
	always @(posedge clk or negedge rst_n ) begin
		if (!rst_n)		fix_w2_r[idx] <= 0 ;
		else begin
			if (state_bits[0]==1'b1)
				fix_w2_r[idx] <= fix_w2_w[idx] ;
		end
	end	
endgenerate
// step 9 (state_bits[1]) : sub
// wire [inst_sig_width+inst_exp_width:0] next_w1_w[0:11];
generate
for( idx=0 ; idx<4 ; idx=idx+1 ) begin
	fp_SUB SUB_next_w1_0( .inst_a(w1_r[ idx+0 ]), .inst_b(fix_w1_0_r[idx]), .z_inst(next_w1_w[ idx+0 ]) );	
	fp_SUB SUB_next_w1_1( .inst_a(w1_r[ idx+4 ]), .inst_b(fix_w1_1_r[idx]), .z_inst(next_w1_w[ idx+4 ]) );	
	fp_SUB SUB_next_w1_2( .inst_a(w1_r[ idx+8 ]), .inst_b(fix_w1_2_r[idx]), .z_inst(next_w1_w[ idx+8 ]) );	
end
endgenerate
// wire [inst_sig_width+inst_exp_width:0] next_w2_w[0:2];
generate
for( idx=0 ; idx<3 ; idx=idx+1 )
	fp_SUB SUB_next_w2( .inst_a(w2_r[idx]), .inst_b(fix_w2_r[idx]), .z_inst(next_w2_w[idx]) );	
endgenerate
// reg [inst_sig_width+inst_exp_width:0] w1_r[0:11], w2_r[0:2];
//================================================================
//  INPUT
//================================================================
// reg flag;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	flag <= 0 ;
	else begin
		if (in_valid_w1==1'b1)		flag <= 1 ;
		else if (out_valid==1'b1)	flag <= 0 ;
	end
end
// reg [inst_sig_width+inst_exp_width:0] w1_r[0:11], w2_r[0:2];
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for( i=0 ; i<12 ; i=i+1 )
			w1_r[i] <= 0 ;
	end
	else begin
		if (in_valid_w1==1'b1) begin
			w1_r[11] <= weight1 ;
			for( i=0 ; i<11 ; i=i+1 )
				w1_r[i] <= w1_r[i+1] ;
		end
		else if (flag==1'b0 && state_bits[1]==1'b1) begin
			for( i=0 ; i<12 ; i=i+1 )
				w1_r[i] <= next_w1_w[i] ;
		end
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for( i=0 ; i<3 ; i=i+1 )
			w2_r[i] <= 0 ;	
	end
	else begin
		if (in_valid_w2==1'b1) begin
			w2_r[2] <= weight2 ;
			for( i=0 ; i<2 ; i=i+1 )
				w2_r[i] <= w2_r[i+1] ;
		end
		else if (flag==1'b0 && state_bits[1]==1'b1) begin
			for( i=0 ; i<3 ; i=i+1 )
				w2_r[i] <= next_w2_w[i] ;
		end
	end
end
// reg [inst_sig_width+inst_exp_width:0] dp_r[0:3], tg_r;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)	begin
		for( i=0 ; i<4 ; i=i+1 )
			dp_r[i] <= 0 ;
	end
	else begin
		if (in_valid_d==1'b1 ) begin
			dp_r[3] <= data_point ;
			for( i=0 ; i<3 ; i=i+1 )
				dp_r[i] <= dp_r[i+1] ;
		end
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	tg_r <= 0 ;
	else begin
		if (in_valid_t==1'b1)
			tg_r <= target ;
	end
end

endmodule

//================================================================
//  SUBMODULE : DesignWare
//================================================================
module fp_MULT(inst_a, inst_b, z_inst);
// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

input  [inst_sig_width+inst_exp_width:0] inst_a, inst_b;
output [inst_sig_width+inst_exp_width:0] z_inst;

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	U1( .a(inst_a),
		.b(inst_b),
		.rnd(3'b000),
		.z(z_inst) );

// synopsys dc_script_begin
// set_implementation rtl U1
// synopsys dc_script_end

endmodule

module fp_SUM4(inst_a, inst_b, inst_c, inst_d, z_inst);
// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

input  [inst_sig_width+inst_exp_width:0] inst_a, inst_b, inst_c, inst_d;
output [inst_sig_width+inst_exp_width:0] z_inst;

wire [inst_sig_width+inst_exp_width:0] temp_ab, temp_cd;

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	U1(	.a(inst_a),
		.b(inst_b),
		.rnd(3'b000),
		.z(temp_ab) );

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	U2(	.a(inst_c),
		.b(inst_d),
		.rnd(3'b000),
		.z(temp_cd) );

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	U3(	.a(temp_ab),
		.b(temp_cd),
		.rnd(3'b000),
		.z(z_inst) );

// synopsys dc_script_begin
// set_implementation rtl U1
// set_implementation rtl U2
// set_implementation rtl U3
// synopsys dc_script_end

endmodule

module fp_SUM3(inst_a, inst_b, inst_c, z_inst);
// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

input [inst_sig_width+inst_exp_width:0] inst_a, inst_b, inst_c;
output [inst_sig_width+inst_exp_width:0] z_inst;

wire [inst_sig_width+inst_exp_width:0] temp_ab;

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	U1(	.a(inst_a),
		.b(inst_b),
		.rnd(3'b000),
		.z(temp_ab) );

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	U2(	.a(temp_ab),
		.b(inst_c),
		.rnd(3'b000),
		.z(z_inst) );

// synopsys dc_script_begin
// set_implementation rtl U1
// set_implementation rtl U2
// synopsys dc_script_end

endmodule

module fp_SUB(inst_a, inst_b, z_inst);
// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

input [inst_sig_width+inst_exp_width:0] inst_a, inst_b;
output [inst_sig_width+inst_exp_width:0] z_inst;

DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	U1(	.a(inst_a),
		.b(inst_b),
		.rnd(3'b000),
		.z(z_inst) );

// synopsys dc_script_begin
// set_implementation rtl U1
// synopsys dc_script_end

endmodule

module fp_ADD(inst_a, inst_b, z_inst);
// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

input [inst_sig_width+inst_exp_width:0] inst_a, inst_b;
output [inst_sig_width+inst_exp_width:0] z_inst;

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	U2(	.a(inst_a),
		.b(inst_b),
		.rnd(3'b000),
		.z(z_inst) );

// synopsys dc_script_begin
// set_implementation rtl U1
// synopsys dc_script_end

endmodule