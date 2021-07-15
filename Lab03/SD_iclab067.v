//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Lab03			: Sudoku (SD)
//   Author         : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : SD.v
//   Module Name : SD
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module SD(
    // Input signals
    clk,
    rst_n,
	in_valid,
	in,
    // Output signals
    out_valid,
    out
);
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
input clk, rst_n, in_valid;
input [3:0] in;
output reg out_valid;
output reg [3:0] out;
//================================================================
//  integer / genvar / parameters
//================================================================
integer i, j;
genvar idx, jdx, ndx;
// FSM
parameter STATE_IDLE    = 2'd0 ;
parameter STATE_FORWARD = 2'd1 ;
parameter STATE_BAKWARD = 2'd2 ;
parameter STATE_OUTPUT  = 2'd3 ;
//================================================================
//   Wires & Registers 
//================================================================
// INPUT
reg [6:0] in_cnt;
reg [3:0] Board[0:8][0:8];
reg [3:0] Blanks_r[15:0], Blanks_c[15:0];
// FSM
reg [1:0] current_state;
reg [1:0] next_state;
// 	EXIST
wire exist_row[1:9][0:8];	// [number in sudoku 1~9][position 0~8]
wire exist_col[1:9][0:8];	// [number in sudoku 1~9][position 0~8]
wire exist_box[1:9][0:8];	// [number in sudoku 1~9][position 0~8]
// 	IS_LEGAL
wire [3:0] need_row[1:9], need_col[1:9], need_box[1:9];
wire [3:0] total_need_row, total_need_col, total_need_box;
wire is_legal;
// NUM_BLANK
reg [3:0] num_blank;
// 	FORWARD & BACKWARD
reg [3:0] ptr_current_blank;
reg [3:0] current_c, current_r;
// 	FORWARD
reg [3:0] next_value;
reg possible_value[1:9];
//  PRE_OUTPUT
reg [3:0] out_cnt;
//================================================================
//  FSM
//================================================================
// reg [1:0] current_state;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) current_state <= STATE_IDLE ;
	else 		current_state <= next_state ;
end
// reg [1:0] next_state;
always @(*) begin
	case(current_state)
		STATE_IDLE: begin
			if (in_cnt==7'd81)	next_state = STATE_FORWARD ;
			else 				next_state = STATE_IDLE ;
		end
		STATE_FORWARD: begin
			if (ptr_current_blank==4'd0)	next_state = STATE_OUTPUT ;
			else if (next_value==4'd0)		next_state = STATE_BAKWARD ;
			else 							next_state = STATE_FORWARD ;
		end
		STATE_BAKWARD: begin
			if (ptr_current_blank==4'd0)	next_state = STATE_OUTPUT ;
			else if (next_value==4'd0)		next_state = STATE_BAKWARD ;
			else 							next_state = STATE_FORWARD ;
		end		
		STATE_OUTPUT: begin
			if (is_legal==1'b0 || out_cnt==4'd0 || num_blank==4'd15)	next_state = STATE_IDLE ;
			else next_state = STATE_OUTPUT ;
		end
	endcase
end
//================================================================
//  OUTPUT : out_valid & out
//================================================================
// output reg out_valid;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)		out_valid <= 1'b0 ;
	else begin
		if (next_state==STATE_OUTPUT)	out_valid <= 1'b1 ;
		else 		out_valid <= 1'b0 ;
	end
end
// output reg [3:0] out;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)		out <= 4'd0 ;
	else begin
		if (next_state==STATE_OUTPUT) begin
			if (is_legal==1'b0 || num_blank==4'd15)		out <= 4'd10 ;
			else 	out <= Board[ Blanks_r[out_cnt] ][ Blanks_c[out_cnt] ] ;
		end
		else  	out <= 4'd0 ;
	end
end
//================================================================
//  PRE_OUTPUT
//================================================================
// reg [3:0] out_cnt;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)	out_cnt <= 4'd15 ;
	else begin
		if (next_state==STATE_IDLE) 		out_cnt <= 4'd15 ;
		else if (next_state==STATE_OUTPUT)	out_cnt <= out_cnt - 1 ;
	end
end
//================================================================
// 	FORWARD
//================================================================
// reg [3:0] next_value;
always @(*) begin
		 if (possible_value[1]==1'b1)	next_value = 4'd1 ;	
	else if (possible_value[2]==1'b1)	next_value = 4'd2 ;
	else if (possible_value[3]==1'b1)	next_value = 4'd3 ;
	else if (possible_value[4]==1'b1)	next_value = 4'd4 ;
	else if (possible_value[5]==1'b1)	next_value = 4'd5 ;
	else if (possible_value[6]==1'b1)	next_value = 4'd6 ;
	else if (possible_value[7]==1'b1)	next_value = 4'd7 ;
	else if (possible_value[8]==1'b1)	next_value = 4'd8 ;
	else if (possible_value[9]==1'b1)	next_value = 4'd9 ;
	// no solution
	else	next_value = 4'd0;	
end
// reg possible_value[1:9];
generate
for( ndx=1 ; ndx<10 ; ndx=ndx+1 ) begin
	always @(*) begin
		possible_value[ndx] = (Board[current_r][current_c]<ndx) && (exist_row[ndx][current_r]==1'b0) && (exist_col[ndx][current_c]==1'b0) && (exist_box[ndx][ 3*(current_r/3) + current_c/3 ]==1'b0) ;
	end
end
endgenerate
//================================================================
// 	FORWARD & BACKWARD
//================================================================
// reg [3:0] ptr_current_blank;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	ptr_current_blank <= 4'd15 ;
	else begin
		if (next_state==STATE_FORWARD)		ptr_current_blank <= ptr_current_blank - 1 ;
		else if (next_state==STATE_BAKWARD)	ptr_current_blank <= ptr_current_blank + 1 ;
		else if (next_state==STATE_OUTPUT)	ptr_current_blank <= 4'd15;
	end
end
// reg [3:0] current_c, current_r;
always @(*) begin
	case(ptr_current_blank)
		4'd15 :		current_r = Blanks_r[15] ;
		4'd14 :		current_r = Blanks_r[14] ;
		4'd13 :		current_r = Blanks_r[13] ;
		4'd12 :		current_r = Blanks_r[12] ;
		4'd11 :		current_r = Blanks_r[11] ;
		4'd10 :		current_r = Blanks_r[10] ;
		4'd9  :		current_r = Blanks_r[9 ] ;
		4'd8  :		current_r = Blanks_r[8 ] ;
		4'd7  :		current_r = Blanks_r[7 ] ;
		4'd6  :		current_r = Blanks_r[6 ] ;
		4'd5  :		current_r = Blanks_r[5 ] ;
		4'd4  :		current_r = Blanks_r[4 ] ;
		4'd3  :		current_r = Blanks_r[3 ] ;
		4'd2  :		current_r = Blanks_r[2 ] ;
		4'd1  :		current_r = Blanks_r[1 ] ;
		default:	current_r = Blanks_r[0 ] ;
	endcase
end
always @(*) begin
	case(ptr_current_blank)
		4'd15 :		current_c = Blanks_c[15] ;
		4'd14 :		current_c = Blanks_c[14] ;
		4'd13 :		current_c = Blanks_c[13] ;
		4'd12 :		current_c = Blanks_c[12] ;
		4'd11 :		current_c = Blanks_c[11] ;
		4'd10 :		current_c = Blanks_c[10] ;
		4'd9  :		current_c = Blanks_c[9 ] ;
		4'd8  :		current_c = Blanks_c[8 ] ;
		4'd7  :		current_c = Blanks_c[7 ] ;
		4'd6  :		current_c = Blanks_c[6 ] ;
		4'd5  :		current_c = Blanks_c[5 ] ;
		4'd4  :		current_c = Blanks_c[4 ] ;
		4'd3  :		current_c = Blanks_c[3 ] ;
		4'd2  :		current_c = Blanks_c[2 ] ;
		4'd1  :		current_c = Blanks_c[1 ] ;
		default:	current_c = Blanks_c[0 ] ;
	endcase
end
//================================================================
//  IS_LEGAL
//================================================================
// how many numbers are lack in one row/column/box
// wire [3:0] need_row[1:9], need_col[1:9], need_box[1:9];
generate
for( ndx=1 ; ndx<10 ; ndx=ndx+1 ) begin
	assign need_row[ndx] = (exist_row[ndx][0]==0) + (exist_row[ndx][1]==0) + (exist_row[ndx][2]==0) +
						   (exist_row[ndx][3]==0) + (exist_row[ndx][4]==0) + (exist_row[ndx][5]==0) +
						   (exist_row[ndx][6]==0) + (exist_row[ndx][7]==0) + (exist_row[ndx][8]==0) ;
	assign need_col[ndx] = (exist_col[ndx][0]==0) + (exist_col[ndx][1]==0) + (exist_col[ndx][2]==0) +
						   (exist_col[ndx][3]==0) + (exist_col[ndx][4]==0) + (exist_col[ndx][5]==0) +
						   (exist_col[ndx][6]==0) + (exist_col[ndx][7]==0) + (exist_col[ndx][8]==0) ;
	assign need_box[ndx] = (exist_box[ndx][0]==0) + (exist_box[ndx][1]==0) + (exist_box[ndx][2]==0) +
						   (exist_box[ndx][3]==0) + (exist_box[ndx][4]==0) + (exist_box[ndx][5]==0) +
						   (exist_box[ndx][6]==0) + (exist_box[ndx][7]==0) + (exist_box[ndx][8]==0) ;
end
endgenerate
// how many numbers are lack within all rows/columns/boxs
// wire [3:0] total_need_row, total_need_col, total_need_box;
generate
assign total_need_row = need_row[1] + need_row[2] + need_row[3] + need_row[4] + need_row[5] + need_row[6] + need_row[7] + need_row[8] + need_row[9] ;
assign total_need_col = need_col[1] + need_col[2] + need_col[3] + need_col[4] + need_col[5] + need_col[6] + need_col[7] + need_col[8] + need_col[9] ;
assign total_need_box = need_box[1] + need_box[2] + need_box[3] + need_box[4] + need_box[5] + need_box[6] + need_box[7] + need_box[8] + need_box[9] ;
endgenerate
// is the sudoku board now legal or not
// is_legal
assign is_legal = (total_need_row==num_blank) && (total_need_col==num_blank) && (total_need_box==num_blank) ;
//================================================================
//  EXIST
//================================================================
// whether a number ndx exists in a row/column/box or not
generate
for( ndx=1 ; ndx<10 ; ndx=ndx+1 ) begin
	// wire exist_row[1:9][0:8];	// [number in sudoku 1~9][position 0~8]
	for( idx=0 ; idx<9 ; idx=idx+1 )
		assign exist_row[ndx][idx] = (Board[idx][0]==ndx) || (Board[idx][1]==ndx) || (Board[idx][2]==ndx) ||
								   	 (Board[idx][3]==ndx) || (Board[idx][4]==ndx) || (Board[idx][5]==ndx) ||
								   	 (Board[idx][6]==ndx) || (Board[idx][7]==ndx) || (Board[idx][8]==ndx) ;
	// wire exist_col[1:9][0:8];	// [number in sudoku 1~9][position 0~8]
	for( jdx=0 ; jdx<9 ; jdx=jdx+1 )
		assign exist_col[ndx][jdx] = (Board[0][jdx]==ndx) || (Board[1][jdx]==ndx) || (Board[2][jdx]==ndx) ||
									 (Board[3][jdx]==ndx) || (Board[4][jdx]==ndx) || (Board[5][jdx]==ndx) ||
									 (Board[6][jdx]==ndx) || (Board[7][jdx]==ndx) || (Board[8][jdx]==ndx) ;
	// wire exist_box[1:9][0:8];	// [number in sudoku 1~9][position 0~8]
	for( idx=1 ; idx<9 ; idx=idx+3 )
		for( jdx=1 ; jdx<9 ; jdx=jdx+3 )
			assign exist_box[ndx][ idx + (jdx-1)/3 - 1 ] = (Board[idx-1][jdx-1]==ndx) || (Board[idx-1][jdx]==ndx) || (Board[idx-1][jdx+1]==ndx) ||
					 									   (Board[idx  ][jdx-1]==ndx) || (Board[idx  ][jdx]==ndx) || (Board[idx  ][jdx+1]==ndx) ||
					 									   (Board[idx+1][jdx-1]==ndx) || (Board[idx+1][jdx]==ndx) || (Board[idx+1][jdx+1]==ndx) ;
end
endgenerate
//================================================================
//  NUM_BLANK
//================================================================
// reg [3:0] num_blank;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	num_blank <= 4'd0 ;
	else begin
		if (next_state==STATE_IDLE) begin
			if (in_valid==1'b1)
				if (in==4'd0)
					num_blank <= num_blank + 1 ;
		end
		else if (next_state==STATE_FORWARD)	begin
			if (next_value!=4'd0 && Board[current_r][current_c]==4'd0)
				num_blank <= num_blank - 1 ;
		end		
		else if (next_state==STATE_BAKWARD)	begin
			if (next_value==4'd0 && Board[current_r][current_c]!=4'd0)
				num_blank <= num_blank + 1 ;
		end		
		else if (next_state==STATE_OUTPUT)			num_blank <= 4'd0 ;
	end
end
//================================================================
//  INPUT
//================================================================
// reg [6:0] in_cnt;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)	in_cnt <= 7'd0 ;
	else begin
		if (in_valid==1'b1)					in_cnt <= in_cnt + 1 ;
		else if (next_state==STATE_OUTPUT)	in_cnt <= 7'd0 ;
	end
end

// reg [3:0] Board[0:8][0:8];
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for( i=0 ; i<9 ; i=i+1 )
			for( j=0 ; j<9 ; j=j+1 )
				Board[i][j] <= 4'd0 ;
	end
	else begin
		if (next_state==STATE_IDLE) begin
			if (in_valid==1'b1) begin
				Board[8][8] <= in ;			// neweset in
				for( i=0 ; i<9 ; i=i+1 )	// shift-register : except right-most column
					for( j=0 ; j<8 ; j=j+1 )
						Board[i][j] <= Board[i][j+1] ;
				for( i=0 ; i<8 ; i=i+1 )	// shift-register : right-most column
					Board[i][8] <= Board[i+1][0] ;
			end
		end
		else if (next_state==STATE_FORWARD) begin
			Board[current_r][current_c] <= next_value ;
		end
		else if (next_state==STATE_BAKWARD) begin
			Board[current_r][current_c] <= next_value ;
		end
	end
end
// reg [3:0] Blanks_r[15:0], Blanks_c[15:0];
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for( i=0 ; i<16 ; i=i+1 ) begin
			Blanks_r[i] <= 0 ;
			Blanks_c[i] <= 0 ;
		end
	end
	else begin
		Blanks_r[0] <= 0 ;
		Blanks_c[0] <= 0 ;
		if (next_state==STATE_IDLE) begin
			if (in_valid==1'b1) begin
				if (in==4'd0) begin
					Blanks_r[1] <= in_cnt/9 ;
					Blanks_c[1] <= in_cnt%9 ;
					for( i=2 ; i<16 ; i=i+1 ) begin
						Blanks_r[i] <= Blanks_r[i-1] ;
						Blanks_c[i] <= Blanks_c[i-1] ;
					end
				end
			end
		end
		// no need reset because every pattern has 15 blanks
	end
end

endmodule