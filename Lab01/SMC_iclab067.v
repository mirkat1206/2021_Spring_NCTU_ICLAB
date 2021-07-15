//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Lab01          : Supper MOSFET Calculator (SMC)
//   Author         : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : SMC.v
//   Module Name : SMC
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module SMC(
    // Input signals
    mode,
    W_0, V_GS_0, V_DS_0,
    W_1, V_GS_1, V_DS_1,
    W_2, V_GS_2, V_DS_2,
    W_3, V_GS_3, V_DS_3,
    W_4, V_GS_4, V_DS_4,
    W_5, V_GS_5, V_DS_5,   
    // Output signals
    out_n
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [2:0] W_0, V_GS_0, V_DS_0;
input [2:0] W_1, V_GS_1, V_DS_1;
input [2:0] W_2, V_GS_2, V_DS_2;
input [2:0] W_3, V_GS_3, V_DS_3;
input [2:0] W_4, V_GS_4, V_DS_4;
input [2:0] W_5, V_GS_5, V_DS_5;
input [1:0] mode;
output [9:0] out_n;

//================================================================
//    Wire & Registers 
//================================================================
//
genvar idx;
integer i;
parameter MAXN = 5 ;
//
wire [2:0] W_[0:MAXN], V_GS[0:MAXN], V_DS[0:MAXN];
//
wire [2:0] ID_Tri_A[0:MAXN], ID_Tri_B[0:MAXN];
wire [3:0] ID_Tri_C[0:MAXN];
wire [2:0] ID_Sat_A[0:MAXN], ID_Sat_B[0:MAXN], ID_Sat_C[0:MAXN];
wire [2:0] gm_Tri_A[0:MAXN], gm_Tri_B[0:MAXN], gm_Tri_C[0:MAXN];
wire [2:0] gm_Sat_A[0:MAXN], gm_Sat_B[0:MAXN], gm_Sat_C[0:MAXN];
//
wire is_Tri[0:MAXN];
//
wire [2:0] ID_A[0:MAXN], ID_B[0:MAXN], gm_A[0:MAXN], gm_B[0:MAXN], gm_C[0:MAXN];
wire [3:0] ID_C[0:MAXN];
wire [2:0] A[0:MAXN], B[0:MAXN];
wire [3:0] C[0:MAXN];
//
wire [9:0] cal_out[0:MAXN];
wire [9:0] n[0:MAXN], n1[0:MAXN];
//
wire [9:0] out_0, out_1, out_2;
//================================================================
//    DESIGN
//================================================================
// Turn default input forms into array forms
assign W_[0] = W_0 ;
assign W_[1] = W_1 ;
assign W_[2] = W_2 ;
assign W_[3] = W_3 ;
assign W_[4] = W_4 ;
assign W_[5] = W_5 ;
assign V_GS[0] = V_GS_0 ;
assign V_GS[1] = V_GS_1 ;
assign V_GS[2] = V_GS_2 ;
assign V_GS[3] = V_GS_3 ;
assign V_GS[4] = V_GS_4 ;
assign V_GS[5] = V_GS_5 ;
assign V_DS[0] = V_DS_0 ;
assign V_DS[1] = V_DS_1 ;
assign V_DS[2] = V_DS_2 ;
assign V_DS[3] = V_DS_3 ;
assign V_DS[4] = V_DS_4 ;
assign V_DS[5] = V_DS_5 ;

// assign (ID/gm)_(Tri/Sat)_(A/B/C)
generate
    for( idx=0 ; idx<=MAXN ; idx=idx+1 ) begin
        //
        assign ID_Tri_A[idx] = V_DS[idx] ;
        assign ID_Tri_B[idx] = W_[idx] ;
        assign ID_Tri_C[idx] = 2*V_GS[idx] - V_DS[idx] - 2 ;
        //
        assign gm_Tri_A[idx] = 2 ;
        assign gm_Tri_B[idx] = W_[idx] ;
        assign gm_Tri_C[idx] = V_DS[idx] ;
        //
        assign ID_Sat_A[idx] = W_[idx] ;
        assign ID_Sat_B[idx] = V_GS[idx] - 1 ;
        assign ID_Sat_C[idx] = ID_Sat_B[idx] ;      // V_GS[idx] - 1
        //
        assign gm_Sat_A[idx] = 2 ;
        assign gm_Sat_B[idx] = W_[idx] ;
        assign gm_Sat_C[idx] = ID_Sat_B[idx] ;      // V_GS[idx] - 1
    end
endgenerate

// check either MOSFET is in Triode or Saturation region
generate
    for( idx=0 ; idx<=MAXN ; idx=idx+1 ) begin
        assign is_Tri[idx] = ( V_GS[idx]>(V_DS[idx]+1) ) ? 1'b1 : 1'b0 ;
    end
endgenerate

// based on Triode/Saturation region, choose (ID/gm)_(A/B/C)
generate
    for( idx=0 ; idx<=MAXN ; idx=idx+1 ) begin
        assign ID_A[idx] = ( is_Tri[idx]==1'b1 ) ? ID_Tri_A[idx] : ID_Sat_A[idx] ;
        assign ID_B[idx] = ( is_Tri[idx]==1'b1 ) ? ID_Tri_B[idx] : ID_Sat_B[idx] ;
        assign ID_C[idx] = ( is_Tri[idx]==1'b1 ) ? ID_Tri_C[idx] : ID_Sat_C[idx] ;
        assign gm_A[idx] = ( is_Tri[idx]==1'b1 ) ? gm_Tri_A[idx] : gm_Sat_A[idx] ;
        assign gm_B[idx] = ( is_Tri[idx]==1'b1 ) ? gm_Tri_B[idx] : gm_Sat_B[idx] ;
        assign gm_C[idx] = ( is_Tri[idx]==1'b1 ) ? gm_Tri_C[idx] : gm_Sat_C[idx] ;
    end
endgenerate

// based on mode[0], choose A, B, C
generate
    for( idx=0 ; idx<=MAXN ; idx=idx+1 ) begin
        assign A[idx] = ( mode[0]==1'b1 ) ? ID_A[idx] : gm_A[idx] ;
        assign B[idx] = ( mode[0]==1'b1 ) ? ID_B[idx] : gm_B[idx] ;
        assign C[idx] = ( mode[0]==1'b1 ) ? ID_C[idx] : gm_C[idx] ;
    end
endgenerate

//
generate
    for( idx=0 ; idx<=MAXN ; idx=idx+1 ) begin
        assign cal_out[idx] = ( A[idx] * B[idx] * C[idx] ) / 3 ;
    end
endgenerate

// sort
Sort sort(  .in0(cal_out[0]), .in1(cal_out[1]), .in2(cal_out[2]), .in3(cal_out[3]), .in4(cal_out[4]), .in5(cal_out[5]),
            .out0(n[0]) , .out1(n[1]) , .out2(n[2]) , .out3(n[3]) , .out4(n[4]) , .out5(n[5]) );

// based on mode[1], choose larger/smaller values
assign n1[0] = ( mode[1]==1'b1 ) ? n[0] : n[3] ;
assign n1[1] = ( mode[1]==1'b1 ) ? n[1] : n[4] ;
assign n1[2] = ( mode[1]==1'b1 ) ? n[2] : n[5] ;

// based on mode[0], choose ID/gm output function
assign out_0 = ( mode[0]==1'b0 ) ? n1[0] : ( n1[0]<<1 ) + n1[0] ;
assign out_1 = ( mode[0]==1'b0 ) ? n1[1] : ( n1[1]<<2 ) ;
assign out_2 = ( mode[0]==1'b0 ) ? n1[2] : ( n1[2]<<2 ) + n1[2] ;

// output
assign out_n = out_0 + out_1 + out_2 ;

endmodule

//================================================================
//   SUB MODULE
//================================================================
// sort 6 elements
module Sort(
    // Input signals
    in0, in1, in2, in3, in4, in5,
    // Output signals
    out0, out1, out2, out3, out4, out5
);
//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [9:0] in0, in1, in2, in3, in4, in5;
output [9:0] out0, out1, out2, out3, out4, out5;
//================================================================
//    Wire & Registers 
//================================================================
wire [9:0] a[0:3], b[0:2], c[0:3], d[0:2], e[0:5], f[0:3], g[0:1];
//================================================================
//    DESIGN
//================================================================
//
assign a[0] = ( in0>in1 ) ? in0 : in1 ;
assign a[1] = ( in0>in1 ) ? in1 : in0 ;
assign a[2] = ( a[1]>in2 )? a[1] : in2 ;
assign a[3] = ( a[1]>in2 )? in2 : a[1] ;
assign b[0] = ( a[0]>a[2] ) ? a[0] : a[2] ;
assign b[1] = ( a[0]>a[2] ) ? a[2] : a[0] ;
assign b[2] = a[3] ;
//
assign c[0] = ( in3>in4 ) ? in3 : in4 ;
assign c[1] = ( in3>in4 ) ? in4 : in3 ;
assign c[2] = ( c[1]>in5 )? c[1] : in5 ;
assign c[3] = ( c[1]>in5 )? in5 : c[1] ;
assign d[0] = ( c[0]>c[2] ) ? c[0] : c[2] ;
assign d[1] = ( c[0]>c[2] ) ? c[2] : c[0] ;
assign d[2] = c[3] ;
//
assign e[0] = ( b[0]>d[0] ) ? b[0] : d[0] ;
assign e[1] = ( b[0]>d[0] ) ? d[0] : b[0] ;
assign e[2] = ( b[1]>d[1] ) ? b[1] : d[1] ;
assign e[3] = ( b[1]>d[1] ) ? d[1] : b[1] ;
assign e[4] = ( b[2]>d[2] ) ? b[2] : d[2] ;
assign e[5] = ( b[2]>d[2] ) ? d[2] : b[2] ;
//
assign out0 = e[0] ;
assign out5 = e[5] ;
//
assign f[0] = ( e[1]>e[2] ) ? e[1] : e[2] ;
assign f[1] = ( e[1]>e[2] ) ? e[2] : e[1] ;
assign f[2] = ( e[3]>e[4] ) ? e[3] : e[4] ;
assign f[3] = ( e[3]>e[4] ) ? e[4] : e[3] ;
//
assign out1 = f[0] ;
assign out4 = f[3] ;
//
assign g[0] = ( f[1]>f[2] ) ? f[1] : f[2] ;
assign g[1] = ( f[1]>f[2] ) ? f[2] : f[1] ;
//
assign out2 = g[0] ;
assign out3 = g[1] ;

endmodule