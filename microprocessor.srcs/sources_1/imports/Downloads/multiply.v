`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// University:
// Engineer:
// Create Date: 03/13/2018 10:03:23 AM
// Module Name: multiply

//////////////////////////////////////////////////////////////////////////////////

// Top level module
module multiply(
    input clk,
    input reset,
    input load_A,
    input load_B,
    input start,
    input [7:0] data_A,
    input [7:0] data_B,
    output [15:0] product,
    output done
    );
	
	// Wires to output from control unit into datapath
	wire EA, EB, p_sel, EP;
	
	// Wires to output from datapath into control unit
	wire B_is_Zero, B0;
	
	// Instantiation of datapath and control unit
	control_path_mul control_unit_instance(EA, EB, done, p_sel, EP, clk, reset, start, B_is_Zero, B0);
	data_path_mul data_path_instance(B_is_Zero, product, B0, EA, EB, EP, p_sel, clk, load_A, load_B, data_A, data_B, reset);
    
endmodule

// Control unit module begins here
module control_path_mul(EA, EB, Done, Psel, EP, Clock, Reset, S, Zero, b0);
    input Clock, Reset, S, Zero, b0;
    output reg EA, EB, Done, Psel, EP;
    
    parameter S1 = 2'b00, S2 = 2'b01, S3 = 2'b10;
    reg [1:0] state;
    
    // Change state on clock edge
    always @ (posedge Clock, posedge Reset) begin
        if (Reset)
            state <= S1;
        else begin
            case (state)
                S1: if (S) state <= S2;
                    else state <= S1;
                S2: if (Zero) state <= S3;
                    else state <= S2;
                S3: if (S) state <= S3;
                    else state <= S1;
                default: state <= 2'bxx;
            endcase
        end
    end
    
    // Control signal outputs
    always @ (b0, S, state) begin
        // Default values
        EA = 0; EB = 0; Done = 0; Psel = 0; EP = 0;
        case (state)
            S1: EP = 1;
            S2: begin
                Psel = 1; EA = 1; EB = 1;
                if (b0) EP = 1;
                else EP = 0;
            end
            S3: Done = 1;
        endcase
    end
    
endmodule

// Datapath module begins here
module data_path_mul(B_Equals_Zero, P, LSB_B, ShiftA, ShiftB, EnableP, ChooseP, Clock, LA, LB, DataA, DataB, Reset);
    input LA, LB, ShiftA, ShiftB, Clock, ChooseP, EnableP, Reset;
    input [7:0] DataA, DataB;
    output reg [15:0] P;
	output B_Equals_Zero, LSB_B;
    
    reg [15:0] RegA;
	reg [7:0] RegB;
	
	wire [15:0] Sum, DataP;
    
    // Shift Register A
    always @ (posedge Clock) begin
        if (ShiftA) RegA <= RegA << 1;
        else if (LA) RegA <= {8'b0, DataA};
        else RegA <= RegA;
    end
    
    // Shift Register B
    always @ (posedge Clock) begin
        if (ShiftB) RegB <= RegB >> 1;
        else if (LB) RegB <= DataB;
        else RegB <= RegB;
    end
	
	// Register to store and output the product, P
	always @ (posedge Clock) begin
		if (EnableP) P <= DataP;
		else P <= P;
	end
	
	// 2-to-1 mux for putting proper values into register P
	assign DataP = ChooseP ? Sum : 16'b0;
	
	// Status signals to be sent to control unit
	assign Sum = RegA + P;
	assign B_Equals_Zero = (RegB == 0);
	assign LSB_B = RegB[0];
    
endmodule