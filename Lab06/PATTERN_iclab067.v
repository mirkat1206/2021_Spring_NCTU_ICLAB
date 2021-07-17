//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Lab06			: CheckSum (CS)
//   Author         : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifdef RTL
    `define CYCLE_TIME 12.0
`endif

`ifdef GATE
    `define CYCLE_TIME 4.0
`endif

module PATTERN
#(parameter WIDTH_DATA_1 = 384, parameter WIDTH_RESULT_1 = 8,
parameter WIDTH_DATA_2 = 128, parameter WIDTH_RESULT_2 = 8)
(
    //  Output signals
    data,
    in_valid, clk, rst_n,
    //  Input signals
    result,
    out_valid
);
// ================================================================
//    INPUT AND OUTPUT DECLARATION
// ================================================================
output reg[(WIDTH_DATA_1 + WIDTH_DATA_2 - 1):0] data;
output reg in_valid, clk, rst_n;
input [(WIDTH_RESULT_1 + WIDTH_RESULT_2 - 1):0] result;
input out_valid;
//================================================================
//  integer
//================================================================
integer a, i, cycles, total_cycles, pat_file, gap;
integer PATNUM, patcount;
integer color_stage = 0, color, r = 5, g = 0, b = 0 ;
//================================================================
//  wire & registers 
//================================================================
reg [(WIDTH_RESULT_1 + WIDTH_RESULT_2 - 1):0] golden_result;
//================================================================
//  clock
//================================================================
always  #(`CYCLE_TIME/2.0)  clk = ~clk ;
initial clk = 0 ;
//================================================================
//  initial
//================================================================
initial begin
	pat_file = $fopen("../00_TESTBED/Design_pat.txt", "r");
	a = $fscanf(pat_file, "%d\n", PATNUM);
	// reset output signals
	rst_n = 1 ;
	data = 0 ;
	in_valid = 0 ;
	// reset
	force clk = 0 ;
	total_cycles = 0 ;
	reset_task;
	// 
	@(negedge clk);
	for( patcount=0 ; patcount<PATNUM ; patcount=patcount+1 ) begin
		input_task;
		wait_outvalid_task;
		check_result_task;
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
task check_result_task ; begin
	if (out_valid===1) begin
		a = $fscanf(pat_file, "%b\n", golden_result);
		if (golden_result!==result) begin
			fail;
			// Spec
			// The result should be correct when out_valid is high
           	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
           	$display ("                                                                SPEC FAIL!                                                                  ");
           	$display ("                                                  golden_result = %b , your result = %b                                                     ", golden_result, result);
           	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
           	repeat(5)  @(negedge clk);
           	$finish;
		end
		@(negedge clk);
	end
	if (out_valid===1) begin
		fail;
        // Spec. ?
        // out_valid should be only for one cycle
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                SPEC ? FAIL!                                                                ");
        $display ("                                                   out_valid should be only for one cycle.                                                  ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        repeat(5)  @(negedge clk);
        $finish;
	end
end endtask

task wait_outvalid_task ; begin
	cycles = 0 ;
	while( out_valid!==1 ) begin
		cycles = cycles + 1 ;
		if (cycles==100) begin
			fail;
            // Spec. 7
            // The clock period is within 20ns, finish the operation within 10  cycles, 
            // so out_valid should be high within 100 cycles after in_valid pulls to low. 
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                SPEC 7 FAIL!                                                                ");
            $display ("                                             The execution latency is limited in 100 cycles.                                                ");
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
	in_valid = 1 ;
	a = $fscanf(pat_file, "%b\n", data);
	if (out_valid===1) begin
		fail;
        // Spec. 04
        // out_valid should not be raised when in_valid is high.   
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                               SPEC 04 FAIL!                                                                ");
        $display ("                                          out_valid should not be raised when in_valid is high.                                             ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        repeat(5)  @(negedge clk);
        $finish;
	end
	@(negedge clk);
	in_valid = 0 ;
	data = 0 ;
end endtask
//================================================================
//  env task
//================================================================
task reset_task ; begin
	#(1.0);	rst_n = 0 ;
	#(5.0);
	if ((out_valid!==0)||(result!==0)) begin
		fail;
        // Spec. 5
        // The reset signal (rst_n) would be given only once at the beginning of simulation. 
        // All output signals should be reset after the reset signal is asserted. 
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                SPEC 5 FAIL!                                                                ");
        $display ("                                   All output signals should be reset after the reset signal is asserted.                                   ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        #(100);
        $finish;
    end
    #(1.0);	rst_n = 1 ;
    #(2.0);	release clk;
end endtask

task delay_task ; begin
    // Spec. 14
	// The next input will come in 1~3 cycles after your out_valid is pulled down. 
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
