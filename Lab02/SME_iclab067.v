//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Lab02			: String Match Engine (SME)
//   Author         : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : SME.v
//   Module Name : SME
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module SME(
    // Input signals
    clk,
    rst_n,
    chardata,
    isstring,
    ispattern,
    // Output signals
    out_valid,
    match,
    match_index
);
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
input clk;
input rst_n;
input [7:0] chardata;
input isstring;
input ispattern;
output reg match;
output reg [4:0] match_index;
output reg out_valid;
//================================================================
//  integer / genvar / parameters
//================================================================
integer i, j;
genvar idx, jdx;
// Special charaters
parameter CHR_START = 8'h5E ;   // ^ : starting position of the string or 'space' would match
parameter CHR_ENDIN = 8'h24 ;   // $ : ending position of the string or 'space' would match
parameter CHR_ANYSG = 8'h2E ;   // . : any of a single charater would match
parameter CHR_ANYML = 8'h2A ;   // * : any of multiple characters would match
parameter CHR_SPACE = 8'h20 ;   //   : space
parameter CHR_NOTHN = 8'h00 ;   // my own definition, used in string
parameter CHR_MATCH = 8'h01 ;   // my own definition, used in pattern
//================================================================
//   Wires & Registers 
//================================================================
//  INPUT
reg f_isstring, f_ispattern;
reg [7:0] String[0:33];         // [0], [33] : for checking CHR_START/CHR_ENDIN
reg [7:0] Pattern[0:7];
reg [5:0] head_str;             // head position of the input string among string[0:33]
reg [3:0] lnth_ptn;             // length of the input pattern
//  Handle The Fucking Annoying *
reg is_star;                    // is there a star in the input pattern
reg [3:0] pos_star;             // pattern[0~7] <--> pos_star[0~8], where 8 means no star
//  MATCH_TABLE
wire is_equivalent[0:7][0:33];
reg match_table[0:7][0:33];
//  AND_TABLE & REV_AND_TABLE : 2D
wire and_table[0:7][0:33];      // down-right to top-left
wire rev_and_table[0:7][0:33];  // top-left to down-right
//  IS_MATCH_ARRAY & REV_IS_MATCH_ARRAY : 2D to 1D
reg is_match_array[0:33];       // down-right to top-left
reg rev_is_match_array[0:33];   // top-left to down-right
//  MATCH_POS & REV_MATCH_POS
reg [5:0] match_pos;            // down-right to top-left
reg [5:0] rev_match_pos;        // top-left to down-right
//  IS_MATCH : 1D to 1-bit
wire is_match, is_match_w_star, is_match_wo_star;
//  IS_STATE_MATCH
reg is_state_match;
//  PRE_OUTPUT
reg is_ptn_head_start;      
reg [5:0] next_match_index;
//================================================================
//  OUTPUT : out_valid & match
//================================================================
// out_valid
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     out_valid <= 0 ;
    else begin
        if (is_state_match==1'b1)   out_valid <= 1 ;
        else        out_valid <= 0 ;
    end
end

// match
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) match <= 0 ;
    else        match <= is_match ;
end
//================================================================
//  OUTPUT : match_index
//================================================================
// match_index
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     match_index <= 5'd0 ;
    else begin
        if (is_match==1'b1 & match_pos<head_str )
            match_index <= 0 ;
        else
            match_index <= next_match_index ;
    end
end
//================================================================
//  PRE_OUTPUT
//================================================================
// match_pos : the line below than CHR_ANYML *
// rev_match_pos : the same line as CHR_ANYML 
// pattern[0~7] <--> pos_star[0~8], where 8 means no star
wire [5:0] real_rev_match_pos;
wire [5:0] lnth_before_star;
assign lnth_before_star = lnth_ptn - ( 7 - pos_star ) - 1 ;
assign real_rev_match_pos =  rev_match_pos - lnth_before_star ; 

// next_match_index
always @(*) begin
    if (is_match==1'b0)     next_match_index <= 0 ;
    else if (is_star==1'b0) next_match_index <= match_pos - head_str + is_ptn_head_start ;
    else if (rev_match_pos<head_str)  next_match_index <= 0 ;
    else    next_match_index <= real_rev_match_pos - head_str + is_ptn_head_start ;
end

// is_ptn_head_start
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     is_ptn_head_start <= 0 ;
    else begin
        // check when the 1st pattern char is inputted
        if (ispattern==1'b1 & f_ispattern==1'b0) begin
            if (chardata==CHR_START)    is_ptn_head_start <= 1 ;
            else                        is_ptn_head_start <= 0 ;
        end
    end
end
//================================================================
//  IS_STATE_MATCH
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) is_state_match <= 1'b0 ;
    else begin
        if (f_ispattern==1'b1 & ispattern==1'b0)
            is_state_match <= 1'b1 ;
        else 
            is_state_match <= 1'b0 ;
    end
end
//================================================================
//  IS_MATCH : 1D to 1-bit
//================================================================
// is_match_wo_star
// if match_pos==33, means no match. Since CHR_ENDIN ^ won't appear in the pattern alone
assign is_match_wo_star = (match_pos==33) ? 1'b0 : 1'b1 ;                

// is_match_w_star
// match_pos : the same line as CHR_ANYML *
// rev_match_pos : the same line as CHR_ANYML *
assign is_match_w_star = ( (rev_match_pos!=33) & (match_pos!=0) & (rev_match_pos<=(match_pos+1)) ) ? 1'b1 : 1'b0 ;

// is_match
assign is_match = (is_star==1'b1) ? is_match_w_star : is_match_wo_star ;                     
//================================================================
//  MATCH_POS & REV_MATCH_POS
//================================================================
// match_pos : down-right to top-left
always @(*) begin
    // no CHR_ANYML *, search the first match
    if (is_star==1'b0) begin
         if (is_match_array[0] ==1'b1)    match_pos <=  0 ;
    else if (is_match_array[1] ==1'b1)    match_pos <=  1 ;
    else if (is_match_array[2] ==1'b1)    match_pos <=  2 ;
    else if (is_match_array[3] ==1'b1)    match_pos <=  3 ;
    else if (is_match_array[4] ==1'b1)    match_pos <=  4 ;
    else if (is_match_array[5] ==1'b1)    match_pos <=  5 ;
    else if (is_match_array[6] ==1'b1)    match_pos <=  6 ;
    else if (is_match_array[7] ==1'b1)    match_pos <=  7 ;
    else if (is_match_array[8] ==1'b1)    match_pos <=  8 ;
    else if (is_match_array[9] ==1'b1)    match_pos <=  9 ;
    else if (is_match_array[10]==1'b1)    match_pos <= 10 ;
    else if (is_match_array[11]==1'b1)    match_pos <= 11 ;
    else if (is_match_array[12]==1'b1)    match_pos <= 12 ;
    else if (is_match_array[13]==1'b1)    match_pos <= 13 ;
    else if (is_match_array[14]==1'b1)    match_pos <= 14 ;
    else if (is_match_array[15]==1'b1)    match_pos <= 15 ;
    else if (is_match_array[16]==1'b1)    match_pos <= 16 ;
    else if (is_match_array[17]==1'b1)    match_pos <= 17 ;
    else if (is_match_array[18]==1'b1)    match_pos <= 18 ;
    else if (is_match_array[19]==1'b1)    match_pos <= 19 ;
    else if (is_match_array[20]==1'b1)    match_pos <= 20 ;
    else if (is_match_array[21]==1'b1)    match_pos <= 21 ;
    else if (is_match_array[22]==1'b1)    match_pos <= 22 ;
    else if (is_match_array[23]==1'b1)    match_pos <= 23 ;
    else if (is_match_array[24]==1'b1)    match_pos <= 24 ;
    else if (is_match_array[25]==1'b1)    match_pos <= 25 ;
    else if (is_match_array[26]==1'b1)    match_pos <= 26 ;
    else if (is_match_array[27]==1'b1)    match_pos <= 27 ;
    else if (is_match_array[28]==1'b1)    match_pos <= 28 ;
    else if (is_match_array[29]==1'b1)    match_pos <= 29 ;
    else if (is_match_array[30]==1'b1)    match_pos <= 30 ;
    else if (is_match_array[31]==1'b1)    match_pos <= 31 ;
    else if (is_match_array[32]==1'b1)    match_pos <= 32 ;
    // if match_pos==33, means no match. Since CHR_ENDIN ^ won't appear in the pattern alone
    else                                  match_pos <= 33 ;
    end
    // with CHR_ANYML *, search the last match
    // the same line as CHR_ANYML *
    else begin
         if (is_match_array[33]==1'b1)    match_pos <= 33 ;
    else if (is_match_array[32]==1'b1)    match_pos <= 32 ;
    else if (is_match_array[31]==1'b1)    match_pos <= 31 ;
    else if (is_match_array[30]==1'b1)    match_pos <= 30 ;
    else if (is_match_array[29]==1'b1)    match_pos <= 29 ;
    else if (is_match_array[28]==1'b1)    match_pos <= 28 ;
    else if (is_match_array[27]==1'b1)    match_pos <= 27 ;
    else if (is_match_array[26]==1'b1)    match_pos <= 26 ;
    else if (is_match_array[25]==1'b1)    match_pos <= 25 ;
    else if (is_match_array[24]==1'b1)    match_pos <= 24 ;
    else if (is_match_array[23]==1'b1)    match_pos <= 23 ;
    else if (is_match_array[22]==1'b1)    match_pos <= 22 ;
    else if (is_match_array[21]==1'b1)    match_pos <= 21 ;
    else if (is_match_array[20]==1'b1)    match_pos <= 20 ;
    else if (is_match_array[19]==1'b1)    match_pos <= 19 ;
    else if (is_match_array[18]==1'b1)    match_pos <= 18 ;
    else if (is_match_array[17]==1'b1)    match_pos <= 17 ;
    else if (is_match_array[16]==1'b1)    match_pos <= 16 ;
    else if (is_match_array[15]==1'b1)    match_pos <= 15 ;
    else if (is_match_array[14]==1'b1)    match_pos <= 14 ;
    else if (is_match_array[13]==1'b1)    match_pos <= 13 ;
    else if (is_match_array[12]==1'b1)    match_pos <= 12 ;
    else if (is_match_array[11]==1'b1)    match_pos <= 11 ;
    else if (is_match_array[10]==1'b1)    match_pos <= 10 ;
    else if (is_match_array[9 ]==1'b1)    match_pos <= 9  ;
    else if (is_match_array[8 ]==1'b1)    match_pos <= 8  ;
    else if (is_match_array[7 ]==1'b1)    match_pos <= 7  ;
    else if (is_match_array[6 ]==1'b1)    match_pos <= 6  ;
    else if (is_match_array[5 ]==1'b1)    match_pos <= 5  ;
    else if (is_match_array[4 ]==1'b1)    match_pos <= 4  ;
    else if (is_match_array[3 ]==1'b1)    match_pos <= 3  ;
    else if (is_match_array[2 ]==1'b1)    match_pos <= 2  ;
    else if (is_match_array[1 ]==1'b1)    match_pos <= 1  ;
    // if match_pos==0, means no match. 
    else                                  match_pos <= 0  ;
    end
end

// rev_is_match_array : top-left to down-right
always @(*) begin
    // with CHR_ANYML *, search the first match
    // the same line as CHR_ANYML *
         if (rev_is_match_array[0] ==1'b1)    rev_match_pos <=  0 ;
    else if (rev_is_match_array[1] ==1'b1)    rev_match_pos <=  1 ;
    else if (rev_is_match_array[2] ==1'b1)    rev_match_pos <=  2 ;
    else if (rev_is_match_array[3] ==1'b1)    rev_match_pos <=  3 ;
    else if (rev_is_match_array[4] ==1'b1)    rev_match_pos <=  4 ;
    else if (rev_is_match_array[5] ==1'b1)    rev_match_pos <=  5 ;
    else if (rev_is_match_array[6] ==1'b1)    rev_match_pos <=  6 ;
    else if (rev_is_match_array[7] ==1'b1)    rev_match_pos <=  7 ;
    else if (rev_is_match_array[8] ==1'b1)    rev_match_pos <=  8 ;
    else if (rev_is_match_array[9] ==1'b1)    rev_match_pos <=  9 ;
    else if (rev_is_match_array[10]==1'b1)    rev_match_pos <= 10 ;
    else if (rev_is_match_array[11]==1'b1)    rev_match_pos <= 11 ;
    else if (rev_is_match_array[12]==1'b1)    rev_match_pos <= 12 ;
    else if (rev_is_match_array[13]==1'b1)    rev_match_pos <= 13 ;
    else if (rev_is_match_array[14]==1'b1)    rev_match_pos <= 14 ;
    else if (rev_is_match_array[15]==1'b1)    rev_match_pos <= 15 ;
    else if (rev_is_match_array[16]==1'b1)    rev_match_pos <= 16 ;
    else if (rev_is_match_array[17]==1'b1)    rev_match_pos <= 17 ;
    else if (rev_is_match_array[18]==1'b1)    rev_match_pos <= 18 ;
    else if (rev_is_match_array[19]==1'b1)    rev_match_pos <= 19 ;
    else if (rev_is_match_array[20]==1'b1)    rev_match_pos <= 20 ;
    else if (rev_is_match_array[21]==1'b1)    rev_match_pos <= 21 ;
    else if (rev_is_match_array[22]==1'b1)    rev_match_pos <= 22 ;
    else if (rev_is_match_array[23]==1'b1)    rev_match_pos <= 23 ;
    else if (rev_is_match_array[24]==1'b1)    rev_match_pos <= 24 ;
    else if (rev_is_match_array[25]==1'b1)    rev_match_pos <= 25 ;
    else if (rev_is_match_array[26]==1'b1)    rev_match_pos <= 26 ;
    else if (rev_is_match_array[27]==1'b1)    rev_match_pos <= 27 ;
    else if (rev_is_match_array[28]==1'b1)    rev_match_pos <= 28 ;
    else if (rev_is_match_array[29]==1'b1)    rev_match_pos <= 29 ;
    else if (rev_is_match_array[30]==1'b1)    rev_match_pos <= 30 ;
    else if (rev_is_match_array[31]==1'b1)    rev_match_pos <= 31 ;
    else if (rev_is_match_array[32]==1'b1)    rev_match_pos <= 32 ;
    // if rev_match_pos==33, means no match. 
    else                                      rev_match_pos <= 33 ;
end
//================================================================
//  IS_MATCH_ARRAY & REV_IS_MATCH_ARRAY : 2D to 1D
//================================================================
// is_match_array : down-right to top-left
generate
for( jdx=0 ; jdx<34 ; jdx=jdx+1 ) begin
    always @(*) begin
        if (is_star==1'b0) begin
            case(lnth_ptn)
                3'b001:     is_match_array[jdx] <= and_table[7][jdx] ;
                3'b010:     is_match_array[jdx] <= and_table[6][jdx] ;
                3'b011:     is_match_array[jdx] <= and_table[5][jdx] ;
                3'b100:     is_match_array[jdx] <= and_table[4][jdx] ;
                3'b101:     is_match_array[jdx] <= and_table[3][jdx] ;
                3'b110:     is_match_array[jdx] <= and_table[2][jdx] ;
                3'b111:     is_match_array[jdx] <= and_table[1][jdx] ;
                default:    is_match_array[jdx] <= and_table[0][jdx] ;    
            endcase           
        end
        else begin
            // pattern[0~7] <--> pos_star[0~8], where 8 means no star
           case(pos_star)   // the same line as CHR_ANYML *
                3'b001:     is_match_array[jdx] <= and_table[1][jdx] ;
                3'b010:     is_match_array[jdx] <= and_table[2][jdx] ;
                3'b011:     is_match_array[jdx] <= and_table[3][jdx] ;
                3'b100:     is_match_array[jdx] <= and_table[4][jdx] ;
                3'b101:     is_match_array[jdx] <= and_table[5][jdx] ;
                3'b110:     is_match_array[jdx] <= and_table[6][jdx] ;
                3'b111:     is_match_array[jdx] <= and_table[7][jdx] ;
                default:    is_match_array[jdx] <= and_table[0][jdx] ;    
            endcase
        end
    end
end
endgenerate

// rev_is_match_array : top-left to down-right
generate
    for( jdx=0 ; jdx<34 ; jdx=jdx+1 ) begin
        always @(*) begin
            // pattern[0~7] <--> pos_star[0~8], where 8 means no star
            case(pos_star)  // the same line as CHR_ANYML *
                3'b001:      rev_is_match_array[jdx] <= rev_and_table[1][jdx] ;
                3'b010:      rev_is_match_array[jdx] <= rev_and_table[2][jdx] ;  
                3'b011:      rev_is_match_array[jdx] <= rev_and_table[3][jdx] ;  
                3'b100:      rev_is_match_array[jdx] <= rev_and_table[4][jdx] ;  
                3'b101:      rev_is_match_array[jdx] <= rev_and_table[5][jdx] ;  
                3'b110:      rev_is_match_array[jdx] <= rev_and_table[6][jdx] ;  
                3'b111:      rev_is_match_array[jdx] <= rev_and_table[7][jdx] ;  
                default:     rev_is_match_array[jdx] <= rev_and_table[0][jdx] ;                         
            endcase
        end
    end
endgenerate
//================================================================
//  AND_TABLE & REV_AND_TABLE : 2D
//================================================================
// and_table : down-right to top-left
generate
    // down-most line
    for( jdx=0 ; jdx<34 ; jdx=jdx+1 )
        assign and_table[7][jdx] = match_table[7][jdx] ;
    // right-most line
    for( idx=0 ; idx<7 ; idx=idx+1 )
        assign and_table[idx][33] = match_table[idx][33] ;
    // other line
    for( idx=6 ; idx>=0 ; idx=idx-1 )
        for( jdx=0 ; jdx<33 ; jdx=jdx+1 )
            assign and_table[idx][jdx] = match_table[idx][jdx] & and_table[idx+1][jdx+1] ;
endgenerate

// rev_and_table : top-left to down-right
generate
    // top-most line
    for( jdx=0 ; jdx<34 ; jdx=jdx+1 )
        assign rev_and_table[0][jdx] = match_table[0][jdx] ;
    // left-most line
    for( idx=1 ; idx<8 ; idx=idx+1 ) 
        assign rev_and_table[idx][0] = match_table[idx][0] ;
    // other line
    for( idx=1 ; idx<8 ; idx=idx+1 )
        for( jdx=1 ; jdx<34 ; jdx=jdx+1 )
            assign rev_and_table[idx][jdx] = match_table[idx][jdx] & rev_and_table[idx-1][jdx-1] ;
endgenerate
//================================================================
//  MATCH_TABLE
//================================================================
// is_equivalent
generate
    for( idx=0 ; idx<8 ; idx=idx+1 )
        for( jdx=0 ; jdx<34 ; jdx=jdx+1 )
            Is_EQ func( .str(String[jdx]) , .ptn(Pattern[idx]) , .out(is_equivalent[idx][jdx]) );
endgenerate

// match_table
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for( i=0 ; i<8 ; i=i+1 ) begin
            for( j=0 ; j<34 ; j=j+1 ) begin
                match_table[i][j] <= 1'b0 ; 
            end
        end
    end
    else begin
        for( i=0 ; i<8 ; i=i+1 ) begin
            for( j=1 ; j<33 ; j=j+1 ) begin
                match_table[i][j] <= is_equivalent[i][j] ;
            end
        end
        // left-most 
        for( i=0 ; i<8 ; i=i+1 ) begin
            if (i>(8-lnth_ptn)) match_table[i][0] <= 1'b0 ;
            else                match_table[i][0] <= is_equivalent[i][0] ;
        end
        // right-most 
        for( i=0 ; i<8 ; i=i+1 ) begin
            //if (i<(lnth_ptn-1)) match_table[i][33] <= 1'b0 ;
            if (i<7) match_table[i][33] <= 1'b0 ;
            else                match_table[i][33] <= is_equivalent[i][33] ;
        end
    end
end
//================================================================
//  Handle The Fucking Annoying *
//================================================================
// is_star
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     is_star <= 1'b0 ;
    else begin
        if (out_valid==1'b1)    is_star <= 1'b0 ;
        else if (ispattern==1'b1 & chardata==CHR_ANYML)    is_star <= 1'b1 ;
    end
end

// pos_star
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     pos_star <= 4'd8;
    else begin
        if (ispattern==1'b1 & chardata==CHR_ANYML)
            pos_star <= pos_star - 1 ;
        else if (ispattern==1'b1 & is_star==1'b1)
            pos_star <= pos_star - 1 ;
        else if (out_valid==1'b1)
            pos_star <= 4'd8 ;
    end
end
//================================================================
//  INPUT
//================================================================
// f_isstring
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     f_isstring <= 1'b0 ;
    else begin
        if (isstring==1'b1) f_isstring <= 1'b1 ;
        else    f_isstring <= 1'b0 ;
    end
end

// string : using shift register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        String[33] <= CHR_ENDIN ;
        for( i=0 ; i<33 ; i=i+1 ) 
            String[i] <= CHR_NOTHN ;
    end
    else begin
        String[33] <= CHR_ENDIN ;
        if (isstring==1'b1) begin
        	if (f_isstring==1'b0) begin
        		// reset CHR_START
            	String[31] <= CHR_START ;
            	// input the newest one
            	String[32] <= chardata ;
           	 	// reset :  only when isstring==1'b1 & f_isstring==1'b0,
            	//          which is when the 1st string char is inputted
        		for( i=0 ; i<31 ; i=i+1 )
                    String[i] <= CHR_NOTHN ;
        	end
        	else begin
            	// input the newest one        	
            	String[32] <= chardata ;
        		// shift register
        		for( i=31 ; i>=0 ; i=i-1 )
                    String[i] <= String[i+1] ;
        	end
        end
   end
end


// head_str
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     head_str <= 6'd32 ;
    else begin
        if (isstring==1'b1) begin
            if (f_isstring==1'b1)   head_str <= head_str - 1 ;
            // reset :  only when isstring==1'b1 & f_isstring==1'b1,
            //          which is when the 1st string char is inputted
            else    head_str <= 6'd32 ;
        end
    end
end

// f_ispattern
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     f_ispattern <= 1'b0 ;
    else            f_ispattern <= ispattern ;
end

// Pattern : using shift register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for( i=0 ; i<8 ; i=i+1 )
            Pattern[i] <= CHR_MATCH ;	
    end
    else begin
        if (ispattern==1'b1) begin
            // input the newest one
            Pattern[7] <= chardata ;
            // shift register
            for( i=6 ; i>=0 ; i=i-1 )
                Pattern[i] <= Pattern[i+1] ;
        end
        // reset
        else if (out_valid==1'b1) begin
            for( i=0 ; i<8 ; i=i+1 )
                Pattern[i] <= CHR_MATCH ;	
        end
    end
end

// lnth_ptn
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     lnth_ptn <= 0 ;
    else begin
        if (ispattern==1'b1)        lnth_ptn <= lnth_ptn + 1 ;
        // reset
        else if (out_valid==1'b1)   lnth_ptn <= 0 ;
    end
end

endmodule

//================================================================
//  SUB MODULE
//================================================================
module Is_EQ(str, ptn, out);
input [7:0] str, ptn;
output reg out;

// Special charaters
parameter CHR_START = 8'h5E ;   // ^ : starting position of the string or 'space' would match
parameter CHR_ENDIN = 8'h24 ;   // $ : ending position of the string or 'space' would match
parameter CHR_ANYSG = 8'h2E ;   // . : any of a single charater would match
parameter CHR_ANYML = 8'h2A ;   // * : any of multiple characters would match
parameter CHR_SPACE = 8'h20 ;   //   : space
parameter CHR_NOTHN = 8'h00 ;   // my own definition, used in string
parameter CHR_MATCH = 8'h01 ;   // my own definition, used in pattern

always @(*) begin
    if (str==ptn)               out <= 1'b1 ;
    else if (ptn==CHR_MATCH)	out <= 1'b1 ;	
    else if (ptn==CHR_NOTHN)    out <= 1'b1 ;
    else if (ptn==CHR_START & str==CHR_SPACE)   out <= 1'b1 ;
    else if (ptn==CHR_ENDIN & str==CHR_SPACE)   out <= 1'b1 ;
    else if (ptn==CHR_ANYSG) begin
        if (str==CHR_START)         out <= 1'b0 ;
        else if (str==CHR_ENDIN)    out <= 1'b0 ;
        else if (str==CHR_NOTHN)	out <= 1'b0 ;	
        else    out <= 1'b1 ;
    end
    else if (ptn==CHR_ANYML) begin
        if (str==CHR_NOTHN)         out <= 1'b0 ;
        else    out <= 1'b1 ;
    end
    else        out <= 1'b0 ;
end

endmodule