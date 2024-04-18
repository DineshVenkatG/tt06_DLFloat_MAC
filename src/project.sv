/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none


module tt_um_dlfloatmac (

    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

wire [15:0]data_in;
wire [15:0] c;
wire [15:0]wa,wb;
wire write_en;

assign uio_oe  = write_en?8'b11111111:8'b00000000;

assign en=1;
assign data_in = {uio_in,ui_in};


reg_wrapper wrap(clk,rst_n,data_in,wa,wb,write_en);
dlfloat_mac MAC(clk,wa,wb,c);


assign uio_out = c[15:8];
assign uo_out = c[7:0];
  // All output pins must be assigned. If not used, assign to 0.
  //assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  
endmodule


////////reg_wrapper//////////


module reg_wrapper(
    input clk,
    input rst,
    input [15:0] data_in,
    output reg [15:0] reg_a,
    output reg [15:0] reg_b,
    output reg write_en
);

reg [1:0] state;
reg [15:0] temp_data;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        state <= 2'b00; // Initialize state machine
        reg_a <= 16'b0; // Initialize registers
        reg_b <= 16'b0;
        write_en = 0;
    end
    else begin
        case (state)
            2'b00: begin
                temp_data <= data_in;
//                reg_a <= data_in;
                state <= 2'b01;
            end
            2'b01: begin
                reg_a <= temp_data;
                reg_b <= data_in;
                write_en <= 1;
                state <= 2'b00;
            end
            default: state <= 2'b00; // Reset state to default
        endcase
    end
end



endmodule





///////mac/////////

module dlfloat_mac(clk,a,b,c);
    input [15:0]a,b;
    input clk;
    output bit[15:0]c;

    reg [15:0]data_a,data_b;
    wire [15:0]fprod,fadd;
    //dlfloat_mult(a,b,c,clk);
    //dlfloat_adder(input clk, input [15:0]a, input [15:0]b, output reg [15:0]c);
    always @(posedge clk)
    begin 
        data_a <= a;
        data_b <= b;
        //fprod1 <= fprod;
       // c <= fadd;
    end 
    always@(posedge clk)
    begin 
        c <= fadd;
     end 
    dlfloat_mult mul(data_a,data_b,fprod,clk);
    dlfloat_adder add(clk,fprod,c,fadd);

    
    //assign c = fadd;
endmodule 



/////////////// mult ///////////////

module dlfloat_mult(a,b,c,clk);
    input [15:0]a,b;
    input clk;
    output  reg [15:0]c;
    
    reg [9:0]ma,mb; //1 extra because 1.smthng
    reg [8:0] mant;
    reg [19:0]m_temp; //after multiplication
    reg [5:0] ea,eb,e_temp,exp;
    reg sa,sb,s;
    reg [16:0] temp; //1 extra bit ??
    //reg [6:0] exp_adjust; //why ??

   


    always @(posedge clk)
    begin 
        ma ={1'b1,a[8:0]};
        mb= {1'b1,b[8:0]};
        sa = a[15];
        sb = b[15];
        ea = a[14:9];
        eb = b[14:9];

        e_temp = ea + eb - 31;
        m_temp = ma * mb;

        mant = m_temp[19] ? m_temp[18:10] : m_temp[17:9];
        exp = m_temp[19] ? e_temp+1'b1 : e_temp;

        s=sa ^ sb;

       c =(a==0|b==0)?0:{s,exp,mant};
    end 
endmodule 


////////////adder//////////////

module dlfloat_adder(input clk, input [15:0]a, input [15:0]b, output reg [15:0]c);
    
    reg    [15:0] Num_shift_80; 
    reg    [5:0]  Larger_exp_80,Final_expo_80;
    reg    [8:0] Small_exp_mantissa_80,S_mantissa_80,L_mantissa_80,Large_mantissa_80,Final_mant_80;
    reg    [9:0] Add_mant_80,Add1_mant_80;
    reg    [5:0]  e1_80,e2_80;
    reg    [8:0] m1_80,m2_80;
    reg          s1_80,s2_80,Final_sign_80;
    reg    [3:0]  renorm_shift_80;
    integer signed   renorm_exp_80;
    //reg           renorm_exp_80;
    reg    [15:0] c_80;


//    always @(posedge clk)
//    begin
//        c<= c_80;
//    end
    assign c = c_80;
    


    always @(*) begin
        //stage 1
	e1_80 = a[14:9];
	e2_80 = b[14:9];
        m1_80 = a[8:0];
	m2_80 = b[8:0];
	s1_80 = a[15];
	s2_80 = b[15];
        
        if (e1_80  > e2_80) begin
            Num_shift_80           = e1_80 - e2_80;              // number of mantissa shift
            Larger_exp_80           = e1_80;                     // store lower exponent
            Small_exp_mantissa_80  = m2_80;
            Large_mantissa_80      = m1_80;
        end
        
        else begin
            Num_shift_80           = e2_80 - e1_80;
            Larger_exp_80           = e2_80;
            Small_exp_mantissa_80  = m1_80;
            Large_mantissa_80      = m2_80;
        end

	if (e1_80 == 0 | e2_80 ==0) begin
	    Num_shift_80 = 0;
	end
	else begin
	    Num_shift_80 = Num_shift_80;
	end
	
	
        
        //stage 2
        //if check both for normalization then append 1 and shift
	if (e1_80 != 0) begin
            Small_exp_mantissa_80  = {1'b1,Small_exp_mantissa_80[8:1]};
	    Small_exp_mantissa_80  = (Small_exp_mantissa_80 >> Num_shift_80);
        end
	else begin
	    Small_exp_mantissa_80 = Small_exp_mantissa_80;
	end

	if (e2_80!= 0) begin
            Large_mantissa_80      = {1'b1,Large_mantissa_80[8:1]};
	end
	else begin
	    Large_mantissa_80 = Large_mantissa_80;
	end

        	//else do what to do for denorm field
			

        //stage 3
                                                    //check if exponent are equal
            if (Small_exp_mantissa_80  < Large_mantissa_80) begin
                //Small_exp_mantissa_80 = ((~ Small_exp_mantissa_80 ) + 1'b1);
		//$display("what small_exp:%b",Small_exp_mantissa_80);
		S_mantissa_80 = Small_exp_mantissa_80;
		L_mantissa_80 = Large_mantissa_80;
            end
            else begin
                //Large_mantissa_80 = ((~ Large_mantissa_80 ) + 1'b1);
		//$display("what large_exp:%b",Large_mantissa_80);
			
		S_mantissa_80 = Large_mantissa_80;
		L_mantissa_80 = Small_exp_mantissa_80;
             end       
        //stage 4
        //add the two mantissa's
	
	if (e1_80!=0 & e2_80!=0) begin
		if (s1_80 == s2_80) begin
        		Add_mant_80 = S_mantissa_80 + L_mantissa_80;
		end else begin
			Add_mant_80 = L_mantissa_80 - S_mantissa_80;
		end
	end	
	else begin
		Add_mant_80 = L_mantissa_80;
	end
         
	//renormalization for mantissa and exponent
	

	//stage 5
	// if e1==e2, no shift for exp
        Final_expo_80 =  Larger_exp_80 + renorm_exp_80;
	
	Add1_mant_80 = Add_mant_80 << renorm_shift_80;

	Final_mant_80 = Add1_mant_80[9:1];  	

        
	if (s1_80 == s2_80) begin
		Final_sign_80 = s1_80;
	end 

	if (e1_80 > e2_80) begin
		Final_sign_80 = s1_80;	
	end else if (e2_80 > e1_80) begin
		Final_sign_80 = s2_80;
	end
	else begin

		if (m1_80 > m2_80) begin
			Final_sign_80 = s1_80;		
		end else begin
			Final_sign_80 = s2_80;
		end
	end	
	
	c_80 = (a==0 & b==0)?0:{Final_sign_80,Final_expo_80,Final_mant_80};
    end
    
    always @(posedge clk)begin 
    if (Add_mant_80[9] ) begin
		renorm_shift_80 = 4'd1;
		renorm_exp_80 = 4'd1;
	end
	else if (Add_mant_80[8])begin
		renorm_shift_80 = 4'd2;
		renorm_exp_80 = 0;		
	end
	else if (Add_mant_80[7])begin
		renorm_shift_80 = 4'd3; 
		renorm_exp_80 = -1;
	end 
	else if (Add_mant_80[6])begin
		renorm_shift_80 = 4'd4; 
		renorm_exp_80 = -2;		
	end  
	else if (Add_mant_80[5])begin
		renorm_shift_80 = 4'd5; 
		renorm_exp_80 = -3;		
	end      
	end 
    
    
//    always @(posedge clk) begin
//            if(reset) begin
//                Num_shift_80 <= #1 0;
//            end
//    end
    
endmodule
