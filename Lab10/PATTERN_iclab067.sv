//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Lab09		 : Happy Farm (HF)
//   Author    	 : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : PATTERN.sv
//   Module Name : PATTERN
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################ 
`define CYCLE_TIME 2.3
// `define SEED 67

`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_PKG.sv"
`include "success.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
//  integer & parameter
//================================================================
// 
integer i, k, s, cycles, total_cycles, y;
integer patcount, temp;
// 
integer err_cnt, cnt_Is_Empty, cnt_Not_Empty, cnt_Has_Grown, cnt_Not_Grown;
integer flag;
// 
integer base_water_amnt, act_water_cnt;
// 
parameter SEED = 67 ;
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter BASE_Addr = 65536 ;
parameter BASE_deposit = 65536 + 255*4 ;
//================================================================
//  logic
//================================================================
logic [7:0] golden_DRAM[(BASE_Addr+0):((BASE_Addr+256*4)-1)];
// operation info.
// Data golden_data;
Action golden_act;
Land golden_id, pre_id;
Crop_cat golden_cat;
Water_amnt golden_amnt;
// dram info.
Land_Info golden_land_info;
// flag
logic has_given_id;
// golden outputs
logic golden_complete;
Error_Msg golden_err_msg;
logic [31:0] current_deposit, golden_deposit, golden_out_info;
// land info. before actions (deal with Reap/Steal)
logic [31:0] temp_land_info;
//================================================================
//  class
//================================================================
class rand_gap;	
	rand int gap;
	function new (int seed);
		this.srandom(seed);		
	endfunction 
	constraint limit { gap inside {[1:1]}; }
endclass

class rand_delay;	
	rand int delay;
	function new (int seed);
		this.srandom(seed);		
	endfunction 
	constraint limit { delay inside {[1:1]}; }
endclass

class rand_crop_category;
	rand Crop_cat crop_category;
	function new (int seed);
		this.srandom(seed);		
	endfunction 
	constraint limit { crop_category inside {Potato, Corn, Tomato, Wheat}; }
endclass

class rand_water_amount;
	rand Water_amnt water_amount;
	function new (int seed);
		this.srandom(seed);		
	endfunction 
	constraint limit { water_amount inside {[1:12000]}; }
endclass

// 
rand_gap r_gap = new(SEED) ;
rand_delay r_delay = new(SEED) ;
// 
rand_crop_category r_crop_cat = new(SEED) ;
rand_water_amount r_water_amnt = new(SEED) ;
//================================================================
//  initial
//================================================================
initial begin
	// read in initial DRAM data
	$readmemh(DRAM_p_r, golden_DRAM);
	// initial deposit value
	current_deposit = { golden_DRAM[BASE_deposit+0], golden_DRAM[BASE_deposit+1], golden_DRAM[BASE_deposit+2], golden_DRAM[BASE_deposit+3] };
	// $display("initial deposit = %h", current_deposit);
	// reset output signals
	inf.rst_n = 1'b1 ;
	inf.id_valid = 1'b0 ;
	inf.act_valid = 1'b0 ;
	inf.cat_valid = 1'b0 ;
	inf.amnt_valid = 1'b0 ;
	inf.D = 'bx;
	// reset
	total_cycles = 0 ;
	cnt_Is_Empty  = 0 ;
	cnt_Not_Empty = 0 ;
	cnt_Has_Grown = 0 ;
	cnt_Not_Grown = 0 ;
	reset_task;
	// 
	@(negedge clk);
	patcount = 0 ;
	base_water_amnt = 0 ;
	act_water_cnt = 0 ;

	golden_id = 0 ;
	has_given_id = 0 ;
	for( k=0 ; k<90 ; k+=1 ) begin
		     if (patcount%9== 0)	golden_act = Seed ;
		else if (patcount%9== 1)	golden_act = Check_dep ;
		else if (patcount%9== 2)	golden_act = Water ;
		else if (patcount%9== 3)	golden_act = Check_dep ;
		else if (patcount%9== 4)	golden_act = Reap ;
		else if (patcount%9== 5)	golden_act = Check_dep ;
		else if (patcount%9== 6)	golden_act = Steal ;
		else if (patcount%9== 7)	golden_act = Check_dep ;
		else if (patcount%9== 8)	golden_act = Check_dep ;
		// 
		case(golden_act)
			Seed: begin
				// $display("Seed");
				if(current_deposit<=20) begin// no money   
					golden_act = Reap ;
					reap_task;
				end
				seed_task;
			end
			Water: begin
				// $display("Water");
				water_task;
			end
			Reap: begin
				// $display("Reap");
				reap_task;
			end
			Steal: begin
				// $display("Steal");
				steal_task;
			end
			Check_dep: begin
				// $display("Check_dep");
				check_dep_task;
			end
		endcase
		// for checking outputs
		get_land_info_task;
		// $display("after  : %h", golden_land_info);
		wait_outvalid_task;
		output_task;
		// 
		gap_task;
		// 
	    ++patcount;
	    // $display("PASS PATTERN NO.%4d\n", patcount );
	    // 
	    if (golden_complete==1'b0) begin
	    	case(golden_err_msg)
	    		Is_Empty:	err_cnt = ++cnt_Is_Empty ;
	    		Not_Empty:	err_cnt = ++cnt_Not_Empty ;
	    		Has_Grown: 	err_cnt = ++cnt_Has_Grown ;
	    		Not_Grown:	err_cnt = ++cnt_Not_Grown ;
	    	endcase
	    end
	    // 
	    if (has_given_id==1) begin
			golden_id += 1 ;
			has_given_id = 0 ;
		end
	end

	pre_id = golden_id ;
	flag = 0 ;

	for( k=0 ; k<10 ; k+=1 ) begin
		for( golden_id=0 ; golden_id<255 ; golden_id+=1 ) begin
			has_given_id = 0 ;
			// 
			if (flag==0) begin
			 	golden_id = pre_id ;
			 	flag = 1 ;
			end
			// 
			temp = patcount - 90 ;
			     if (temp%28== 0)	golden_act = Seed ;		//
			else if (temp%28== 1)	golden_act = Seed ;
			else if (temp%28== 2)	golden_act = Water ;
			else if (temp%28== 3)	golden_act = Seed ;
			else if (temp%28== 4)	golden_act = Reap ;
			else if (temp%28== 5)	golden_act = Seed ;
			else if (temp%28== 6)	golden_act = Steal ;
			else if (temp%28== 7)	golden_act = Water ;	//
			else if (temp%28== 8)	golden_act = Seed ;
			else if (temp%28== 9)	golden_act = Water ;
			else if (temp%28==10)	golden_act = Water ;
			else if (temp%28==11)	golden_act = Reap ;
			else if (temp%28==12)	golden_act = Water ;
			else if (temp%28==13)	golden_act = Steal ;
			else if (temp%28==14)	golden_act = Reap ;		//
			else if (temp%28==15)	golden_act = Seed ;
			else if (temp%28==16)	golden_act = Reap ;
			else if (temp%28==17)	golden_act = Water ;
			else if (temp%28==18)	golden_act = Reap ;
			else if (temp%28==19)	golden_act = Reap ;
			else if (temp%28==20)	golden_act = Steal ;
			else if (temp%28==21)	golden_act = Steal ;	//
			else if (temp%28==22)	golden_act = Seed ;
			else if (temp%28==23)	golden_act = Steal ;
			else if (temp%28==24)	golden_act = Water ;
			else if (temp%28==25)	golden_act = Steal ;
			else if (temp%28==26)	golden_act = Reap ;
			else if (temp%28==27)	golden_act = Steal ;
			// 
			case(golden_act)
				Seed: begin
					// $display("Seed");
					if(current_deposit<=20) begin// no money   
						golden_act = Reap ;
						reap_task;
						continue;
					end
					seed_task;
				end
				Water: begin
					// $display("Water");
					water_task;
				end
				Reap: begin
					// $display("Reap");
					reap_task;
				end
				Steal: begin
					// $display("Steal");
					steal_task;
				end
				
			endcase
			// for checking outputs
			get_land_info_task;
			// $display("after  : %h", golden_land_info);
			wait_outvalid_task;
			output_task;
			// 
			gap_task;
			// 
			++patcount;
	        // $display("PASS PATTERN NO.%4d", patcount );
	        // 
	        if (golden_complete==1'b0) begin
	        	case(golden_err_msg)
	        		Is_Empty:	err_cnt = ++cnt_Is_Empty ;
	        		Not_Empty:	err_cnt = ++cnt_Not_Empty ;
	        		Has_Grown: 	err_cnt = ++cnt_Has_Grown ;
	        		Not_Grown:	err_cnt = ++cnt_Not_Grown ;
	        	endcase
	        end
		end
	end
    // $display("cnt_Is_Empty = %d", cnt_Is_Empty);
    // $display("cnt_Not_Empty = %d", cnt_Not_Empty);
    // $display("cnt_Has_Grown = %d", cnt_Has_Grown);
    // $display("cnt_Not_Grown = %d", cnt_Not_Grown);
	// #(1000);
    congratulations;
    $finish;
end
//================================================================
//  output task
//================================================================
task output_task; begin
	// $display("output_task");
	y = 0;
	while (inf.out_valid===1) begin
		if (y >= 1) begin
			/*$display ("--------------------------------------------------");
			$display ("                        FAIL                      ");
			$display ("          Outvalid is more than 1 cycles          ");
			$display ("--------------------------------------------------");
	        #(100);*/
			$finish;
		end
		else if (golden_act==Check_dep) begin
			golden_out_info = 0 ;
			golden_deposit = current_deposit ;
    		if ( (inf.complete!==golden_complete) || (inf.err_msg!==golden_err_msg) || (inf.out_info!==golden_out_info) || (inf.out_deposit!==golden_deposit)) begin
				/*$display("-----------------------------------------------------------");
    	    	$display("                           FAIL 1                 ");
    	    	$display("    Golden complete : %6d    your complete : %6d ", golden_complete, inf.complete);
    			$display("    Golden err_msg  : %6d    your err_msg  : %6d ", golden_err_msg, inf.err_msg);
    			$display("    Golden info     : %8h  your info     : %8h   ", golden_out_info, inf.out_info);
    	    	$display("    Golden deposit  : %8h  your deposit  : %8h   ", current_deposit, inf.out_deposit );
    	    	$display("-----------------------------------------------------------");
		        #(100);*/
    			$finish;
    		end	    
    	end
		else begin	
			if (golden_complete) begin
				golden_deposit = 0 ;
				if ( (golden_act==Reap) || (golden_act==Steal) )
					golden_out_info = temp_land_info ;
				else
					golden_out_info = { golden_land_info.land_id , golden_land_info.land_status , golden_land_info.water_amnt } ;
    			if ( (inf.complete!==golden_complete) || (inf.err_msg!==golden_err_msg) || (inf.out_info!==golden_out_info) || (inf.out_deposit!==golden_deposit)) begin
    			    /*$display("-----------------------------------------------------------");
    	    		$display("                           FAIL 2                 ");
    	    		$display("    Golden complete : %6d    your complete : %6d ", golden_complete, inf.complete);
    				$display("    Golden err_msg  : %6d    your err_msg  : %6d ", golden_err_msg, inf.err_msg);
    				$display("    Golden info     : %8h  your info     : %8h   ", golden_out_info, inf.out_info);
    	    		$display("    Golden deposit  : %8h  your deposit  : %8h   ", golden_deposit, inf.out_deposit );
    	    		$display("-----------------------------------------------------------");
			        #(100);*/
    			    $finish;
    			end
    		end
    		else begin
    			golden_deposit = 0 ;
    			golden_out_info = 0;
    			if ( (inf.complete!==golden_complete) || (inf.err_msg!==golden_err_msg) || (inf.out_info!==golden_out_info) || (inf.out_deposit!==golden_deposit)) begin
    			    /*$display("-----------------------------------------------------------");
    	    		$display("                           FAIL 3                 ");
    	    		$display("    Golden complete : %6d    your complete : %6d ", golden_complete, inf.complete);
    				$display("    Golden err_msg  : %6d    your err_msg  : %6d ", golden_err_msg, inf.err_msg);
    				$display("    Golden info     : %8h  your info     : %8h   ", golden_out_info, inf.out_info);
    	    		$display("    Golden deposit  : %8h  your deposit  : %8h   ", golden_deposit, inf.out_deposit );
    	    		$display("-----------------------------------------------------------");
			        #(100);*/
    			    $finish;
    			end
    		end	
    	end	
		@(negedge clk);
		y = y + 1;
	end
end endtask

task wait_outvalid_task; begin
	cycles = 0 ;
	while (inf.out_valid!==1) begin
		cycles = cycles + 1 ;
		if (cycles==1200) begin
			/*fail;
            // Spec. 8
            // Your latency should be less than 1200 cycle for each operation.
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                SPEC 8 FAIL!                                                                ");
            $display ("                                             The execution latency is limited in 1200 cycles.                                               ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        	#(100);*/
            $finish;
		end
		@(negedge clk);
	end
	total_cycles = total_cycles + cycles ;
end endtask
//================================================================
//  input task
//================================================================
task get_land_info_task; begin
	golden_land_info.land_id 	 = golden_DRAM[BASE_Addr+golden_id*4 + 0] ;
	golden_land_info.land_status = golden_DRAM[BASE_Addr+golden_id*4 + 1] ;
	golden_land_info.crop_cat    = golden_DRAM[BASE_Addr+golden_id*4 + 1][3:0] ;
	golden_land_info.water_amnt  = { golden_DRAM[BASE_Addr+golden_id*4 + 2] , golden_DRAM[BASE_Addr+golden_id*4 + 3] } ;
end endtask

task seed_task; begin
	// id
	if (has_given_id==0) begin
		give_id_task;
		delay_task;
	end
	// 
	r_crop_cat.randomize();		// which crop to seed
	golden_cat  = r_crop_cat.crop_category ;
	r_water_amnt.randomize();	// how much water to water
	golden_amnt = r_water_amnt.water_amount ;
	// for initialization
	get_land_info_task;
	// $display("before : %h", golden_land_info);
	temp_land_info = { golden_land_info.land_id , golden_land_info.land_status , golden_land_info.water_amnt } ;
	// action
	inf.act_valid = 1'b1 ;
	inf.D = golden_act ;
	@(negedge clk);
	inf.act_valid = 1'b0 ;
	inf.D = 'bx ;
	delay_task;
	// category
	inf.cat_valid = 1'b1 ;
	inf.D = golden_cat ;
	@(negedge clk);
	inf.cat_valid = 1'b0 ;
	inf.D = 'bx ;
	delay_task;
	// water
	inf.amnt_valid = 1'b1 ;
	inf.D = golden_amnt ;
	@(negedge clk);
	inf.amnt_valid = 1'b0 ;
	inf.D = 'bx ;
	@(negedge clk);
	// delay_task;
	// golden answers
	if( golden_land_info.land_status[7:4]!=No_sta) begin
		// $display("Error in Seed operation : Land is not empty.");
		golden_complete = 1'b0 ;
		golden_err_msg = Not_Empty ;
	end
	else begin
		golden_complete = 1'b1 ;
		golden_err_msg = No_Err ;
		// deposit
		case(golden_cat)
			Potato: 	current_deposit -= 5 ;
			Corn:		current_deposit -= 10 ;
			Tomato:		current_deposit -= 15 ;
			Wheat:		current_deposit -= 20 ;
		endcase
		{ golden_DRAM[BASE_Addr+golden_id*4 + 2] , golden_DRAM[BASE_Addr+golden_id*4 + 3] } = current_deposit ;
		if (current_deposit<0) begin
			// $display("PATTERN No.%4d error : Player run out of money.", patcount);
    	    repeat(2) @(negedge clk);
			$finish;
		end
		// land info
		case(golden_cat)
			Potato: begin
				if (golden_amnt>=16'h0080)		golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Snd_sta ;
				else if (golden_amnt>=16'h0010)	golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Fst_sta ;
				else							golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Zer_sta ;
			end
			Corn: begin
				if (golden_amnt>=16'h0200)		golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Snd_sta ;
				else if (golden_amnt>=16'h0040)	golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Fst_sta ;
				else							golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Zer_sta ;
			end
			Tomato: begin
				if (golden_amnt>=16'h0800)		golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Snd_sta ;
				else if (golden_amnt>=16'h0100)	golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Fst_sta ;
				else							golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Zer_sta ;
			end
			Wheat: begin
				if (golden_amnt>=16'h2000)		golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Snd_sta ;
				else if (golden_amnt>=16'h0400)	golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Fst_sta ;
				else							golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Zer_sta ;
			end
		endcase
		golden_DRAM[BASE_Addr+golden_id*4 + 1][3:0] = golden_cat ;
		{ golden_DRAM[BASE_Addr+golden_id*4 + 2] , golden_DRAM[BASE_Addr+golden_id*4 + 3] } = golden_amnt ;
	end
end endtask

task water_task; begin
	// id
	if (has_given_id==0) begin
		give_id_task;
		delay_task;
	end
	act_water_cnt = act_water_cnt + 1 ;
	if (act_water_cnt>100) begin
		act_water_cnt = 0 ;
		base_water_amnt = base_water_amnt + 12000 ;
	end
	r_water_amnt.randomize();	// how much water to water
	golden_amnt = base_water_amnt + r_water_amnt.water_amount ;
	// for initialization
	get_land_info_task;
	// $display("before : %h", golden_land_info);
	temp_land_info = { golden_land_info.land_id , golden_land_info.land_status , golden_land_info.water_amnt } ;
	// action
	inf.act_valid = 1'b1 ;
	inf.D = golden_act ;
	@(negedge clk);
	inf.act_valid = 1'b0 ;
	inf.D = 'bx ;
	delay_task;
	// water
	inf.amnt_valid = 1'b1 ;
	inf.D = golden_amnt ;
	@(negedge clk);
	inf.amnt_valid = 1'b0 ;
	inf.D = 'bx ;
	@(negedge clk);
	// delay_task;
	if (golden_land_info.land_status[7:4]==No_sta) begin
		// $display("Error in Water operation : Land is empty.");
		golden_complete = 1'b0 ;
		golden_err_msg = Is_Empty ;
	end
	else if (golden_land_info.land_status[7:4]==Snd_sta) begin
		// $display("Error in Water operation : Crop needs no more water.");
		golden_complete = 1'b0 ;
		golden_err_msg = Has_Grown ;
	end
	else begin
		golden_complete = 1'b1 ;
		golden_err_msg = No_Err ;
		// land info
		{ golden_DRAM[BASE_Addr+golden_id*4 + 2] , golden_DRAM[BASE_Addr+golden_id*4 + 3] } += golden_amnt ;
		golden_amnt = { golden_DRAM[BASE_Addr+golden_id*4 + 2] , golden_DRAM[BASE_Addr+golden_id*4 + 3] } ;
		case(golden_DRAM[BASE_Addr+golden_id*4 + 1][3:0])
			Potato: begin
				if (golden_amnt>=16'h0080)		golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Snd_sta ;
				else if (golden_amnt>=16'h0010)	golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Fst_sta ;
				else							golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Zer_sta ;
			end
			Corn: begin
				if (golden_amnt>=16'h0200)		golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Snd_sta ;
				else if (golden_amnt>=16'h0040)	golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Fst_sta ;
				else							golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Zer_sta ;
			end
			Tomato: begin
				if (golden_amnt>=16'h0800)		golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Snd_sta ;
				else if (golden_amnt>=16'h0100)	golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Fst_sta ;
				else							golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Zer_sta ;
			end
			Wheat: begin
				if (golden_amnt>=16'h2000)		golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Snd_sta ;
				else if (golden_amnt>=16'h0400)	golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Fst_sta ;
				else							golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = Zer_sta ;
			end
		endcase
	end
end endtask

task reap_task; begin
	// id
	if (has_given_id==0) begin
		give_id_task;
		delay_task;
	end	
	// for initialization
		get_land_info_task;
		// $display("before : %h", golden_land_info);
		temp_land_info = { golden_land_info.land_id , golden_land_info.land_status , golden_land_info.water_amnt } ;
	// action
	inf.act_valid = 1'b1 ;
	inf.D = golden_act ;
	@(negedge clk);
	inf.act_valid = 1'b0 ;
	inf.D = 'bx ;
	// delay_task;
	if (golden_land_info.land_status[7:4]==No_sta) begin
		// $display("Error in Reap operation : Land is empty.");
		golden_complete = 1'b0 ;
		golden_err_msg = Is_Empty ;
	end
	else if (golden_land_info.land_status[7:4]==Zer_sta) begin
		// $display("Error in Reap operation : Crop hasn't grown up.");
		golden_complete = 1'b0 ;
		golden_err_msg = Not_Grown ;
	end
	else begin
		golden_complete = 1'b1 ;
		golden_err_msg = No_Err ;
		// deposit
		case(golden_land_info.land_status[3:0])
			Potato: 	current_deposit += (golden_land_info.land_status[7:4]==Fst_sta) ? 10 : 25 ;
			Corn:		current_deposit += (golden_land_info.land_status[7:4]==Fst_sta) ? 20 : 50 ;
			Tomato:		current_deposit += (golden_land_info.land_status[7:4]==Fst_sta) ? 30 : 75 ;
			Wheat:		current_deposit += (golden_land_info.land_status[7:4]==Fst_sta) ? 40 : 100 ;
		endcase
		{ golden_DRAM[BASE_Addr+golden_id*4 + 2] , golden_DRAM[BASE_Addr+golden_id*4 + 3] } = current_deposit ;
		// land info
		golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = No_sta ;
		golden_DRAM[BASE_Addr+golden_id*4 + 1][3:0] = No_cat ;
		{ golden_DRAM[BASE_Addr+golden_id*4 + 2] , golden_DRAM[BASE_Addr+golden_id*4 + 3] } = 0 ;
	end
end endtask

task steal_task; begin
	// id
	if (has_given_id==0) begin
		give_id_task;
		delay_task;
		has_given_id = 1 ;
	end	
	// for initialization
		get_land_info_task;
		// $display("before : %h", golden_land_info);
		temp_land_info = { golden_land_info.land_id , golden_land_info.land_status , golden_land_info.water_amnt } ;
	// action
	inf.act_valid = 1'b1 ;
	inf.D = golden_act ;
	@(negedge clk);
	inf.act_valid = 1'b0 ;
	inf.D = 'bx ;
	// delay_task;
	if (golden_land_info.land_status[7:4]==No_sta) begin
		// $display("Error in Steal operation : Land is empty.");
		golden_complete = 1'b0 ;
		golden_err_msg = Is_Empty ;
	end
	else if (golden_land_info.land_status[7:4]==Zer_sta) begin
		// $display("Error in Steal operation : Crop hasn't grown up.");
		golden_complete = 1'b0 ;
		golden_err_msg = Not_Grown ;
	end
	else begin
		golden_complete = 1'b1 ;
		golden_err_msg = No_Err ;
		// land info
		golden_DRAM[BASE_Addr+golden_id*4 + 1][7:4] = No_sta ;
		golden_DRAM[BASE_Addr+golden_id*4 + 1][3:0] = No_cat ;
		{ golden_DRAM[BASE_Addr+golden_id*4 + 2] , golden_DRAM[BASE_Addr+golden_id*4 + 3] } = 0 ;
	end
end endtask

task check_dep_task; begin
	golden_complete = 1'b1 ;
	golden_err_msg = No_Err ;
	// action
	inf.act_valid = 1'b1 ;
	inf.D = golden_act ;
	@(negedge clk);
	inf.act_valid = 1'b0 ;
	inf.D = 'bx ;
end endtask

task give_id_task; begin
	inf.id_valid = 1'b1 ;
	inf.D = { 8'd0 , golden_id } ;
	@(negedge clk);
	inf.id_valid = 1'b0 ;
	inf.D = 'bx ;
	has_given_id = 1 ;
end endtask
//================================================================
//  env task
//================================================================
task reset_task ; begin
	#(2.0);	inf.rst_n = 0 ;
	#(3.0);
	if (inf.out_valid!==0 || inf.err_msg!==0 || inf.complete!==0 || inf.out_info!==0 || inf.out_deposit!==0) begin
		/*fail;
        // Spec. 3
        // Using  asynchronous  reset  active  low  architecture. All  outputs  should  be zero after reset. 
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                SPEC 3 FAIL!                                                                ");
        $display ("                                   All output signals should be reset after the reset signal is asserted.                                   ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        #(100);*/
        $finish;
	end
	#(2.0);	inf.rst_n = 1 ;
end endtask

task delay_task ; begin
	r_delay.randomize();
	for( i=0 ; i<r_delay.delay ; i++ )	@(negedge clk);
end endtask

task gap_task ; begin
	r_gap.randomize();
	for( i=0 ; i<r_gap.gap ; i++ )	@(negedge clk);
end endtask
//================================================================
//  pass/fail task
//================================================================
task congratulations; begin
    $display("********************************************************************");
    $display("                        \033[0;38;5;219mCongratulations!\033[m      ");
    $display("                 \033[0;38;5;219mYou have passed all patterns!\033[m");
    $display("                 \033[0;38;5;219mTotal time: %d \033[m",$time);
    $display("********************************************************************");
	repeat(2) @(negedge clk);
    $finish;
end
endtask
/*
task fail; begin
$display(":( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( ");
end endtask
*/
endprogram