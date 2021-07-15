//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Lab09		 : Happy Farm (HF)
//   Author    	 : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : bridge.sv
//   Module Name : bridge
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################ 

module bridge(input clk, INF.bridge_inf inf);
//================================================================
//  integer / genvar / parameter
//================================================================
//  MODE
/*parameter MODE_READ  = 1'b1 ;
parameter MODE_WRITE = 1'b0 ;*/
//  FSM
parameter STATE_IDLE         = 3'd0 ;
parameter STATE_R_WAIT_READY = 3'd1 ;
parameter STATE_R_WAIT_VALID = 3'd2 ;
parameter STATE_W_WAIT_READY = 3'd3 ;
parameter STATE_W_WAIT_VALID = 3'd4 ;
parameter STATE_OUTPUT       = 3'd5 ;
//================================================================
//  logic
//================================================================
logic [2:0] currunet_state, next_state;
logic [7:0] addr;
logic [31:0] data;
//================================================================
//  FSM
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) 	currunet_state <= STATE_IDLE ;
	else 				currunet_state <= next_state ;
end
always_comb begin
	next_state = currunet_state ;
	case(currunet_state)
		STATE_IDLE: begin
			if (inf.C_in_valid==1) begin
				if (inf.C_r_wb==MODE_READ)	next_state = STATE_R_WAIT_READY ;
				else 						next_state = STATE_W_WAIT_READY ;
			end
		end
		STATE_R_WAIT_READY: if (inf.AR_READY==1)	next_state = STATE_R_WAIT_VALID ;
		STATE_R_WAIT_VALID: if (inf.R_VALID==1)		next_state = STATE_OUTPUT ;
		STATE_W_WAIT_READY: if (inf.AW_READY==1)	next_state = STATE_W_WAIT_VALID ;
		STATE_W_WAIT_VALID: if (inf.B_VALID==1)		next_state = STATE_OUTPUT ;
		STATE_OUTPUT:	next_state = STATE_IDLE ;
	endcase 
end
//================================================================
//   AXI Lite Signals
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if(!inf.rst_n)	inf.B_READY <= 0 ;
	else 			inf.B_READY <= 1 ;
end	
// MODE_READ
assign inf.AR_VALID = (currunet_state==STATE_R_WAIT_READY) ;
assign inf.AR_ADDR  = (currunet_state==STATE_R_WAIT_READY) ? { 1'b1 , 6'b0 , addr , 2'b0 } : 0 ;	// 10000~103fc (17 bits) : 1 + (6) + 8 + 2
assign inf.R_READY  = (currunet_state==STATE_R_WAIT_VALID) ;
// MODE_WRITE
assign inf.AW_VALID = (currunet_state==STATE_W_WAIT_READY) ;
assign inf.AW_ADDR  = (currunet_state==STATE_W_WAIT_READY) ? { 1'b1 , 6'b0 , addr , 2'b0 } : 0 ;	// 10000~103fc (17 bits) : 1 + (6) + 8 + 2
assign inf.W_DATA   = data ;
assign inf.W_VALID  = (currunet_state==STATE_W_WAIT_VALID) ;
//================================================================
//   INPUT
//================================================================
always_ff @(posedge clk or  negedge inf.rst_n) begin
	if (!inf.rst_n) 	addr <= 0 ;
	else begin
		if (inf.C_in_valid==1)	addr <= inf.C_addr ;
	end
end
always_ff @(posedge clk or  negedge inf.rst_n) begin
	if (!inf.rst_n) 	data <= 0 ;
	else begin
		if (inf.C_in_valid==1 && inf.C_r_wb==MODE_WRITE)	data <= inf.C_data_w ;
	end
end
//================================================================
//   OUTPUT
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) 	inf.C_out_valid <= 0 ;
	else begin
		if (next_state==STATE_OUTPUT)	inf.C_out_valid <= 1 ;
		else 							inf.C_out_valid <= 0 ;
	end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) 	inf.C_data_r <= 0 ;
	else begin
		if (inf.R_VALID==1) 	inf.C_data_r <= inf.R_DATA ;
		// if (inf.R_VALID==1) 	inf.C_data_r <= { inf.R_DATA[7:0] , inf.R_DATA[15:8] , inf.R_DATA[23:16] , inf.R_DATA[31:24] };
		else 					inf.C_data_r <= 0 ;
	end
end

endmodule