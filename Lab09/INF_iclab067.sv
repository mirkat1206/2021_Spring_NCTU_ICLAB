//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Lab09		 : Happy Farm (HF)
//   Author    	 : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : INF.sv
//   Module Name : INF
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################ 

interface INF(input clk);
	import      usertype::*;
	logic 	rst_n ; 
	logic   act_valid;
	logic   id_valid;
	logic   cat_valid;
	logic   amnt_valid;
	DATA  	D;
	
	logic   	out_valid;
	logic 		complete;
	Error_Msg 	err_msg;
	logic[31:0] out_deposit;
	logic[31:0] out_info;
	
	logic [7:0]  C_addr;
	logic [31:0] C_data_w;
	logic [31:0] C_data_r;
	logic C_in_valid;
	logic C_out_valid;
	logic C_r_wb;
	
	logic   AR_READY, R_VALID, AW_READY, W_READY, B_VALID,
	        AR_VALID, R_READY, AW_VALID, W_VALID, B_READY;
	logic [1:0]	 R_RESP, B_RESP;
    logic [31:0] R_DATA, W_DATA;
	logic [16:0] AW_ADDR, AR_ADDR;

    modport PATTERN(
        // Global Signal
        output rst_n,
        // Output : Player(Pattern.sv) to Farm System(farm.sv)
        output id_valid,
        output act_valid,
        output cat_valid,
        output amnt_valid,
        output D,
        // Input : Farm System(farm.sv) to Player(Pattern.sv)
        input out_valid,
        input err_msg,
        input complete,
        input out_info,
        input out_deposit
    );
	
    modport DRAM(
        // Global Signal
        input rst_n,
        // Output : DRAM to AXI Bridge(bridge.sv)
        output AR_READY,
        output R_VALID,
        output R_DATA,
        output R_RESP,
        output AW_READY,
        output W_READY,
        output B_VALID,
        output B_RESP,
        // Input : AXI Bridge(bridge.sv) to DRAM
        input AR_VALID,
        input AR_ADDR,
        input R_READY,
        input AW_VALID,
        input AW_ADDR,
        input W_VALID,
        input W_DATA,
        input B_READY
    );
	
    modport farm_inf(
    	// Global Signal
    	input rst_n,
    	// Input : Player(Pattern.sv) to Farm System(farm.sv)
    	input id_valid,
    	input act_valid,
    	input cat_valid,
    	input amnt_valid,
    	input D,
    	// Output : Farm System(farm.sv) to Player(Pattern.sv)
    	output out_valid,
    	output err_msg,
    	output complete,
    	output out_info,
    	output out_deposit,
    	// Input : AXI Bridge(bridge.sv) to Farm System(farm.sv)
    	input C_out_valid,
    	input C_data_r,
    	// Output : Farm System(farm.sv) to AXI Bridge(bridge.sv)
    	output C_addr,
    	output C_data_w,
    	output C_in_valid,
    	output C_r_wb
	);
		
    modport bridge_inf(
    	// Global Signal
    	input rst_n,
    	// Input : Farm System(farm.sv) to AXI Bridge(bridge.sv)
    	input C_addr,
    	input C_data_w,
    	input C_in_valid,
    	input C_r_wb,
    	// Output : AXI Bridge(bridge.sv) to Farm System(farm.sv)
    	output C_out_valid,
    	output C_data_r,
    	// Input : DRAM to AXI Bridge(bridge.sv)
    	input AR_READY,
    	input R_VALID,
    	input R_DATA,
    	input R_RESP,
    	input AW_READY,
    	input W_READY,
    	input B_VALID,
    	input B_RESP,
    	// Output : AXI Bridge(bridge.sv) to DRAM
    	output AR_VALID,
    	output AR_ADDR,
    	output R_READY,
    	output AW_VALID,
    	output AW_ADDR,
    	output W_VALID,
    	output W_DATA,
    	output B_READY
    );
	
	modport PATTERN_farm(
		output rst_n,
	    output id_valid,
	    output act_valid,
	    output cat_valid,
	    output amnt_valid,
	    output D,
	    output C_out_valid,
	    output C_data_r,

	    input out_valid,
	    input err_msg,
	    input complete,
	    input out_info,
	    input out_deposit,
	    input C_addr,
	    input C_data_w,
	    input C_in_valid,
	    input C_r_wb
    );

	modport PATTERN_bridge(  
    	// Global Signal
        output rst_n,
        // Input : Farm System(farm.sv) to AXI Bridge(bridge.sv)
        output C_addr,
        output C_data_w,
        output C_in_valid,
        output C_r_wb,
        // Output : AXI Bridge(bridge.sv) to Farm System(farm.sv)
        input C_out_valid,
        input C_data_r,
        // Input : DRAM to AXI Bridge(bridge.sv)
        output AR_READY,
        output R_VALID,
        output R_DATA,
        output R_RESP,
        output AW_READY,
        output W_READY,
        output B_VALID,
        output B_RESP,
        // Output : AXI Bridge(bridge.sv) to DRAM
        input AR_VALID,
        input AR_ADDR,
        input R_READY,
        input AW_VALID,
        input AW_ADDR,
        input W_VALID,
        input W_DATA,
        input B_READY
    );

endinterface