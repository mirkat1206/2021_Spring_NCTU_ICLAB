//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Lab04			: Artificial Neural Network (NN)
//   Author         : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifdef RTL
	`timescale 1ns/10ps
	`include "NN.v"  
	`define CYCLE_TIME 8.0
`endif
`ifdef GATE
	`timescale 1ns/10ps
	`include "NN_SYN.v"
	`define CYCLE_TIME 8.0
`endif

module PATTERN(
	// Output signals
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
	// Input signals
	out_valid,
	out
);
//================================================================
//  parameters
//================================================================
parameter inst_sig_width = 23 ;
parameter inst_exp_width = 8 ;
parameter inst_ieee_compliance = 0 ;
parameter inst_arch = 2 ;
//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output reg clk, rst_n, in_valid_d, in_valid_t, in_valid_w1, in_valid_w2;
output reg [inst_sig_width+inst_exp_width:0] data_point, target;
output reg [inst_sig_width+inst_exp_width:0] weight1, weight2;
input out_valid;
input [inst_sig_width+inst_exp_width:0] out;
//================================================================
//  integer
//================================================================
// 
integer a, i, cycles, epoch, iter, pat_file;
integer PATNUM, patcount;
integer total_cycles;
integer color_stage = 0, color, r = 5, g = 0, b = 0;
// 
integer k;
real aa, out_real, golden_out_real, difference;
real out_sign, golden_out_sign, out_exponent, golden_out_exponent, out_fraction, golden_out_fraction;
//================================================================
//  wire & registers 
//================================================================
reg [inst_sig_width+inst_exp_width:0] w1_r[0:11], w2_r[0:2];
reg [inst_sig_width+inst_exp_width:0] d_r[0:3], t_r;
reg [inst_sig_width+inst_exp_width:0] golden_out;
//================================================================
//  clock
//================================================================
always  #(`CYCLE_TIME/2.0)  clk = ~clk ;
initial clk = 0 ;
//================================================================
//  initial
//================================================================
initial begin
	pat_file = $fopen("../00_TESTBED/pat.txt", "r");
	a = $fscanf(pat_file, "%d\n", PATNUM);
	// reset output signals
	rst_n = 1 ;
	in_valid_d = 0 ;
	in_valid_t = 0 ;
	in_valid_w1 = 0 ;
	in_valid_w2 = 0 ;
	data_point = 32'bx ;
	target = 32'bx ;
	weight1 = 32'bx ;
	weight2 = 32'bx ;
	// rest
	force clk = 0 ;
	total_cycles = 0 ;
	reset_task;
	//
	@(negedge clk);
	for( patcount=0 ; patcount<PATNUM ; patcount=patcount+1 ) begin
		$display("weight_task");
		weight_task;
		repeat(2) 	@(negedge clk);
		for( epoch=0 ; epoch<25 ; epoch=epoch+1 ) begin
			for( iter=0 ; iter<100 ; iter=iter+1 ) begin			
				// $display("data_target_task");
				data_target_task;
				// $display("wait_outvalid_task");
				wait_outvalid_task;
				// $display("check_out_task");
				check_out_task;
				// $display("pass iter %d", iter+1 );
				repeat(1) 	@(negedge clk);
			end
			// 
			$display("PASS EPOCH NO.%4d", epoch+1 );
		end
		// 
		case(color_stage)
            0: begin
                r = r - 1;
                g = g + 1;
                if(r == 0) color_stage = 1;
            end
            1: begin
                g = g - 1;
                b = b + 1;
                if(g == 0) color_stage = 2;
            end
            2: begin
                b = b - 1;
                r = r + 1;
                if(b == 0) color_stage = 0;
            end
        endcase
        color = 16 + r*36 + g*6 + b;
        if(color < 100) $display("\033[38;5;%2dmPASS PATTERN NO.%4d\033[00m", color, patcount+1);
        else $display("\033[38;5;%3dmPASS PATTERN NO.%4d\033[00m", color, patcount+1);
	end
	#(1000);
	YOU_PASS_task;
	$finish;
end
//================================================================
//  output task
//================================================================
// reg [inst_sig_width+inst_exp_width:0] golden_out;
task check_out_task ; begin
	if (out_valid===1) begin
		a = $fscanf(pat_file, "%b\n", golden_out);
		//*****************
		//convert out and golden_out to real number//
  		if (out[31]==1)	out_sign = -1 ;
  		else 			out_sign = 1 ;

  		if (golden_out[31]==1) 	golden_out_sign = -1 ;
  		else 					golden_out_sign = 1 ;
  
  		out_exponent = -127 ;
  		aa = 1 ;
  		for( k=23 ; k<31 ; k=k+1 ) begin
   			if(out[k]==1)	out_exponent = out_exponent + aa ;
   			aa = aa * 2 ;
  		end
 
  		golden_out_exponent = -127 ;
  		aa = 1 ;
  		for( k=23 ; k<31 ; k=k+1 ) begin
   			if (golden_out[k]==1) 	golden_out_exponent = golden_out_exponent + aa ;
   			aa = aa * 2 ;
  		end
  
  		out_fraction = 1 ;
  		aa = 0.5 ;
  		for( k=22 ; k>=0 ; k=k-1 ) begin
  			if (out[k]==1) 	out_fraction = out_fraction + aa ;
  		 	aa = aa / 2 ;
  		end
  
  		golden_out_fraction = 1 ;
  		aa = 0.5 ;
  		for( k=22 ; k>=0 ; k=k-1 ) begin
  		 	if (golden_out[k]==1) 	golden_out_fraction = golden_out_fraction + aa ;
  		 	aa = aa / 2 ;
  		end
  
  		out_real = out_sign * out_fraction * (2**out_exponent) ;
  		golden_out_real = golden_out_sign * golden_out_fraction * (2**golden_out_exponent) ;
  
  		//compute difference
  		difference = golden_out_real - out_real ;
  		if (difference<0) difference = -difference ;

  		// 
  		// $display("difference = %f", difference);
		//*****************
		
		if ( difference>0.0001 ) begin
			fail;
			// Spec. 7
			// allow the error under 0.0001
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                SPEC 7 FAIL!                                                                ");
            $display ("                                                     golden_out = %b , your out = %b                                                        ", golden_out, out);
            $display ("                                                     golden_out - your out = %b                                                        ", golden_out, out);
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            repeat(5)  @(negedge clk);
            $finish;
		end
		@(negedge clk);
	end
	// Spec. 4
	// The out should be reset after your out_valid is pulled down. 
	if (out!==0) begin
		fail;
        // Spec. 4
        // The out should be reset after your out_valid is pulled down. 
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                SPEC 4 FAIL!                                                                ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        repeat(5)  @(negedge clk);
        $finish;
	end
	// Spec. 5
	// The out_valid is limited to high only one cycle when you want to output the result. 
	if (out_valid===1) begin
		fail;
		// Spec. 7
		// allow the error under 0.0001
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                SPEC 5 FAIL!                                                                ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        repeat(5)  @(negedge clk);
        $finish;
	end
end endtask

task wait_outvalid_task ; begin
	cycles = 0 ;
	while( out_valid!==1 ) begin
		cycles = cycles + 1 ;
		if (out!==0) begin
			fail;
            // Spec. 4
            // The out should be reset after your out_valid is pulled down. 
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                SPEC 4 FAIL!                                                                ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            repeat(5)  @(negedge clk);
            $finish;
		end
		if (cycles==300) begin
			fail;
            // Spec. 6
            // The  execution  latency  is  limited  in  300  cycles.  
            // The  latency  is  the  clock  cycles  between  the falling edge of the last in_valid_d and the rising edge of the first out_valid. 
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                SPEC 6 FAIL!                                                                ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            repeat(5)  @(negedge clk);
            $finish;
		end
		@(negedge clk);
	end
	total_cycles = total_cycles + cycles ;
end endtask
//================================================================
//  input task
//================================================================
// reg [inst_sig_width+inst_exp_width:0] w1_r[0:11], w2_r[0:2];
task weight_task ; begin
	// w1_r
	for( i=0 ; i<12 ; i=i+1 )
		a = $fscanf(pat_file, "%b\n", w1_r[i]);
	// w2_r
	for( i=0 ; i<3 ; i=i+1 )
		a = $fscanf(pat_file, "%b\n", w2_r[i]);
	// 
	in_valid_w1 = 1 ;
	in_valid_w2 = 1 ;
	for( i=0 ; i<12 ; i=i+1 ) begin
		// weight2
		if (i<3)	weight2 = w2_r[i] ;
		else begin
			weight2 = 32'bx ;
			in_valid_w2 = 0 ;
		end
		// weight1
		weight1 = w1_r[i] ;
		//
		@(negedge clk);
	end
	weight1 = 32'bx ;
	in_valid_w1 = 0 ;
end endtask
// reg [inst_sig_width+inst_exp_width:0] d_r[0:3], t_r;
task data_target_task ; begin
	// d_r
	for( i=0 ; i<4 ; i=i+1 ) 
		a = $fscanf(pat_file, "%b\n", d_r[i]);
	// t_r
	a = $fscanf(pat_file, "%b\n", t_r);
	// 
	in_valid_d = 1 ;
	in_valid_t = 1 ;
	for( i=0 ; i<4 ; i=i+1 ) begin
		// target
		if (i<1)	target = t_r ;
		else begin
			target = 32'bx ;
			in_valid_t = 0 ;
		end
		// data_point
		data_point = d_r[i] ;
		// 
		@(negedge clk);
	end
	data_point = 32'bx ;
	in_valid_d = 0 ;
end endtask
//================================================================
//  env task
//================================================================
task reset_task ; begin
	#(1.0);	rst_n = 0 ;
	#(2.0);
	if ((out_valid!==0)||(out!==0)) begin
		fail;
        // Spec. 3
        // The reset signal (rst_n) would be given only once at the beginning of simulation. 
        // All output signals should be reset after the reset signal is asserted. 
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                SPEC 3 FAIL!                                                                ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        #(100);
        $finish;
    end
    #(1.0);	rst_n = 1 ;
    #(2.0);	release clk;
end endtask
//================================================================
//  pass/fail task
//================================================================
task YOU_PASS_task;begin
$display ("----------------------------------------------------------------------------------------------------------------------");
$display ("                                                  Congratulations!                                                    ");
$display ("                                           You have passed all patterns!                                              ");
$display ("                                                                                                                      ");
$display ("                                        Your execution cycles   = %5d cycles                                          ", total_cycles);
$display ("                                        Your clock period       = %.1f ns                                             ", `CYCLE_TIME);
$display ("                                        Total latency           = %.1f ns                                             ", total_cycles*`CYCLE_TIME );
$display ("----------------------------------------------------------------------------------------------------------------------");
$finish;    
end endtask

task fail; begin
$display(":( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( ");
end endtask

endmodule
