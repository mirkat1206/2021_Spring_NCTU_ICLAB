`define CYCLE_TIME 20.0

`ifdef RTL
	`define PATTERN_NUM 100000
`endif
`ifdef GATE
	`define PATTERN_NUM 200
`endif

module PATTERN(
  // Output signals
    mode,
    W_0, V_GS_0, V_DS_0,
    W_1, V_GS_1, V_DS_1,
    W_2, V_GS_2, V_DS_2,
    W_3, V_GS_3, V_DS_3,
    W_4, V_GS_4, V_DS_4,
    W_5, V_GS_5, V_DS_5,   
  // Input signals
    out_n
);
//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output reg [2:0] W_0, V_GS_0, V_DS_0;
output reg [2:0] W_1, V_GS_1, V_DS_1;
output reg [2:0] W_2, V_GS_2, V_DS_2;
output reg [2:0] W_3, V_GS_3, V_DS_3;
output reg [2:0] W_4, V_GS_4, V_DS_4;
output reg [2:0] W_5, V_GS_5, V_DS_5;
output reg [1:0] mode;
input [9:0] out_n;

//================================================================
// parameters & integer
//================================================================
integer PATNUM;
integer patcount;
integer input_file, output_file;
integer a,k,i,j;
//================================================================
// wire & registers 
//================================================================
reg [2:0] input_reg[17:0];
reg [9:0] golden_ans;
//================================================================
// clock
//================================================================
reg clk;
real	CYCLE = `CYCLE_TIME;
always	#(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

//================================================================
// Hint
//================================================================
// if you want to use c++/python to generate test data, here is 
// a sample format for you. You can change for your convinience.
/* input.txt format
1. [PATTERN_NUM] 

repeat(PATTERN_NUM)
	1. [mode] 
	2. [W_0 V_GS_0 V_DS_0]
	3. [W_1 V_GS_1 V_DS_1]
	4. [W_2 V_GS_2 V_DS_2]
	5. [W_3 V_GS_3 V_DS_3]
	6. [W_4 V_GS_4 V_DS_4]
	7. [W_5 V_GS_5 V_DS_5]
*/

/* output.txt format
1. [out_n]
*/

//================================================================
// initial
//================================================================
initial begin
	//input_file=$fopen("../00_TESTBED/input.txt","r");
    //output_file=$fopen("../00_TESTBED/output.txt","r");
    W_0 = 'bx; V_GS_0 = 'bx; V_DS_0 = 'bx;
    W_1 = 'bx; V_GS_1 = 'bx; V_DS_1 = 'bx;
    W_2 = 'bx; V_GS_2 = 'bx; V_DS_2 = 'bx;
    W_3 = 'bx; V_GS_3 = 'bx; V_DS_3 = 'bx;
    W_4 = 'bx; V_GS_4 = 'bx; V_DS_4 = 'bx;
    W_5 = 'bx; V_GS_5 = 'bx; V_DS_5 = 'bx;
	mode = 'dx;
    repeat(5) @(negedge clk);
    
    //k = $fscanf(input_file,"%d",PATNUM);
    
    PATNUM = `PATTERN_NUM;
	
    for(patcount = 0; patcount < PATNUM; patcount = patcount + 1) begin		
		input_data;
        repeat(1) @(negedge clk);
		check_ans;
		repeat(3) @(negedge clk);
	end
	display_pass;
    repeat(3) @(negedge clk);
    $finish;
end

//================================================================
// task
//================================================================
task input_data; begin
    //k = $fscanf(input_file,"%d",mode);
    //for(i=0;i<18;i=i+1) 
	//    k = $fscanf(input_file,"%d",input_reg[i]);
    
    mode = ($random()%'d4);
    W_0  = ($random()%'d7)+1;  V_GS_0 = ($random()%'d7)+1;  V_DS_0 = ($random()%'d7)+1;
    W_1  = ($random()%'d7)+1;  V_GS_1 = ($random()%'d7)+1;  V_DS_1 = ($random()%'d7)+1;
    W_2  = ($random()%'d7)+1;  V_GS_2 = ($random()%'d7)+1;  V_DS_2 = ($random()%'d7)+1;
    W_3  = ($random()%'d7)+1;  V_GS_3 = ($random()%'d7)+1;  V_DS_3 = ($random()%'d7)+1;
    W_4  = ($random()%'d7)+1;  V_GS_4 = ($random()%'d7)+1;  V_DS_4 = ($random()%'d7)+1;
    W_5  = ($random()%'d7)+1;  V_GS_5 = ($random()%'d7)+1;  V_DS_5 = ($random()%'d7)+1;

    

end endtask

task check_ans; begin
    //k = $fscanf(output_file,"%d",golden_ans);    
    gen_golden;
    if(out_n!==golden_ans) begin
        display_fail;
        $display ("-------------------------------------------------------------------");
		$display("*                            PATTERN NO.%4d 	                      ", patcount);
        $display ("             answer should be : %d , your answer is : %d           ", golden_ans, out_n);
        $display ("-------------------------------------------------------------------");
        #(100);
        $finish ;
    end
    else $display ("             \033[0;32mPass Pattern NO. %d\033[m         ", patcount);
end endtask

task display_fail; begin
        $display("\n");
        $display("\n");
        $display("        ----------------------------               ");
        $display("        --                        --       |\__||  ");
        $display("        --  OOPS!!                --      / X,X  | ");
        $display("        --                        --    /_____   | ");
        $display("        --  \033[0;31mSimulation Failed!!\033[m   --   /^ ^ ^ \\  |");
        $display("        --                        --  |^ ^ ^ ^ |w| ");
        $display("        ----------------------------   \\m___m__|_|");
        $display("\n");
end endtask

task display_pass; begin
        $display("\n");
        $display("\n");
        $display("        ----------------------------               ");
        $display("        --                        --       |\__||  ");
        $display("        --  Congratulations !!    --      / O.O  | ");
        $display("        --                        --    /_____   | ");
        $display("        --  \033[0;32mSimulation PASS!!\033[m     --   /^ ^ ^ \\  |");
        $display("        --                        --  |^ ^ ^ ^ |w| ");
        $display("        ----------------------------   \\m___m__|_|");
        $display("\n");
end endtask

reg region0, region1, region2, region3, region4, region5;
reg [9:0] ID[5:0];
reg [5:0] gm[5:0];
reg [9:0] tmp;

task gen_golden; begin
    region0 = ( V_GS_0 - 1 > V_DS_0) ? 1 : 0 ;   // 1:triode 0:saturation
    region1 = ( V_GS_1 - 1 > V_DS_1) ? 1 : 0 ;
    region2 = ( V_GS_2 - 1 > V_DS_2) ? 1 : 0 ;
    region3 = ( V_GS_3 - 1 > V_DS_3) ? 1 : 0 ;
    region4 = ( V_GS_4 - 1 > V_DS_4) ? 1 : 0 ;
    region5 = ( V_GS_5 - 1 > V_DS_5) ? 1 : 0 ;
    
    if( region0 == 1 ) begin
        ID[0] = W_0 * V_DS_0 * (2*V_GS_0-2-V_DS_0) / 3 ;
        gm[0] = 2 * W_0 * V_DS_0 / 3 ;
    end 
    else begin 
        ID[0] = W_0 * (V_GS_0-1) * (V_GS_0-1) / 3 ;
        gm[0] = 2 * W_0 * (V_GS_0-1) / 3 ;
    end 
    
    if( region1 == 1 ) begin
        ID[1] = W_1 * V_DS_1 * (2*V_GS_1-2-V_DS_1) / 3 ;
        gm[1] = 2 * W_1 * V_DS_1 / 3 ;
    end 
    else begin 
        ID[1] = W_1 * (V_GS_1-1) * (V_GS_1-1) / 3 ;
        gm[1] = 2 * W_1 * (V_GS_1-1) / 3 ;
    end 
    
    if( region2 == 1 ) begin
        ID[2] = W_2 * V_DS_2 * (2*V_GS_2-2-V_DS_2) / 3 ;
        gm[2] = 2 * W_2 * V_DS_2 / 3 ;
    end 
    else begin 
        ID[2] = W_2 * (V_GS_2-1) * (V_GS_2-1) / 3 ;
        gm[2] = 2 * W_2 * (V_GS_2-1) / 3 ;
    end 
    
    if( region3 == 1 ) begin
        ID[3] = W_3 * V_DS_3 * (2*V_GS_3-2-V_DS_3) / 3 ;
        gm[3] = 2 * W_3 * V_DS_3 / 3 ;
    end 
    else begin 
        ID[3] = W_3 * (V_GS_3-1) * (V_GS_3-1) / 3 ;
        gm[3] = 2 * W_3 * (V_GS_3-1) / 3 ;
    end 
    
    if( region4 == 1 ) begin
        ID[4] = W_4 * V_DS_4 * (2*V_GS_4-2-V_DS_4) / 3 ;
        gm[4] = 2 * W_4 * V_DS_4 / 3 ;
    end 
    else begin 
        ID[4] = W_4 * (V_GS_4-1) * (V_GS_4-1) / 3 ;
        gm[4] = 2 * W_4 * (V_GS_4-1) / 3 ;
    end 
    
    if( region5 == 1 ) begin
        ID[5] = W_5 * V_DS_5 * (2*V_GS_5-2-V_DS_5) / 3 ;
        gm[5] = 2 * W_5 * V_DS_5 / 3 ;
    end 
    else begin 
        ID[5] = W_5 * (V_GS_5-1) * (V_GS_5-1) / 3 ;
        gm[5] = 2 * W_5 * (V_GS_5-1) / 3 ;
    end 
    
    
    if( mode[0] == 1 ) begin
        for( i=0; i<6; i=i+1) begin
            for( j=0; j<6-i; j=j+1) begin 
                if( ID[j] < ID[j+1] ) begin
                    tmp     = ID[j];
                    ID[j]   = ID[j+1];
                    ID[j+1] = tmp;
                end    
            end
        end
    end
    
    else begin
        for( i=0; i<6; i=i+1) begin
            for( j=0; j<6-i; j=j+1) begin 
                if( gm[j] < gm[j+1] ) begin
                    tmp     = gm[j];
                    gm[j]   = gm[j+1];
                    gm[j+1] = tmp;
                end    
            end
        end 
    end
    
    if( mode[0] == 1 ) begin
        if( mode[1] == 1) begin
            golden_ans = 3*ID[0] + 4*ID[1] + 5*ID[2];
        end
        else begin
            golden_ans = 3*ID[3] + 4*ID[4] + 5*ID[5];
        end
    end
    
    else begin
        if( mode[1] == 1) begin
            golden_ans = gm[0] + gm[1] + gm[2];
        end
        else begin
            golden_ans = gm[3] + gm[4] + gm[5];
        end
    end
    
end endtask

endmodule
