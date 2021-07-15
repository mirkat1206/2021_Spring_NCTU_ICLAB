`ifdef RTL
`define CYCLE_TIME 25
`endif
`ifdef GATE
`define CYCLE_TIME 25
`endif

module PATTERN(
    clk,
    rst_n,
    in_valid,
    coord_x,
    coord_y,
    out_valid,
    out_length,
    out_incenter,
);

output reg clk, rst_n, in_valid;
output reg [4:0] coord_x, coord_y;
input wire out_valid;

input [12:0] out_length;
input [12:0] out_incenter;

parameter PAT_NUM = 1000;

integer SEED = 777;
integer p, i, l, c, f_in, f_out;

reg [4:0] point_x [2:0];
reg [4:0] point_y [2:0];

real gold_result, gold_ans, err_len, err_inc;
real gold_x [2:0];
real gold_y [2:0];
real gold_length [2:0];
real gold_incent [1:0];
real max, mid, min;

real CYCLE = `CYCLE_TIME;
initial clk = 0;
always #(CYCLE / 2.0) clk = ~clk;

initial begin
	coord_x = 'bx;
	coord_y = 'bx;
	in_valid = 'b0;
	rst_n = 'b1;
	
	force clk = 0;

	reset_signal_task;
    repeat(10) @(negedge clk);	

	f_in = $fopen("../00_TESTBED/input.txt", "r");
	f_out = $fopen("../00_TESTBED/output.txt", "r");
   
    for (p = 0; p < PAT_NUM ; p = p + 1) begin
		load_pattern_task;
		input_task;
		wait_out_task;
		check_ans_task;
		repeat(1) @(negedge clk);
	end

	$fclose(f_in);
	$fclose(f_out);
	you_pass_task;
end

task reset_signal_task; begin 
    repeat(3) #(CYCLE);   
	rst_n = 'b0;
	repeat(3) #(CYCLE);  
	if ((out_valid !== 'b0) || (out_incenter !== 'b0) || (out_length !== 'b0)) begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                        FAIL!                                                               ");
		$display ("                                                  Output signals should be 0 after initial RESET at %8t                                     ",$time);
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$finish;
	end
	repeat(10) #(CYCLE);
    rst_n = 'b1;
	repeat(3) #(CYCLE);
    release clk;
end endtask


task load_pattern_task; begin
	$fscanf(f_in, "%d %d %d %d %d %d\n", point_x[0], point_y[0], point_x[1], point_y[1], point_x[2], point_y[2]);
	$fscanf(f_out, "%f %f %f %f %f\n", gold_length[0], gold_length[1], gold_length[2], gold_incent[0], gold_incent[1]);
end endtask

task input_task; begin
    in_valid = 'b1;
	for (i = 0; i < 3; i = i + 1) begin
		coord_x = point_x[i];
		coord_y = point_y[i];
		check_overlap_task;
		@(negedge clk);
	end
	in_valid = 'b0;
	coord_x = 'bx;
	coord_y = 'bx;
end endtask

task check_overlap_task; begin
	if (out_valid == 'd1) begin
		$display ("----------------------------------------------------------------------------------------------------------------------");
		$display ("                                                  FAIL!                                                               ");
		$display ("                                           Out_valid overlaps with in_valid!                                          ");
		$display ("----------------------------------------------------------------------------------------------------------------------");
		$finish;
	end
end endtask



task wait_out_task; begin
	l = 0;
	while (out_valid == 'b0) begin
		if (l > 1000) begin
		    $display ("----------------------------------------------------------------------------------------------------------------------");
			$display ("                                                  FAIL!                                                               ");
			$display ("                                           latency over 1000 cycles!                                                  ");
			$display ("----------------------------------------------------------------------------------------------------------------------");
			$finish;
		end else begin
			l = l + 1;
			@(negedge clk);
		end
	end
end endtask

task check_ans_task; begin
	c = 0;
	while (out_valid == 'b1) begin
		if (c >= 3) begin
		    $display ("----------------------------------------------------------------------------------------------------------------------");
			$display ("                                                  FAIL!                                                               ");
			$display ("                                           Out_valid raised over 3 cycles!                                            ");
			$display ("----------------------------------------------------------------------------------------------------------------------");
			$finish;
		end else begin
		
			gold_ans = gold_length[c];
			gold_result = out_length / 128.0;
			err_len = gold_ans - gold_result;
			if ((err_len > 0.1) || (err_len < -0.1)) begin
				$display ("----------------------------------------------------------------------------------------------------------------------");
				$display ("                                                  FAIL!                                                               ");
				$display ("                                           Error is over 0.1!                                                         ");
				$display ("                                         Answer: %f, output %f                                                        ", gold_ans, gold_result);
				$display ("----------------------------------------------------------------------------------------------------------------------");
				$finish;
			end
			if (c<2)begin
				gold_ans = gold_incent[c];
				gold_result = out_incenter / 128.0;
				err_inc = gold_ans - gold_result;
				if ((err_inc > 0.1) || (err_inc < -0.1)) begin
					$display ("----------------------------------------------------------------------------------------------------------------------");
					$display ("                                                  FAIL!                                                               ");
					$display ("                                           Error is over 0.03125!                                                     ");
					$display ("                                         Answer: %f, output %f                                                        ", gold_ans, gold_result);
					$display ("----------------------------------------------------------------------------------------------------------------------");
					$finish;
				end
			end
			$display("err_len = %f , err_inc = %f", err_len, err_inc);
			c = c + 1;
			@(negedge clk);
		end
	end
	if (c < 3) begin
		$display ("----------------------------------------------------------------------------------------------------------------------");
		$display ("                                                  FAIL!                                                               ");
		$display ("                                           Out_valid raised under 3 cycles!                                           ");
		$display ("----------------------------------------------------------------------------------------------------------------------");
		$finish;
	end
	$display("\033[0;38;5;111mPASS PATTERN \033[4m NO.%3d \033[m", p);
end endtask

task you_pass_task; begin
	$display ("*********************************");
	$display ("         Congratulation!         ");
	$display ("      You pass all patterns!     ");
	$display ("*********************************");
	$finish;
end endtask
    
endmodule
