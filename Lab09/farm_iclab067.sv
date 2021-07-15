//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Lab09		 : Happy Farm (HF)
//   Author    	 : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : farm.sv
//   Module Name : farm
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################ 

module farm(input clk, INF.farm_inf inf);
import usertype::*;
//================================================================
//  integer / genvar / parameter
//================================================================
//  MODE
/*parameter MODE_READ  = 1'b1 ;
parameter MODE_WRITE = 1'b0 ;*/
//  FSM
/*parameter S_GET_DEPOSIT = 3'd0  ; 
parameter S_IDLE		= 3'd1  ;
parameter S_SAVE_LAND	= 3'd2  ;
parameter S_GET_LAND	= 3'd3  ;
parameter S_EXECUTE		= 3'd4  ;
parameter S_OUTPUT		= 3'd5  ;*/
//================================================================
//  logic
//================================================================
//  FSM
Farm_sta current_state, next_state;
//  
Land id, last_id;
Action act;
Crop_cat cat;
Water_amnt amnt, next_amnt;
//   LAND
Land_Info land_now, land_before;
logic [31:0] deposit;
// 
logic is_1st_land;
logic flag_id, flag_act, flag_amnt;
// 
logic flag_dram;
//================================================================
//  FSM
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)		current_state <= S_GET_DEPOSIT ;
	else 				current_state <= next_state ;
end
always_comb begin
	next_state = current_state ;
	case(current_state)
		S_GET_DEPOSIT:	if (inf.C_out_valid==1)		next_state = S_IDLE ;
		S_IDLE: begin
			if (flag_act==1) begin
				if (flag_id==1) begin
					if (is_1st_land==1)		next_state = S_GET_LAND ;
					else 					next_state = S_SAVE_LAND ;
				end
				else begin
					case(act)
						Seed:	if (flag_amnt==1)	next_state = S_EXE1 ;
						Water:	if (flag_amnt==1)					next_state = S_EXE1 ;
						Reap:	next_state = S_EXE1 ;
						Steal:	next_state = S_EXE1 ;
						Check_dep:		next_state = S_OUTPUT ;
					endcase
				end
			end
		end
		S_SAVE_LAND:	if (inf.C_out_valid==1)		next_state = S_GET_LAND ;
		S_GET_LAND: begin
			if (inf.C_out_valid==1 || flag_dram==1) begin
				if (flag_act==1) begin
					case(act)
						Seed:	if (flag_amnt==1)	next_state = S_EXE1 ;
						Water:	if (flag_amnt==1)					next_state = S_EXE1 ;
						Reap:	next_state = S_EXE1 ;
						Steal:	next_state = S_EXE1 ;
					endcase
				end
			end
		end
		S_EXE1:		next_state = S_EXE2 ;
		S_EXE2:		next_state = S_OUTPUT ;
		S_OUTPUT:	next_state = S_IDLE ;
	endcase
end
//================================================================
//   FLAG_DRAM
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)		flag_dram <= 0 ;
	else begin
		if (current_state==S_GET_LAND && inf.C_out_valid==1)	flag_dram <= 1 ;
		else if (current_state==S_IDLE)							flag_dram <= 0 ;
	end
end
//================================================================
//   ERROR
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) 	inf.complete <= 0 ;
	else begin
		if (current_state==S_EXE1) begin
			case(act)
				Seed: begin
					if (land_now.land_status[7:4]!=No_sta)	
						inf.complete <= 0 ;
				end
				Water: begin
					if (land_now.land_status[7:4]==No_sta || land_now.land_status[7:4]==Snd_sta)	
						inf.complete <= 0 ;
				end
				Reap: begin
					if (land_now.land_status[7:4]==No_sta || land_now.land_status[7:4]==Zer_sta)	
						inf.complete <= 0 ;
				end
				Steal: begin
					if (land_now.land_status[7:4]==No_sta || land_now.land_status[7:4]==Zer_sta)	
						inf.complete <= 0 ;
				end
			endcase
		end
		else if (current_state==S_IDLE)
			inf.complete <= 1 ;
	end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) 	inf.err_msg <= No_Err ;
	else begin
		if (current_state==S_EXE1) begin
			case(act)
				Seed: begin
					if (land_now.land_status[7:4]!=No_sta)			inf.err_msg <= Not_Empty ;
				end
				Water: begin
					if (land_now.land_status[7:4]==No_sta)			inf.err_msg <= Is_Empty ;
					else if (land_now.land_status[7:4]==Snd_sta)	inf.err_msg <= Has_Grown ;
				end
				Reap: begin
					if (land_now.land_status[7:4]==No_sta)			inf.err_msg <= Is_Empty ;
					else if (land_now.land_status[7:4]==Zer_sta)	inf.err_msg <= Not_Grown ;
				end
				Steal: begin
					if (land_now.land_status[7:4]==No_sta)			inf.err_msg <= Is_Empty ;
					else if (land_now.land_status[7:4]==Zer_sta)	inf.err_msg <= Not_Grown ;
				end
			endcase
		end
		else if (current_state==S_IDLE)		inf.err_msg <= No_Err ;
	end
end
//================================================================
//   LAND
//================================================================
logic [4:0] seed_price;
always_comb begin
	seed_price = 0 ;
	case(cat)
		Potato: seed_price = 5  ;
		Corn:	seed_price = 10 ;
		Tomato:	seed_price = 15 ;
		Wheat:	seed_price = 20 ;
	endcase
end
logic [6:0] sell_price;
always_comb begin
	sell_price = 0 ;
	case(land_now.land_status[3:0])
		Potato: begin
			if (land_now.land_status[7:4]==Snd_sta)			sell_price = 25 ;
			else if (land_now.land_status[7:4]==Fst_sta)	sell_price = 10 ;
		end
		Corn: begin
			if (land_now.land_status[7:4]==Snd_sta)			sell_price = 50 ;
			else if (land_now.land_status[7:4]==Fst_sta)	sell_price = 20 ;
		end
		Tomato: begin
			if (land_now.land_status[7:4]==Snd_sta)			sell_price = 75 ;
			else if (land_now.land_status[7:4]==Fst_sta)	sell_price = 30 ;
		end
		Wheat: begin
			if (land_now.land_status[7:4]==Snd_sta)			sell_price = 100 ;
			else if (land_now.land_status[7:4]==Fst_sta)	sell_price = 40 ;
		end
	endcase 
end
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) 	deposit <= 0 ;
	else begin
		if (current_state==S_GET_DEPOSIT) begin
			if (inf.C_out_valid==1)	
				// deposit <= inf.C_data_r ;
				deposit <= { inf.C_data_r[7:0] , inf.C_data_r[15:8] , inf.C_data_r[23:16] , inf.C_data_r[31:24] } ;
		end
		else if (current_state==S_EXE1) begin
			if (act==Seed && land_now.land_status[7:4]==No_sta) begin
				deposit <= deposit - seed_price ;
			end
			else if (act==Reap && land_now.land_status[7:4]!=No_sta && land_now.land_status[7:4]!=Zer_sta) begin
				deposit <= deposit + sell_price ;
			end
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) 	land_before <= 0 ;
	else begin
		if (current_state==S_EXE1)
			land_before <= land_now ;
	end
end
logic [15:0] thr_Snd, thr_Fst;	// threshold
always_comb begin
	thr_Snd = 0 ;
	if (act==Seed) begin
		case(cat)
			Potato:	thr_Snd = 16'h0080 ;
			Corn:	thr_Snd = 16'h0200 ;
			Tomato:	thr_Snd = 16'h0800 ;
			Wheat:	thr_Snd = 16'h2000 ;
		endcase
	end
	else begin
		case(land_now.land_status[3:0])
			Potato:	thr_Snd = 16'h0080 ;
			Corn:	thr_Snd = 16'h0200 ;
			Tomato:	thr_Snd = 16'h0800 ;
			Wheat:	thr_Snd = 16'h2000 ;
		endcase
	end
end
always_comb begin
	thr_Fst = 0 ;
	if (act==Seed) begin
		case(cat)
			Potato:	thr_Fst = 16'h0010 ;
			Corn:	thr_Fst = 16'h0040 ;
			Tomato:	thr_Fst = 16'h0100 ;
			Wheat:	thr_Fst = 16'h0400 ;
		endcase
	end
	else begin
		case(land_now.land_status[3:0])
			Potato:	thr_Fst = 16'h0010 ;
			Corn:	thr_Fst = 16'h0040 ;
			Tomato:	thr_Fst = 16'h0100 ;
			Wheat:	thr_Fst = 16'h0400 ;
		endcase
	end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) 	land_now <= 0 ;
	else begin
		if (current_state==S_GET_LAND) begin
			if (inf.C_out_valid==1)	begin
				land_now <= { inf.C_data_r[7:0] , inf.C_data_r[15:8] , inf.C_data_r[23:16] , inf.C_data_r[31:24] } ;
				// land_now <= inf.C_data_r ;
			end
		end
		else if (current_state==S_EXE1) begin
			case(act)
				Seed: begin
					if (land_now.land_status[7:4]==No_sta) begin
						land_now.water_amnt <= amnt ;
						land_now.land_status[3:0] <= cat ;
						if (amnt>=thr_Snd)		land_now.land_status[7:4] <= Snd_sta ;
						else if (amnt>=thr_Fst)	land_now.land_status[7:4] <= Fst_sta ;
						else 					land_now.land_status[7:4] <= Zer_sta ;
					end
				end
				Water: begin
					if (land_now.land_status[7:4]!=No_sta && land_now.land_status[7:4]!=Snd_sta) begin
						land_now.water_amnt <= next_amnt ;
						if (next_amnt>=thr_Snd)			land_now.land_status[7:4] <= Snd_sta ;
						else if (next_amnt>=thr_Fst)	land_now.land_status[7:4] <= Fst_sta ;
						else 							land_now.land_status[7:4] <= Zer_sta ;
					end
				end
				Reap: begin
					if (land_now.land_status[7:4]!=No_sta && land_now.land_status[7:4]!=Zer_sta) begin
						land_now.land_status[7:4] <= No_sta ;
						land_now.land_status[3:0] <= No_cat ;
						land_now.water_amnt <= 0 ;
					end
				end
				Steal: begin
					if (land_now.land_status[7:4]!=No_sta && land_now.land_status[7:4]!=Zer_sta) begin
						land_now.land_status[7:4] <= No_sta ;
						land_now.land_status[3:0] <= No_cat ;
						land_now.water_amnt <= 0 ;
					end	
				end
			endcase
		end
	end
end
assign next_amnt = land_now.water_amnt + amnt ;
//================================================================
//   INPUT FLAG
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)				flag_id <= 0 ;
	else begin 
		if (inf.id_valid==1)			flag_id <= 1 ;
		else if (next_state==S_OUTPUT)	flag_id <= 0 ;
	end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)				flag_act <= 0 ;
	else begin 
		if (inf.act_valid==1)			flag_act <= 1 ;
		else if (next_state==S_OUTPUT)	flag_act <= 0 ;
	end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)				flag_amnt <= 0 ;
	else begin
		if (inf.amnt_valid==1)			flag_amnt <= 1 ;
		else if (next_state==S_OUTPUT)	flag_amnt <= 0 ;
	end
end
//================================================================
//   INPUT
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)				id <= 0 ;
	else if (inf.id_valid==1)	id <= inf.D.d_id[0] ;
end
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)				last_id <= 0 ;
	else if (inf.id_valid==1)	last_id <= id ;
end
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)				act <= No_action ;
	else if (inf.act_valid==1)	act <= inf.D.d_act[0] ;
end
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)				cat <= No_cat ;
	else if (inf.cat_valid==1)	cat <= inf.D.d_cat[0] ;
end
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)				amnt <= 0 ;
	else if (inf.amnt_valid==1)	amnt <= inf.D.d_amnt ;
end
//================================================================
//   Farm System (farm.sv) vs Bridge (bridge.sv)
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) 	inf.C_addr <= 0 ;
	else begin
		case(next_state)
			S_GET_DEPOSIT: 	inf.C_addr <= 8'd255 ;
			S_SAVE_LAND:	inf.C_addr <= last_id ;
			S_GET_LAND:		inf.C_addr <= id ;
		endcase
	end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)		inf.C_data_w <= 0 ;
	else begin
		// inf.C_data_w <= land_now ;
		inf.C_data_w <= { land_now[7:0] , land_now[15:8] , land_now[23:16] , land_now[31:24] } ;
	end
end
logic flag;
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) 	flag <= 0 ;
	else begin
		if (inf.C_out_valid==1) 	flag <= 0 ;
		else begin
			case(next_state)
				S_GET_DEPOSIT:	flag <= 1 ;
				S_SAVE_LAND: 	flag <= 1 ;
				S_GET_LAND:		flag <= 1 ;
				default:		flag <= 0 ;
			endcase 
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)		inf.C_in_valid <= 0 ;
	else begin
		if (flag==1)	inf.C_in_valid <= 0 ;
		else begin
			case(next_state)
				S_GET_DEPOSIT:	inf.C_in_valid <= 1 ;
				S_SAVE_LAND: 	inf.C_in_valid <= 1 ;
				S_GET_LAND:		inf.C_in_valid <= 1 ;
				default:		inf.C_in_valid <= 0 ;
			endcase 
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) 	inf.C_r_wb <= 0 ;
	else begin
		case(next_state)
			S_GET_DEPOSIT:	inf.C_r_wb <= MODE_READ ;
			S_SAVE_LAND: 	inf.C_r_wb <= MODE_WRITE ;
			S_GET_LAND:		inf.C_r_wb <= MODE_READ ;
		endcase 
	end
end
//================================================================
//   OUTPUT
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)						is_1st_land <= 1 ;
	else if (next_state==S_GET_LAND)	is_1st_land <= 0 ;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) 	inf.out_valid <= 0 ;
	else begin
		if (next_state==S_OUTPUT)	inf.out_valid <= 1 ;
		else 						inf.out_valid <= 0 ;
	end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) 	inf.out_info <= 0 ;
	else begin
		if (next_state==S_OUTPUT) begin
			if (act!=Check_dep && inf.complete==1) begin
				if (act==Steal || act==Reap)	inf.out_info <= land_before ;
				else 							inf.out_info <= land_now ;
			end
			else	inf.out_info <= 0 ;
		end
		else 		inf.out_info <= 0 ;
	end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) 	inf.out_deposit <= 0 ;
	else begin
		if (next_state==S_OUTPUT) begin
			if (act==Check_dep)		inf.out_deposit <= deposit ;
		end
		else	inf.out_deposit <= 0 ;
	end
end

endmodule