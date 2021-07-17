//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Lab06			: Series Processing (SP)
//   Author         : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
`define CYCLE_TIME 8

module PATTERN(
	// Output signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	in_data,
	in_mode,
	// Input signals
	out_valid,
	out_data
);
// ================================================================
//    INPUT AND OUTPUT DECLARATION
// ================================================================
output reg clk;
output reg rst_n;
output reg cg_en;
output reg in_valid;
output reg [8:0] in_data;
output reg [2:0] in_mode;
input out_valid;
input [8:0] out_data;
//================================================================
//  integer
//================================================================
integer a, i, cycles, total_cycles, in_file, out_file, debug_file, gap;
integer PATNUM, patcount;
integer color_stage = 0, color, r = 5, g = 0, b = 0 ;
//================================================================
//  wire & registers 
//================================================================
reg [8:0] golden_out_data;
reg [8:0] g_a[0:5], g_b[0:5], g_c[0:5], g_d[0:5], g_e[0:5];
//================================================================
//  clock
//================================================================
always  #(`CYCLE_TIME/2.0)  clk = ~clk ;
initial clk = 0 ;
//================================================================
//  initial
//================================================================
initial begin
	in_file = $fopen("../00_TESTBED/in.txt", "r");
	out_file = $fopen("../00_TESTBED/out.txt", "r");
	debug_file = $fopen("../00_TESTBED/debug.txt", "r");
	a = $fscanf(in_file, "%d\n", PATNUM);
	// reset output signals
	rst_n = 1 ;
	in_valid = 0 ;
	in_data = 9'bx ;
	in_mode = 3'bx ;
	cg_en = 1 ;
	// reset
	force clk = 0 ;
	total_cycles = 0 ;
	reset_task;
	// 
	@(negedge clk);
	for( patcount=0 ; patcount<PATNUM ; patcount=patcount+1 ) begin
		input_task;
		wait_outvalid_task;
		output_task;
		delay_task;
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
task output_task ; begin
	if (out_valid===1) begin
		for( i=0 ; i<6 ; i=i+1 ) begin
			a = $fscanf(out_file, "%d\n", golden_out_data);
			if (golden_out_data!==out_data) begin
				fail;
				// Spec
				// The result should be correct when out_valid is high
           		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
           		$display ("                                                                SPEC FAIL!                                                                  ");
           		$display ("                                                  golden_result = %d , your result = %d                                                     ", golden_out_data, out_data);
           		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
           		repeat(5)  @(negedge clk);
           		$finish;
			end
			@(negedge clk);
		end
	end
	else begin
		fail;
		// Spec
		// Unexpected out_valid value
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                SPEC FAIL!                                                                  ");
        $display ("                                                        Unexpected out_valid value                                                          ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        repeat(5)  @(negedge clk);
        $finish;
	end
end endtask

task wait_outvalid_task ; begin
	cycles = 0 ;
	while( out_valid!==1 ) begin
		cycles = cycles + 1 ;
		if (cycles==2000) begin
			fail;
            // Spec. 13
            // Your latency should be less than 2000 cycles. Otherwise you will fail this exercise.
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                SPEC 7 FAIL!                                                                ");
            $display ("                                             The execution latency is limited in 2000 cycles.                                               ");
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
task input_task ; begin
	// debug
	for( i=0 ; i<6 ; i=i+1 )	a = $fscanf(debug_file, "%d\n", g_a[i]);
	for( i=0 ; i<6 ; i=i+1 )	a = $fscanf(debug_file, "%d\n", g_b[i]);
	for( i=0 ; i<6 ; i=i+1 )	a = $fscanf(debug_file, "%d\n", g_c[i]);
	for( i=0 ; i<6 ; i=i+1 )	a = $fscanf(debug_file, "%d\n", g_d[i]);
	for( i=0 ; i<6 ; i=i+1 )	a = $fscanf(debug_file, "%d\n", g_e[i]);
	// 
	in_valid = 1 ;
	a = $fscanf(in_file, "%b\n", in_mode);
	a = $fscanf(in_file, "%d\n", in_data);
	for( i=1 ; i<6 ; i=i+1 ) begin
		if (out_valid!==0) begin
			fail;
        	// Spec. 15
        	// in_valid and out_valid should not be high at the same time.   
        	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        	$display ("                                                               SPEC 15 FAIL!                                                                ");
        	$display ("                                          out_valid should not be raised when in_valid is high.                                             ");
        	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        	repeat(5)  @(negedge clk);
        	$finish;
        end
        if (out_data!==0) begin
			fail;
        	// Spec. 16
        	// Out_data should be 0 when out_valid is low.
        	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        	$display ("                                                               SPEC 16 FAIL!                                                                ");
        	$display ("                                                 Out_data should be 0 when out_valid is low.                                                ");
        	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        	repeat(5)  @(negedge clk);
        	$finish;
        end
        @(negedge clk);
        in_mode = 3'bx ;
        a = $fscanf(in_file, "%d\n", in_data);
	end
	@(negedge clk);
	in_valid = 0 ;
	in_data = 9'bx ;
end endtask
//================================================================
//  env task
//================================================================
task reset_task ; begin
	#(1.0);	rst_n = 0 ;
	#(3.0);
	if (out_valid!==0 || out_data!==0) begin
		fail;
        // Spec. 4
        // All your output register should be set zero after reset. 
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                SPEC 4 FAIL!                                                                ");
        $display ("                                   All output signals should be reset after the reset signal is asserted.                                   ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        #(100);
        $finish;
	end
	#(1.0);	rst_n = 1 ;
	#(3.0);	release clk;
end endtask

task delay_task ; begin
    gap = $urandom_range(1, 3) ;
    repeat(gap) @(negedge clk);
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
