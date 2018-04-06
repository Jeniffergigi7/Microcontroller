`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/04/2018 02:15:21 PM
// Design Name: 
// Module Name: microprocessor_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module microprocessor_tb(
    );
    
    reg clock, reset;
    wire [7:0] R0, R1, R2, R3, RHi, RLo;
    wire [7:0] PC, IR, rom_address;
    wire [7:0] rom_data;
    wire [7:0] ram_address, ram_data_in;
    wire [7:0] ram_data_out;
    wire ram_write;
    wire [5:0] state;
    
    microprocessor_final microprocessor_UUT(clock, reset, R0, R1, R2, R3, RHi, RLo, PC, IR, rom_address, rom_data, ram_address,
    ram_data_out, ram_data_in, ram_write, state);
    
    initial begin
    reset = 0; clock = 0; #3;
    reset = 1; #2;
    reset = 0;
    repeat (80) begin
    clock = ~clock; #5;
    end
    $finish;
    end
    
endmodule
