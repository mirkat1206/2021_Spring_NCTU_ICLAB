//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2020 ICLAB Fall Course
//   Lab09      : HF
//   Author     : Lien-Feng Hsu
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : Usertype_PKG.sv
//   Module Name : usertype
//   Release version : v1.0 (Release Date: May-2020)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifndef USERTYPE
`define USERTYPE

package usertype;

typedef enum logic  [3:0] { No_action  = 4'd0 ,
                            Seed       = 4'd1 ,
							Water      = 4'd3 ,
						    Reap       = 4'd2 , 
							Steal      = 4'd4 ,
							Check_dep  = 4'd8  
							}  Action ;
							
typedef enum logic  [3:0] { No_Err       = 4'd0 ,
                            Is_Empty     = 4'd1 ,
							Not_Empty    = 4'd2 ,
							Has_Grown    = 4'd3 ,
						    Not_Grown    = 4'd4 
							}  Error_Msg ;

typedef enum logic  [3:0] { No_cat		 = 4'd0 ,
							Potato	     = 4'd1 ,
                            Corn	     = 4'd2 , 
							Tomato       = 4'd4 ,
						    Wheat        = 4'd8   
							}  Crop_cat ;
							
typedef enum logic  [3:0] { No_sta       = 4'd1 ,
							Zer_sta      = 4'd2 ,
							Fst_sta	     = 4'd4 ,
                            Snd_sta	     = 4'd8
							}  Crop_sta ;

typedef logic [7:0]  Land;
typedef logic [15:0] Water_amnt;

typedef struct packed {
	Land  land_id, land_status;
	Water_amnt water_amnt; 
} Land_Info; 

typedef union packed{ 
    Action       [3:0] d_act;
	Land         [1:0] d_id;
	Crop_cat     [3:0] d_cat;
	Water_amnt         d_amnt;
} DATA;

//################################################## Don't revise code above

//  MODE
parameter MODE_READ  = 1'b1 ;
parameter MODE_WRITE = 1'b0 ;
//  FSM
typedef enum logic  [2:0] { S_GET_DEPOSIT = 3'd0,
							S_IDLE		= 3'd1,
							S_SAVE_LAND	= 3'd2,
							S_GET_LAND	= 3'd3,
							S_EXE1		= 3'd4,
							S_EXE2		= 3'd5,
							S_OUTPUT	= 3'd6
							}  Farm_sta ;

endpackage

import usertype::*; //import usertype into $unit

`endif

