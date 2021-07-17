//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Lab05			: Matrix Computation (MC)
//   Author         : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifdef RTL
`define CYCLE_TIME 4.0
`endif
`ifdef GATE
`define CYCLE_TIME 12.0
`endif

module PATTERN(
        // input signals
		clk,
		rst_n,
		in_valid,
		in_data,
		size,
		action,
        // output signals
		out_valid,
		out_data
);
//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output reg clk, rst_n, in_valid;
output reg [30:0] in_data;
output reg [1:0] size;
output reg [2:0] action;
input out_valid;
input [30:0] out_data;
//================================================================
//  integer
//================================================================
integer a, i, j, cycles, total_cycles, pat_file, gap;
integer PATNUM, patcount, OP_NUM, op_count;
integer matrix_size, opcode;
integer color_stage = 0, color, r = 5, g = 0, b = 0;
//================================================================
//  wire & registers 
//================================================================
reg [30:0] golden_out_data;
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
	a = $fscanf(pat_file, "%d\n", OP_NUM);
	// reset output signals
	rst_n = 1 ;
	in_valid = 0 ;
	in_data = 31'bx ;
	size = 2'bx ;
	action = 3'bx ;
	// reset 
	force clk = 0 ;
	total_cycles = 0 ;
	reset_task;
	// 
	@(negedge clk);
	for( patcount=0 ; patcount<PATNUM ; patcount=patcount+1 ) begin
		setup_task;
		wait_outvalid_task;
		check_out_task;
		delay_task;
		for( op_count=0 ; op_count<OP_NUM ; op_count=op_count+1 ) begin
            $display("%4d", op_count);
			operation_task;
			wait_outvalid_task;
			check_out_task;
			delay_task;
		end
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
task check_out_task ; begin
	if (out_valid===1) begin
		// 0: setup, 1: addition(41%), 2: multiplication(41%), 3: transpose(6%), 4: mirror(6%), 5: rotate counter clockwise(6%)	
		if (opcode<3) begin
			for( i=0 ; i<matrix_size*matrix_size ; i=i+1 ) begin
				if (out_valid===0) begin
					fail;
					// The output signal out_data must be delivered for current size of matrix cycles continuously, and out_valid should be high simultaneously.
            		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            		$display ("                                                                    FAIL!                                                                   ");
            		$display ("                                  out_data must be delivered for current size of matrix cycles continuously                                 ");
            		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            		repeat(5)  @(negedge clk);
            		$finish;
				end
				
				a = $fscanf(pat_file, "%d\n", golden_out_data);
				if (golden_out_data!==out_data) begin
					fail;
					// Spec. 13
					// The out_data should be correct when out_valid is high
            		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            		$display ("                                                                SPEC 13 FAIL!                                                               ");
            		$display ("                                                golden_out_data = %d , your out_data = %d                                                   ", golden_out_data, out_data);
            		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            		repeat(5)  @(negedge clk);
            		$finish;
				end
				@(negedge clk);
			end
			if (out_valid===1) begin
				fail;
				// Too much out_valid
            	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            	$display ("                                                                    FAIL!                                                                   ");
            	$display ("                                                             Too much out_valid                                                             ");
            	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            	repeat(5)  @(negedge clk);
            	$finish;
			end
		end
		else begin
			a = $fscanf(pat_file, "%d\n", golden_out_data);
			if (golden_out_data!==out_data) begin
				fail;
				// Spec. 13
				// The out_data should be correct when out_valid is high
            	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            	$display ("                                                                SPEC 13 FAIL!                                                               ");
            	$display ("                                                golden_out_data = %d , your out_data = %d                                                   ", golden_out_data, out_data);
            	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            	repeat(5)  @(negedge clk);
            	$finish;
			end
			@(negedge clk);
			if (out_valid===1) begin
				fail;
				// If operation is Transpose, Mirror, or Rotate counterclockwise, out_valid last for 1 cycle and out_data must be zero.
            	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            	$display ("                                                                    FAIL!                                                                   ");
            	$display ("            If operation is Transpose, Mirror, or Rotate counterclockwise, out_valid last for 1 cycle and out_data must be zero.            ");
            	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            	repeat(5)  @(negedge clk);
            	$finish;
			end
		end
		golden_out_data = 31'bx ;
	end
end endtask

task wait_outvalid_task ; begin
	cycles = 0 ;
	while( out_valid!==1 ) begin
		cycles = cycles + 1 ;
		if (cycles==25000) begin
			fail;
            // Spec. 9
            // The execution latency is limited in 25000 cycles. The latency is the clock cycles between the falling edge of the in_valid and the rising edge of the out_valid. 
            // The definition of latency can  be view from the sample waveform, and the minimum latency is 0. 
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                SPEC 9 FAIL!                                                                ");
            $display ("                                             The execution latency is limited in 25000 cycles.                                              ");
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
task setup_task ; begin
	in_valid = 1'b1 ;
	a = $fscanf(pat_file, "%d\n", action);
	a = $fscanf(pat_file, "%d\n", size);
	a = $fscanf(pat_file, "%d\n", in_data);
	opcode = action ;
	// MATRIX_SIZE = [2, 4, 8, 16]     # possible size of a matrix : 2x2, 4x4, 8x8, 16x16
	if (size==0)		matrix_size = 2 ;
	else if (size==1)	matrix_size = 4 ;
	else if (size==2)	matrix_size = 8 ;
	else 				matrix_size = 16 ;
	
	if ((out_valid!==0)) begin
		fail;
        // Spec. 8
        // The out_valid cannot overlap with in_valid. 
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                SPEC 8 FAIL!                                                                ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        #(100);
        $finish;
    end

	@(negedge clk);
	size = 2'bx ;
	action = 3'bx ;
	for( i=1 ; i<matrix_size*matrix_size ; i=i+1 ) begin
		a = $fscanf(pat_file, "%d\n", in_data);

		if ((out_valid!==0)) begin
			fail;
        	// Spec. 8
        	// The out_valid cannot overlap with in_valid. 
        	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        	$display ("                                                                SPEC 8 FAIL!                                                                ");
        	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        	#(100);
        	$finish;
    	end

		@(negedge clk);
	end
	in_valid = 0 ;
	in_data = 31'bx ;
end endtask

task operation_task ; begin
	// 0: setup, 1: addition(41%), 2: multiplication(41%), 3: transpose(6%), 4: mirror(6%), 5: rotate counter clockwise(6%)	
	a = $fscanf(pat_file, "%d\n", opcode);
	in_valid = 1'b1 ;
	action = opcode ;
	if (opcode<3) begin
		a = $fscanf(pat_file, "%d\n", in_data);

		if ((out_valid!==0)) begin
			fail;
        	// Spec. 8
        	// The out_valid cannot overlap with in_valid. 
        	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        	$display ("                                                                SPEC 8 FAIL!                                                                ");
        	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        	#(100);
        	$finish;
    	end

		@(negedge clk);
		action = 3'bx ;
		for( i=1 ; i<matrix_size*matrix_size ; i=i+1 ) begin
			a = $fscanf(pat_file, "%d\n", in_data);

			if ((out_valid!==0)) begin
				fail;
        		// Spec. 8
        		// The out_valid cannot overlap with in_valid. 
        		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        		$display ("                                                                SPEC 8 FAIL!                                                                ");
        		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        		#(100);
        		$finish;
    		end

			@(negedge clk);
		end
	end
	else begin
		if ((out_valid!==0)) begin
			fail;
        	// Spec. 8
        	// The out_valid cannot overlap with in_valid. 
        	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        	$display ("                                                                SPEC 8 FAIL!                                                                ");
        	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        	#(100);
        	$finish;
    	end

		@(negedge clk);
	end
	in_valid = 0 ;
	in_data = 31'bx ;
	action = 3'bx ;
end endtask
//================================================================
//  env task
//================================================================
task reset_task ; begin
	#(1.0);	rst_n = 0 ;
	#(2.0);
	if ((out_valid!==0)||(out_data!==0)) begin
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

task delay_task ; begin
    gap = $urandom_range(3, 5) ;
    repeat(gap) @(negedge clk);
end endtask
//================================================================
//  pass/fail task
//================================================================
task YOU_PASS_task ; begin
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

task fail ; begin
$display(":( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( ");
end endtask

endmodule
