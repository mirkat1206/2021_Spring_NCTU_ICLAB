//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Lab05			: Matrix Computation (MC)
//   Author         : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : MC.v
//   Module Name : MC
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module MC(
	// Input signals
	clk,
	rst_n,
	in_valid,
	in_data,
	size,
	action,
	// Output signals
	out_valid,
	out_data
);
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
input clk;
input rst_n;
input in_valid;
input [30:0] in_data;
input [1:0] size;
input [2:0] action;
output reg out_valid;
output reg [30:0] out_data;
//================================================================
//  integer / genvar / parameters
//================================================================
//
integer i;
genvar idx;
//  FSM
parameter STATE_IDLE  = 3'b111 ;
parameter STATE_SETUP = 3'b000 ;	// based on SPEC
parameter STATE_ADD   = 3'b001 ;	// based on SPEC
parameter STATE_MUL   = 3'b010 ;	// based on SPEC
parameter STATE_TRANS = 3'b011 ;	// based on SPEC
parameter STATE_MIROR = 3'b100 ;	// based on SPEC
parameter STATE_ROTAT = 3'b101 ;	// based on SPEC
parameter STATE_OUTPT = 3'b110 ;
//  FSM : in STATE_ADD
parameter ADD_IDLE  = 2'b00 ;
parameter ADD_INPUT = 2'b01 ;
parameter ADD_ADD   = 2'b10 ;
parameter ADD_STORE = 2'b11 ;
//  FSM : in STATE_MUL
parameter MUL_IDLE  = 3'b000 ;
parameter MUL_INPUT = 3'b001 ;
parameter MUL_MUL   = 3'b010 ;
parameter MUL_MOD	= 3'b011 ;
parameter MUL_STORE = 3'b100 ;
parameter MUL_FUCKU = 3'b101 ;
// FSM : in STATE_TRANS / STATE_MIROR / STATE_ROTAT
parameter TMR_IDLE = 2'b00 ;
parameter TMR_TO_T = 2'b01 ;
parameter TMR_REST = 2'b10 ;
parameter TMR_TO_C = 2'b11 ;
//================================================================
//   Wires & Registers 
//================================================================
//  OUTPUT
reg is_ready;
// 	ADR_CNT
reg [8:0] adr_cnt;
// 	ALU
reg [69:0] alu, next_alu;
wire [38:0] is_overflow;
wire [30:0] non_overflow;
//  FLAG
reg flag_rst_add_adr;
reg flag_rst_mul_adr;
reg flag_fisrt_add;
reg flag_fisrt_mul;
reg flag_last_store;
//  MEMORY CONTROL : MATRIX C
wire [30:0] C_MEM_out;
wire C_MEM_cen;			// always enable
reg C_MEM_wen;
reg [7:0] C_MEM_a;
reg [30:0] C_MEM_in;
wire C_MEM_oen;			// always enable
//  MEMORY CONTROL : MATRIX M
wire [30:0] M_MEM_out;
wire M_MEM_cen;			// always enable
reg M_MEM_wen;
reg [7:0] M_MEM_a;
wire [30:0] M_MEM_in;	// assign M_MEM_in = in_data ;
wire M_MEM_oen;			// always enable
//  MEMORY CONTROL : MATRIX T
wire [30:0] T_MEM_out;
wire T_MEM_cen;			// always enable
reg T_MEM_wen;
reg [7:0] T_MEM_a;
reg [30:0] T_MEM_in;
wire T_MEM_oen;			// always enable
// FSM : in STATE_TRANS / STATE_MIROR / STATE_ROTAT
reg [1:0] current_tmr_state;
reg [1:0] next_tmr_state;
//  FSM : in STATE_ADD
reg [1:0] current_add_state;
reg [1:0] next_add_state;
//  FSM : in STATE_MUL
reg [2:0] current_mul_state;
reg [2:0] next_mul_state;
//  FSM
reg [2:0] current_state;
reg [2:0] next_state;
//  i, j
wire [4:0] adr_cnt_i, adr_cnt_j;
wire [7:0] next_C_adr, next_M_adr;
reg [4:0] tmr_i, tmr_j;
wire [7:0] next_T_adr;
//  STATE_MUL
reg [4:0] sub_cnt;
//  STATE_SETUP
reg [2:0] Action;
reg [4:0] Size;
reg [8:0] SizeSize;
//================================================================
//  OUTPUT
//================================================================
// output reg out_valid;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	out_valid <= 0 ;
	else begin
		if (next_state==STATE_OUTPT) begin
			if (Action<3'd3) begin
				if (is_ready && adr_cnt>0 && adr_cnt<=SizeSize)	out_valid <= 1 ;
				else 	out_valid <= 0 ;
			end
			else 	out_valid <= 1 ;
		end
		else 		out_valid <= 0 ;
	end
end
// output reg [30:0] out_data;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	out_data <= 0 ;
	else begin
		if (next_state==STATE_OUTPT) begin
			if (Action<3'd3) begin
				if (is_ready && adr_cnt>0 && adr_cnt<=SizeSize)	out_data <= C_MEM_out ;
				else 	out_data <= 0 ;
			end
			else 	out_data <= 0 ;
		end
		else 		out_data <= 0 ;
	end
end
// reg is_ready;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	is_ready <= 1'b0 ;
	else begin
		if (next_state==STATE_OUTPT) 		is_ready <= 1'b1 ;
		else if (next_state==STATE_IDLE)	is_ready <= 1'b0 ;
	end
end
//================================================================
//  ADR_CNT
//================================================================
// reg [8:0] adr_cnt;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)	adr_cnt <= 0 ;
	else begin
		case(next_state)
			STATE_IDLE: 	adr_cnt <= 0 ;
			STATE_SETUP: 	adr_cnt <= adr_cnt + 1 ;
			STATE_ADD: begin
				case(next_add_state)
					// ADD_IDLE:
					ADD_INPUT: 	adr_cnt <= adr_cnt + 1 ;
					ADD_ADD: 	if (flag_rst_add_adr==0)	adr_cnt <= 0 ;
					ADD_STORE:	adr_cnt <= adr_cnt + 1 ;
					default:	adr_cnt <= adr_cnt ;
				endcase
			end		
			STATE_MUL: begin
				case(next_mul_state)
					// MUL_IDLE:
					MUL_INPUT:	adr_cnt <= adr_cnt + 1 ;
					MUL_MUL: 	if (flag_rst_mul_adr==0)	adr_cnt <= 0 ;
					// MUL_MOD:	
					MUL_STORE:	adr_cnt <= adr_cnt + 1 ;
					MUL_FUCKU: begin
						if (adr_cnt==SizeSize)	adr_cnt <= 0 ;
						else 	adr_cnt <= adr_cnt + 1 ;
					end
					default:	adr_cnt <= adr_cnt ;
				endcase
			end 
			STATE_TRANS: begin
				if (adr_cnt>SizeSize) 	adr_cnt <= 0 ;
				else 	adr_cnt <= adr_cnt + 1 ;
			end
			STATE_MIROR: begin
				if (adr_cnt>SizeSize) 	adr_cnt <= 0 ;
				else 	adr_cnt <= adr_cnt + 1 ;
			end
			STATE_ROTAT: begin
				if (adr_cnt>SizeSize) 	adr_cnt <= 0 ;
				else 	adr_cnt <= adr_cnt + 1 ;
			end
			STATE_OUTPT: begin
				if (is_ready==0)	adr_cnt <= 0 ;
				else 				adr_cnt <= adr_cnt + 1 ;
			end	
		endcase
	end
end
//================================================================
//  FLAG
//================================================================
// reg flag_rst_add_adr;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	flag_rst_add_adr <= 0 ;
	else begin
		if (next_state==STATE_ADD) begin
			if (next_add_state==ADD_ADD)	flag_rst_add_adr <= 1 ;
		end
		else 		flag_rst_add_adr <= 0 ;
	end
end
// reg flag_rst_mul_adr;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	flag_rst_mul_adr <= 0 ;
	else begin
		if (next_state==STATE_MUL) begin
			if (next_mul_state==MUL_MUL)	flag_rst_mul_adr <= 1 ;
		end
		else 		flag_rst_mul_adr <= 0 ;
	end
end
// reg flag_fisrt_add;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	flag_fisrt_add <= 0 ;
	else begin
		if (current_add_state==ADD_ADD)			flag_fisrt_add <= 1 ;
		else if (current_add_state==ADD_STORE)	flag_fisrt_add <= 0 ;
	end
end
// reg flag_fisrt_mul;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	flag_fisrt_mul <= 0 ;
	else begin
		if (current_mul_state==MUL_MUL)			flag_fisrt_mul <= 1 ;
		else if (current_mul_state==MUL_STORE)	flag_fisrt_mul <= 0 ;
	end
end
// reg flag_last_store;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)		flag_last_store <= 0 ;
	else begin
		if (current_mul_state==MUL_FUCKU && adr_cnt==SizeSize)	flag_last_store <= 1 ;
		else 	flag_last_store <= 0 ;
	end
end
//================================================================
//  ALU
//================================================================
// reg [69:0] alu, next_alu;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	alu <= 0 ;
	else begin
		if (current_add_state==ADD_ADD)			alu <= next_alu ;
		else if (current_mul_state==MUL_MUL && flag_fisrt_mul==1) 	alu <= next_alu ;
		else if (current_mul_state==MUL_MOD) 	alu <= next_alu ;
		else 	alu <= 0 ;
	end
end
always @(*) begin
	case(next_state)
		STATE_ADD: begin
			if (is_overflow==0)	next_alu = M_MEM_out + C_MEM_out ;
			else 				next_alu = is_overflow + non_overflow;
		end
		STATE_MUL: begin
			if (current_mul_state==MUL_MUL)			next_alu = alu + M_MEM_out*C_MEM_out ;
			else if (current_mul_state==MUL_MOD)	next_alu = is_overflow + non_overflow ;
			else 	next_alu = 0 ;
		end
		default: 	next_alu = 0 ;
	endcase
end
// wire [38:0] is_overflow;
assign is_overflow[38:0] = alu[69:31] ;
// wire [30:0] non_overflow;
assign non_overflow[30:0] = alu[30:0] ;
//================================================================
//  MEMORY CONTROL : MATRIX C
//================================================================
// wire [31:0] C_MEM_out;
// MYMEM M_C( .Q(C_MEM_out), .CLK(clk), .CEN(C_MEM_cen), .WEN(C_MEM_wen), .A(C_MEM_a), .D(C_MEM_in), .OEN(C_MEM_oen) );
MEM256_31 M_C( .Q(C_MEM_out), .CLK(clk), .CEN(C_MEM_cen), .WEN(C_MEM_wen), .A(C_MEM_a), .D(C_MEM_in), .OEN(C_MEM_oen) );
// wire C_MEM_cen;			// always enable
assign C_MEM_cen = 0 ;
// reg C_MEM_wen;
always @(*) begin
	case(next_state)
		// STATE_IDLE: 	
		STATE_SETUP: 	C_MEM_wen = 0 ;
		STATE_ADD: begin
			case(next_add_state)
				// ADD_IDLE:
				// ADD_INPUT:	
				// ADD_ADD:	C_MEM_wen = 1 ;
				ADD_STORE:	C_MEM_wen = 0 ;
				default:	C_MEM_wen = 1 ;
			endcase
		end
		STATE_MUL: begin
			case(next_mul_state)
				// MUL_IDLE:
				// MUL_INPUT:	
				// MUL_MUL:	C_MEM_wen = 1 ;
				// MUL_MOD:	
				// MUL_STORE:
				MUL_FUCKU:	C_MEM_wen = 0 ;
				default:	C_MEM_wen = 1 ;
			endcase
		end 
		STATE_TRANS: begin
			case(next_tmr_state)
				// TMR_IDLE:
				// TMR_TO_T:	C_MEM_wen = 1 ;
				// TMR_REST:
				TMR_TO_C:	C_MEM_wen = 0 ;
				default:	C_MEM_wen = 1 ;
			endcase
		end 
		STATE_MIROR: begin
			case(next_tmr_state)
				// TMR_IDLE:
				// TMR_TO_T:	C_MEM_wen = 1 ;
				// TMR_REST:
				TMR_TO_C:	C_MEM_wen = 0 ;
				default:	C_MEM_wen = 1 ;
			endcase
		end 
		STATE_ROTAT: begin
			case(next_tmr_state)
				// TMR_IDLE:
				// TMR_TO_T:	C_MEM_wen = 1 ;
				// TMR_REST:
				TMR_TO_C:	C_MEM_wen = 0 ;
				default:	C_MEM_wen = 1 ;
			endcase
		end 
		// STATE_OUTPT: 	C_MEM_wen = 1 ;
		default: 		C_MEM_wen = 1 ;
	endcase
end
// reg [4:0] C_MEM_a;
always @(*) begin
	case(next_state)
		// STATE_IDLE: 
		STATE_SETUP: 	C_MEM_a = adr_cnt ;
		STATE_ADD: begin
			case(next_add_state)
				// ADD_IDLE:
				// ADD_INPUT:	
				ADD_ADD: begin
					if (adr_cnt==SizeSize)	C_MEM_a = 0 ;
					else 					C_MEM_a = adr_cnt ;
				end
				ADD_STORE:	C_MEM_a = adr_cnt ;
				default:	C_MEM_a = 0 ;
			endcase
		end 
		STATE_MUL: begin
			case(next_mul_state)
				// MUL_IDLE:
				// MUL_INPUT:	
				MUL_MUL:	C_MEM_a = next_C_adr ;
				// MUL_MOD:	
				// MUL_STORE:
				MUL_FUCKU:	C_MEM_a = adr_cnt - 1 ;
				default:	C_MEM_a = 0 ;
			endcase
		end 
		STATE_TRANS: begin
			case(next_tmr_state)
				// TMR_IDLE:
				TMR_TO_T:	C_MEM_a = adr_cnt ;
				// TMR_REST:
				TMR_TO_C:	C_MEM_a = adr_cnt - 1 ;
				default:	C_MEM_a = 0 ;
			endcase
		end 
		STATE_MIROR: begin
			case(next_tmr_state)
				// TMR_IDLE:
				TMR_TO_T:	C_MEM_a = adr_cnt ;
				// TMR_REST:
				TMR_TO_C:	C_MEM_a = adr_cnt - 1 ;
				default:	C_MEM_a = 0 ;
			endcase
		end 
		STATE_ROTAT: begin
			case(next_tmr_state)
				// TMR_IDLE:
				TMR_TO_T:	C_MEM_a = adr_cnt ;
				// TMR_REST:
				TMR_TO_C:	C_MEM_a = adr_cnt - 1 ;
				default:	C_MEM_a = 0 ;
			endcase
		end  
		STATE_OUTPT: 	C_MEM_a = adr_cnt ;
		default: 		C_MEM_a = 0 ;
	endcase
end
// reg [31:0] C_MEM_in;
always @(*) begin
	case(next_state)
		// STATE_IDLE: 
		STATE_SETUP: 	C_MEM_in = in_data ;
		STATE_ADD: begin
			case(next_add_state)
				// ADD_IDLE:
				// ADD_INPUT:	
				// ADD_ADD:
				ADD_STORE:	C_MEM_in = alu ;
				default:	C_MEM_in = 0 ;
			endcase
		end 
		STATE_MUL: begin
			case(next_mul_state)
				// MUL_IDLE:
				// MUL_INPUT:	
				// MUL_MUL:
				// MUL_MOD:	
				// MUL_STORE:	
				MUL_FUCKU:	C_MEM_in = T_MEM_out ;
				default:	C_MEM_in = 0 ;
			endcase
		end 
		STATE_TRANS: begin
			case(next_tmr_state)
				// TMR_IDLE:
				// TMR_TO_T:
				// TMR_REST:
				TMR_TO_C:	C_MEM_in = T_MEM_out ;
				default:	C_MEM_in = 0 ;
			endcase
		end 
		STATE_MIROR: begin
			case(next_tmr_state)
				// TMR_IDLE:
				// TMR_TO_T:
				// TMR_REST:
				TMR_TO_C:	C_MEM_in = T_MEM_out ;
				default:	C_MEM_in = 0 ;
			endcase
		end 
		STATE_ROTAT: begin
			case(next_tmr_state)
				// TMR_IDLE:
				// TMR_TO_T:
				// TMR_REST:
				TMR_TO_C:	C_MEM_in = T_MEM_out ;
				default:	C_MEM_in = 0 ;
			endcase
		end 
		// STATE_OUTPT: 
		default: 		C_MEM_in = 0 ;
	endcase
end
// reg C_MEM_oen;			// always enable
assign C_MEM_oen = 0 ;
//================================================================
//  MEMORY CONTROL : MATRIX M
//================================================================
// wire [31:0] M_MEM_out;
// MYMEM M_M( .Q(M_MEM_out), .CLK(clk), .CEN(M_MEM_cen), .WEN(M_MEM_wen), .A(M_MEM_a), .D(M_MEM_in), .OEN(M_MEM_oen) );
MEM256_31 M_M( .Q(M_MEM_out), .CLK(clk), .CEN(M_MEM_cen), .WEN(M_MEM_wen), .A(M_MEM_a), .D(M_MEM_in), .OEN(M_MEM_oen) );
// wire M_MEM_cen;			// always enable
assign M_MEM_cen = 0 ;
// reg M_MEM_wen;
always @(*) begin
	case(next_state)
		// STATE_IDLE: 	
		// STATE_SETUP: 	
		STATE_ADD: begin
			case(next_add_state)
				// ADD_IDLE:
				ADD_INPUT:	M_MEM_wen = 0 ;
				// ADD_ADD:	M_MEM_wen = 1 ;
				// ADD_STORE:
				default:	M_MEM_wen = 1 ;
			endcase
		end
		STATE_MUL: begin
			case(next_mul_state)
				// MUL_IDLE:
				MUL_INPUT:	M_MEM_wen = 0 ;
				// MUL_MUL:	M_MEM_wen = 1 ;
				// MUL_ADD:
				// MUL_MOD:	
				// MUL_STORE:
				default:	M_MEM_wen = 1 ;
			endcase
		end 
		// STATE_TRANS: 	
		// STATE_MIROR: 
		// STATE_ROTAT: 
		// STATE_OUTPT: 	
		default: 		M_MEM_wen = 1 ;
	endcase
end
// reg [4:0] M_MEM_a;
always @(*) begin
	case(next_state)
		// STATE_IDLE: 
		// STATE_SETUP: 
		STATE_ADD: begin
			case(next_add_state)
				// ADD_IDLE:
				ADD_INPUT:	M_MEM_a = adr_cnt ;
				ADD_ADD: begin
					if (adr_cnt==SizeSize)	M_MEM_a = 0 ;
					else 					M_MEM_a = adr_cnt ;
				end
				// ADD_STORE:
				default:	M_MEM_a = 0 ;
			endcase
		end
		STATE_MUL: begin
			case(next_mul_state)
				// MUL_IDLE:
				MUL_INPUT:	M_MEM_a = adr_cnt ;
				MUL_MUL:	M_MEM_a = next_M_adr ;
				// MUL_ADD:
				// MUL_MOD:	
				// MUL_STORE:
				default:	M_MEM_a = 0 ;
			endcase
		end 
		// STATE_TRANS: 
		// STATE_MIROR: 
		// STATE_ROTAT: 
		// STATE_OUTPT: 
		default: 		M_MEM_a = 0 ;
	endcase
end
// wire [31:0] M_MEM_in;
assign M_MEM_in = in_data ;
/*always @(*) begin
	case(next_state)
		// STATE_IDLE: 
		// STATE_SETUP: 
		STATE_ADD: begin
			case(next_add_state)
				// ADD_IDLE:
				ADD_INPUT:	M_MEM_in = in_data ;
				// ADD_ADD:
				// ADD_STORE:
				default:	M_MEM_in = 0 ;
			endcase
		end
		STATE_MUL: begin
			case(next_mul_state)
				// MUL_IDLE:
				MUL_INPUT:	M_MEM_in = in_data ;
				// MUL_MUL:
				// MUL_ADD:
				// MUL_MOD:	
				// MUL_STORE:
				default:	M_MEM_in = 0 ;
			endcase
		end  
		// STATE_TRANS: 
		// STATE_MIROR: 
		// STATE_ROTAT: 
		// STATE_OUTPT: 
		default: 		M_MEM_in = 0 ;
	endcase
end*/
// reg M_MEM_oen;			// always enable
assign M_MEM_oen = 0 ;
//================================================================
//  MEMORY CONTROL : MATRIX T
//================================================================
// wire [31:0] T_MEM_out;
// MYMEM M_T( .Q(T_MEM_out), .CLK(clk), .CEN(T_MEM_cen), .WEN(T_MEM_wen), .A(T_MEM_a), .D(T_MEM_in), .OEN(T_MEM_oen) );
MEM256_31 M_T( .Q(T_MEM_out), .CLK(clk), .CEN(T_MEM_cen), .WEN(T_MEM_wen), .A(T_MEM_a), .D(T_MEM_in), .OEN(T_MEM_oen) );
// wire T_MEM_cen;			// always enable
assign T_MEM_cen = 0 ;
// reg T_MEM_wen;
always @(*) begin
	case(next_state)
		// STATE_IDLE: 	
		// STATE_SETUP: 
		// STATE_ADD:
		STATE_MUL: begin
			case(next_mul_state)
				// MUL_IDLE:
				// MUL_INPUT:	
				// MUL_MUL:
				// MUL_MOD:	
				MUL_STORE:	T_MEM_wen = 0 ;
				// MUL_FUCKU:	T_MEM_wen = 1 ;
				default:	T_MEM_wen = 1 ;
			endcase
		end 
		STATE_TRANS: begin
			case(next_tmr_state)
				// TMR_IDLE:
				TMR_TO_T:	T_MEM_wen = 0 ;
				TMR_REST:	T_MEM_wen = 0 ;
				// TMR_TO_C:	T_MEM_wen = 1 ;
				default:	T_MEM_wen = 1 ;
			endcase
		end 
		STATE_MIROR: begin
			case(next_tmr_state)
				// TMR_IDLE:
				TMR_TO_T:	T_MEM_wen = 0 ;
				TMR_REST:	T_MEM_wen = 0 ;
				// TMR_TO_C:	T_MEM_wen = 1 ;
				default:	T_MEM_wen = 1 ;
			endcase
		end 
		STATE_ROTAT: begin
			case(next_tmr_state)
				// TMR_IDLE:
				TMR_TO_T:	T_MEM_wen = 0 ;
				TMR_REST:	T_MEM_wen = 0 ;
				// TMR_TO_C:	T_MEM_wen = 1 ;
				default:	T_MEM_wen = 1 ;
			endcase
		end  
		// STATE_OUTPT:
		default: 		T_MEM_wen = 1 ;
	endcase
end
// reg [4:0] T_MEM_a;
always @(*) begin
	case(next_state)
		// STATE_IDLE: 
		// STATE_SETUP: 
		// STATE_ADD:
		STATE_MUL: begin
			T_MEM_a = adr_cnt ;
			/*case(next_mul_state)
				// MUL_IDLE:
				// MUL_INPUT:	
				// MUL_MUL:
				// MUL_MOD:	
				MUL_STORE:	T_MEM_a = adr_cnt ;
				MUL_FUCKU:	T_MEM_a = adr_cnt ;
				// default:	T_MEM_a = 0 ;
			endcase*/
		end 
		STATE_TRANS: begin
			case(next_tmr_state)
				// TMR_IDLE:
				// TMR_TO_T:	T_MEM_a = next_T_adr ;
				// TMR_REST:	T_MEM_a = next_T_adr ;
				TMR_TO_C:	T_MEM_a = adr_cnt ;
				// default:	T_MEM_a = 0 ;
				default:	T_MEM_a = next_T_adr ;
			endcase
		end 
		STATE_MIROR: begin
			case(next_tmr_state)
				// TMR_IDLE:
				// TMR_TO_T:	T_MEM_a = next_T_adr ;
				// TMR_REST:	T_MEM_a = next_T_adr ;
				TMR_TO_C:	T_MEM_a = adr_cnt ;
				// default:	T_MEM_a = 0 ;
				default:	T_MEM_a = next_T_adr ;
			endcase
		end 
		STATE_ROTAT: begin
			case(next_tmr_state)
				// TMR_IDLE:
				// TMR_TO_T:	T_MEM_a = next_T_adr ;
				// TMR_REST:	T_MEM_a = next_T_adr ;
				TMR_TO_C:	T_MEM_a = adr_cnt ;
				// default:	T_MEM_a = 0 ;
				default:	T_MEM_a = next_T_adr ;
			endcase
		end  
		// STATE_OUTPT: 	
		default: 		T_MEM_a = 0 ;
	endcase
end
// reg [31:0] C_MEM_in;
always @(*) begin
	case(next_state)
		// STATE_IDLE: 
		// STATE_SETUP: 
		// STATE_ADD:
		STATE_MUL: begin
			T_MEM_in = alu ;
			/*case(next_mul_state)
				// MUL_IDLE:
				// MUL_INPUT:	
				// MUL_MUL:
				// MUL_MOD:	
				MUL_STORE:	T_MEM_in = alu ;
				// MUL_FUCKU:	
				default:	T_MEM_in = 0 ;
			endcase*/
		end 
		STATE_TRANS: begin
			T_MEM_in = C_MEM_out ;
			/*case(next_tmr_state)
				// TMR_IDLE:
				TMR_TO_T:	T_MEM_in = C_MEM_out ;
				TMR_REST:	T_MEM_in = C_MEM_out ;
				// TMR_TO_C:
				default:	T_MEM_in = 0 ;
			endcase*/
		end 
		STATE_MIROR: begin
			T_MEM_in = C_MEM_out ;
			/*case(next_tmr_state)
				// TMR_IDLE:
				TMR_TO_T:	T_MEM_in = C_MEM_out ;
				TMR_REST:	T_MEM_in = C_MEM_out ;
				// TMR_TO_C:
				default:	T_MEM_in = 0 ;
			endcase*/
		end 
		STATE_ROTAT: begin
			T_MEM_in = C_MEM_out ;
			/*case(next_tmr_state)
				// TMR_IDLE:
				TMR_TO_T:	T_MEM_in = C_MEM_out ;
				TMR_REST:	T_MEM_in = C_MEM_out ;
				// TMR_TO_C:
				default:	T_MEM_in = 0 ;
			endcase*/
		end  
		// STATE_OUTPT: 
		default: 		T_MEM_in = 0 ;
	endcase
end
// reg T_MEM_oen;			// always enable
assign T_MEM_oen = 0 ;
//================================================================
// FSM : in STATE_TRANS / STATE_MIROR / STATE_ROTAT
//================================================================
// reg [1:0] current_tmr_state;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) current_tmr_state <= TMR_IDLE ;
	else 		current_tmr_state <= next_tmr_state ;
end
// reg [1:0] next_tmr_state;
always @(*) begin
	case(current_tmr_state)
		TMR_IDLE: begin
			if (next_state==STATE_TRANS || next_state==STATE_MIROR || next_state==STATE_ROTAT)
				next_tmr_state = TMR_TO_T ;
			else next_tmr_state = current_tmr_state ;
		end
		TMR_TO_T: begin
			if (adr_cnt==SizeSize)	next_tmr_state = TMR_REST ;
			else 					next_tmr_state = current_tmr_state ;
		end
		TMR_REST:	next_tmr_state = TMR_TO_C ;
		TMR_TO_C: begin
			if (adr_cnt>SizeSize)	next_tmr_state = TMR_IDLE ;
			else 					next_tmr_state = current_tmr_state ;
		end
		default:	next_tmr_state = TMR_IDLE ;
	endcase
end
//================================================================
//  FSM : in STATE_ADD
//================================================================
// reg [1:0] current_add_state;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)	current_add_state <= ADD_IDLE ;
	else 		current_add_state <= next_add_state ;
end
// reg [1:0] next_add_state;
always @(*) begin
	case(current_add_state)
		ADD_IDLE: begin
			if (next_state==STATE_ADD)	next_add_state = ADD_INPUT ;
			else 						next_add_state = current_add_state ;
		end
		ADD_INPUT: begin
			if (adr_cnt==SizeSize)	next_add_state = ADD_ADD ;
			else 					next_add_state = current_add_state ;
		end
		ADD_ADD: begin
			if (flag_fisrt_add==1 && is_overflow==0)	next_add_state = ADD_STORE ;
			else										next_add_state = current_add_state ;
		end
		ADD_STORE: begin
			if (adr_cnt==SizeSize)	next_add_state = ADD_IDLE ;
			else 					next_add_state = ADD_ADD ;
		end
		default:	next_add_state = ADD_IDLE ;
	endcase
end
//================================================================
//  FSM : in STATE_MUL
//================================================================
// reg [2:0] current_mul_state;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)	current_mul_state <= MUL_IDLE ;
	else 		current_mul_state <= next_mul_state ;
end
// reg [2:0] next_mul_state;
always @(*) begin
	case(current_mul_state)
		MUL_IDLE: begin
			if (next_state==STATE_MUL)	next_mul_state = MUL_INPUT ;
			else 						next_mul_state = current_mul_state ;
		end
		MUL_INPUT: begin
			if (adr_cnt==SizeSize)	next_mul_state = MUL_MUL ;
			else 					next_mul_state = current_mul_state ;
		end
		MUL_MUL: begin
			if (sub_cnt==Size)	next_mul_state = MUL_MOD ;
			else 				next_mul_state = current_mul_state ;
		end
		MUL_MOD: begin
			if (flag_fisrt_mul==1 && is_overflow==0)	next_mul_state = MUL_STORE ;
			else 										next_mul_state = current_mul_state ;
		end
		MUL_STORE: begin
			if (adr_cnt==SizeSize)	next_mul_state = MUL_FUCKU ;
			else 					next_mul_state = MUL_MUL ;
		end
		MUL_FUCKU: begin
			// if (adr_cnt==SizeSize+1)	next_mul_state = MUL_IDLE ;
			if (flag_last_store==1)	next_mul_state = MUL_IDLE ;
			else 					next_mul_state = current_mul_state ;
		end
		default: 	next_mul_state = MUL_IDLE ;
	endcase
end
//================================================================
//  FSM
//================================================================
// reg [2:0] current_state;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)	current_state <= STATE_IDLE ;
	else 		current_state <= next_state ;
end
// wire [2:0] next_state;
always @(*) begin
	next_state = current_state ;
	case(current_state)
		STATE_IDLE: 	if (in_valid==1'b1)		next_state = action ;
		STATE_SETUP: 	if (adr_cnt==SizeSize)	next_state = STATE_OUTPT ;
		STATE_ADD: 		if (next_add_state==ADD_IDLE)	next_state = STATE_OUTPT ;
		STATE_MUL: 		if (next_mul_state==MUL_IDLE)	next_state = STATE_OUTPT ;
		STATE_TRANS:	if (next_tmr_state==TMR_IDLE)	next_state = STATE_OUTPT ;
		STATE_MIROR:	if (next_tmr_state==TMR_IDLE)	next_state = STATE_OUTPT ;
		STATE_ROTAT:	if (next_tmr_state==TMR_IDLE)	next_state = STATE_OUTPT ;
		STATE_OUTPT: begin
			if (Action<3'd3) begin
				if (adr_cnt>SizeSize)	next_state = STATE_IDLE ;
				else 					next_state = current_state ;
			end
			else	next_state = STATE_IDLE ;
		end
		default: 	next_state = STATE_IDLE ;
	endcase
end
//================================================================
//  i, j
//================================================================
// wire [4:0] adr_cnt_i, adr_cnt_j;
// DIVIDE div( .inst_a(adr_cnt), .inst_b(Size), .q_inst(adr_cnt_i), .r_inst(adr_cnt_j) );
assign adr_cnt_i = adr_cnt / Size ;
assign adr_cnt_j = adr_cnt % Size ;
// wire [7:0] next_C_adr, next_M_adr;
assign next_C_adr = (current_mul_state!=MUL_MUL) ? 0 : adr_cnt_j + sub_cnt*Size ;
assign next_M_adr = (current_mul_state!=MUL_MUL) ? 0 : adr_cnt_i*Size + sub_cnt ;
// reg [4:0] tmr_i, tmr_j;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		tmr_i <= 0 ;
		tmr_j <= 0 ;
	end
	else begin
		case(next_state)
			STATE_TRANS: begin
				tmr_i <= adr_cnt_j ;
				tmr_j <= adr_cnt_i ;				
			end
			STATE_MIROR: begin
				tmr_i <= adr_cnt_i ;
				tmr_j <= Size - adr_cnt_j - 1 ;
			end
			STATE_ROTAT: begin
				tmr_i <= Size - adr_cnt_j - 1 ;
				tmr_j <= adr_cnt_i ;
			end
		endcase
	end
end
// wire [7:0] next_T_adr;
assign next_T_adr = tmr_i*Size + tmr_j ;
//================================================================
//  STATE_MUL
//================================================================
// reg [4:0] sub_cnt;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	sub_cnt <= 0 ;
	else begin
		if (next_state==STATE_MUL) begin
			if (current_mul_state==MUL_MUL) begin
				if (sub_cnt==Size)	sub_cnt <= 0 ;
				else 				sub_cnt <= sub_cnt + 1 ;
			end
		end
		else 	sub_cnt <= 0 ;
	end
end
//================================================================
//  STATE_SETUP
//================================================================
// reg [2:0] Action;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)		Action <= 0 ;
	else begin
		if (next_state==STATE_OUTPT)	Action <= Action ;
		else 		Action <= next_state ;
	end
end
wire w_action = (adr_cnt==0 && next_state==STATE_SETUP) ? action : STATE_IDLE ;
// reg [4:0] Size;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) Size <= 5'd0 ;
	else begin
		if (w_action==STATE_SETUP) begin
			case(size)
				2'b00: Size <= 5'd2 ;
				2'b01: Size <= 5'd4 ;
				2'b10: Size <= 5'd8 ;
				2'b11: Size <= 5'd16 ;
			endcase
		end
	end
end
// reg [8:0] SizeSize;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) SizeSize <= 9'd0 ;
	else begin
		if (w_action==STATE_SETUP) begin
			case(size)
				2'b00: SizeSize <= 9'd4 ;
				2'b01: SizeSize <= 9'd16 ;
				2'b10: SizeSize <= 9'd64 ;
				2'b11: SizeSize <= 9'd256 ;
			endcase
		end
	end
end
endmodule