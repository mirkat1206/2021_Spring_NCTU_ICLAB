//synopsys translate_off
`include "DW_sqrt.v"
`include "DW_sqrt_seq.v"
`include "DW_div.v"
`include "DW_div_seq.v"
//synopsys translate_on

module TRIANGLE(
    clk,
    rst_n,
    in_valid,
    coord_x,
    coord_y,
    out_valid,
    out_length,
	out_incenter
);
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
input wire clk, rst_n, in_valid;
input wire [4:0] coord_x, coord_y;
output reg out_valid;
output reg [12:0] out_length, out_incenter;
//================================================================
//  Wires & Registers 
//================================================================
//  INPUT
reg [4:0] xa, xb, xc, ya, yb, yc;
reg [1:0] cnt_in;
//  PYTHAGOREAN
reg flag_sqrt, has_in;
wire [10:0] aa, bb, cc;
wire [12:0] a, b, c;
wire flag_a, flag_b, flag_c;
wire flag_pythagorean;
//  INCENTER
wire [19:0] abc_x, abc_y;
wire [14:0] abc, abc_nonzero;  
reg flag_div, has_div;
wire [26:0] xc_q, yc_q;
wire [14:0] xc_r, yc_r;
wire flag_xc, flag_yc;
wire flag_incenter;
//  OUTPUT
reg flag_ready;
reg [1:0] out_cnt; 
reg fuck;
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     fuck <= 0 ;
    else begin
        if (cnt_in==3)        	fuck <= 1 ;
        else if (out_valid==1)  fuck <= 0 ;
    end
end            
//================================================================
//  OUTPUT
//================================================================
// reg flag_ready;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     flag_ready <= 0 ;
    else begin
        if (out_cnt==3)   					flag_ready <= 0 ;
        else if (fuck==1 && flag_incenter)  flag_ready <= 1 ;
    end
end            
//reg [1:0] out_cnt;  
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     out_cnt <= 0 ;
    else begin
        if (flag_ready==1)      out_cnt <= out_cnt + 1 ;
        else if (in_valid==0)   out_cnt <= 0 ;
    end
end            
// output reg out_valid;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     out_valid <= 0 ;
    else begin
        if (out_cnt!=0) out_valid <= 1 ;    
        else            out_valid <= 0 ;
    end     
end

// output reg [12:0] out_length, out_incenter;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     out_length <= 0 ;
    else begin
        if (out_cnt==1)         out_length <= a ;
        else if (out_cnt==2)    out_length <= b ;
        else if (out_cnt==3)    out_length <= c ;
        else                    out_length <= 0 ;
    end         
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     out_incenter <= 0 ;
    else begin
        if (out_cnt==1)         out_incenter <= xc_q[12:0] ;
        else if (out_cnt==2)    out_incenter <= yc_q[12:0] ;
        else if (out_cnt==3)    out_incenter <= yc_q[12:0] ;
        else                    out_incenter <= 0 ;
    end
end
//================================================================
//  INCENTER
//================================================================
// wire [19:0] abc_x, abc_y;
assign abc_x = a*xa + b*xb + c*xc ; 
assign abc_y = a*ya + b*yb + c*yc ; 
// wire [14:0] abc, abc_nonzero;  
assign abc = a + b + c ;
assign abc_nonzero = (abc==0) ? 1 : abc ;
// reg flag_div, has_div;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     has_div <= 0 ;
    else begin
        if (flag_div==1)     has_div <= 1 ;
        else if (cnt_in==3)  has_div <= 0 ;
    end        
end 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     flag_div <= 0 ;
    else begin
        if (has_div==0 && flag_div==0 && flag_pythagorean==1)    flag_div <= 1 ;
        else flag_div <= 0 ;
    end            
end 
// wire [26:0] xc_q, yc_q;
// wire [14:0] xc_r, yc_r;
// wire flag_xc, flag_yc;
DW_div_seq #( .a_width(27), .b_width(15), .tc_mode(0), .num_cyc(25), .rst_mode(0), .input_mode(0), .output_mode(1), .early_start(0) )
            U_xc( .clk(clk), .rst_n(rst_n), .hold(1'b0), .start(flag_div), .a( { abc_x , 7'd0 } ), .b(abc_nonzero), .complete(flag_xc), .quotient(xc_q), .remainder(xc_r) ); 
DW_div_seq #( .a_width(27), .b_width(15), .tc_mode(0), .num_cyc(25), .rst_mode(0), .input_mode(0), .output_mode(1), .early_start(0) )
            U_yc( .clk(clk), .rst_n(rst_n), .hold(1'b0), .start(flag_div), .a( { abc_y , 7'd0 } ), .b(abc_nonzero), .complete(flag_yc), .quotient(yc_q), .remainder(yc_r) ); 
// synopsys dc_script_begin
// set_implimetation cpa U_xc
// set_implimetation cpa U_yc
// synopsys dc_script_end
// debug
wire [5:0] xc_q_int, yc_q_int;
wire [6:0] xc_q_frc, yc_q_frc;
assign xc_q_int = xc_q[12:7] ;
assign yc_q_int = yc_q[12:7] ;
assign xc_q_frc = xc_q[6:0] ;
assign yc_q_frc = yc_q[6:0] ;
// wire flag_incenter;
assign flag_incenter = flag_xc && flag_yc && has_div ;
//================================================================
//  PYTHAGOREAN
//================================================================
// wire [10:0] aa, bb, cc;
// module Pythagorean_step1(x1, x2, y1, y2, out);
// x1 >= x2, y1 >= y2
Pythagorean_step1 U_aa( .out(aa), .x1( (xb>=xc)?xb:xc ), .x2( (xb>=xc)?xc:xb ), .y1( (yb>=yc)?yb:yc ), .y2( (yb>=yc)?yc:yb ) );
Pythagorean_step1 U_bb( .out(bb), .x1( (xa>=xc)?xa:xc ), .x2( (xa>=xc)?xc:xa ), .y1( (ya>=yc)?ya:yc ), .y2( (ya>=yc)?yc:ya ) );
Pythagorean_step1 U_cc( .out(cc), .x1( (xa>=xb)?xa:xb ), .x2( (xa>=xb)?xb:xa ), .y1( (ya>=yb)?ya:yb ), .y2( (ya>=yb)?yb:ya ) );
// reg flag_sqrt, has_in;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     has_in <= 0 ;
    else if (cnt_in==3) has_in <= 1 ;     
end    
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     flag_sqrt <= 0 ;
    else begin
        if (cnt_in==3) 	flag_sqrt <= 1 ;
        else          	flag_sqrt <= 0 ;
    end         
end
// DW_sqrt_seq
// wire [12:0] a, b, c;
// wire flag_a, flag_b, flag_c;
DW_sqrt_seq #( .width(25), .tc_mode(0), .num_cyc(13), .rst_mode(0), .input_mode(0), .output_mode(1), .early_start(0) ) 
            U_a( .clk(clk), .rst_n(rst_n), .hold(1'b0), .start(flag_sqrt), .a( { aa , 14'd0 } ), .complete(flag_a), .root(a) );
DW_sqrt_seq #( .width(25), .tc_mode(0), .num_cyc(13), .rst_mode(0), .input_mode(0), .output_mode(1), .early_start(0) ) 
            U_b( .clk(clk), .rst_n(rst_n), .hold(1'b0), .start(flag_sqrt), .a( { bb , 14'd0 } ), .complete(flag_b), .root(b) ); 
DW_sqrt_seq #( .width(25), .tc_mode(0), .num_cyc(13), .rst_mode(0), .input_mode(0), .output_mode(1), .early_start(0) ) 
            U_c( .clk(clk), .rst_n(rst_n), .hold(1'b0), .start(flag_sqrt), .a( { cc , 14'd0 } ), .complete(flag_c), .root(c) );          
// synopsys dc_script_begin
// set_implimetation cpa U_a
// set_implimetation cpa U_b
// set_implimetation cpa U_c
// synopsys dc_script_end            
// debug
wire [5:0] a_int, b_int, c_int;
wire [6:0] a_frc, b_frc, c_frc;
assign a_int = a[12:7] ;
assign b_int = b[12:7] ;
assign c_int = c[12:7] ;
assign a_frc = a[6:0] ;
assign b_frc = b[6:0] ;
assign c_frc = c[6:0] ;
// wire flag_pythagorean;
assign flag_pythagorean = flag_a && flag_b && flag_c && has_in ; 
//================================================================
//  INPUT
//================================================================
// reg [1:0] cnt_in;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     cnt_in <= 0 ;
    else begin
        if (in_valid==1)        cnt_in <= cnt_in + 1 ;
        else if (cnt_in==3)     cnt_in <= 0 ;
    end        
end 

// reg unsigned [4:0] xa, xb, xc, ya, yb, yc;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        xa <= 0 ;
        xb <= 0 ;
        xc <= 0 ;
    end
    else begin
        if (in_valid==1) begin
            xa <= xb ;
            xb <= xc ;
            xc <= coord_x ;
        end            
    end        
end     
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ya <= 0 ;
        yb <= 0 ;
        yc <= 0 ;
    end
    else begin
        if (in_valid==1) begin
            ya <= yb ;
            yb <= yc ;
            yc <= coord_y ;
        end            
    end        
end

endmodule

//================================================================
//  SUBMODULE
//================================================================
module Pythagorean_step1(x1, x2, y1, y2, out);
input wire [4:0] x1, x2, y1, y2;
output [10:0] out;

wire [4:0] x1_x2, y1_y2;

assign x1_x2 = x1 - x2 ;
assign y1_y2 = y1 - y2 ;
assign out = x1_x2*x1_x2 + y1_y2*y1_y2;

endmodule