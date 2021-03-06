`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// update
// Create Date: 04/04/2018 01:30:09 PM
// Design Name: 
// Module Name: microprocessor_final
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


module microprocessor_final(clock, reset, R0, R1, R2, R3, RHi, RLo, PC, IR, rom_address, rom_data, ram_address,
ram_data_out, ram_data_in, ram_write, state);
    
    input clock, reset;
    output reg [7:0] R0, R1, R2, R3;
    output [7:0] RHi, RLo;
    output reg [7:0] PC, IR, rom_address;
    output [7:0] rom_data;
    output reg [7:0] ram_address, ram_data_in;
    output [7:0] ram_data_out;
    output reg ram_write;
    output reg [5:0] state;
    
    // Instantiate RAM
    blk_mem_RAM RAM_1 (
      .clka(clock),    // input wire clka
      .wea(ram_write),      // input wire [0 : 0] wea
      .addra(ram_address),  // input wire [7 : 0] addra
      .dina(ram_data_in),    // input wire [7 : 0] dina
      .douta(ram_data_out)  // output wire [7 : 0] douta
    );
    
    // Instantiate ROM
    blk_mem_ROM ROM_1 (
      .clka(clock),    // input wire clka
      .addra(rom_address),  // input wire [7 : 0] addra
      .douta(rom_data)  // output wire [7 : 0] douta
    );
    
    // Instantiate wires/regs needed for multiplier
    reg [7:0] Rx, Ry;
    wire MUL_done;
    reg start_MUL;
    
    // Instantiate multiplier circuit
    multiply multiplier_1(
        .clk(clock),
        .reset(reset),
        .load_A(1'b1),
        .load_B(1'b1),
        .start(start_MUL),
        .data_A(Rx),
        .data_B(Ry),
        .product({RHi, RLo}),
        .done(MUL_done)
        );
    
    parameter   reset_cpu = 6'd0,
                fetch = 6'd1,
                decode = 6'd2,
                execute_NOP = 6'd3,
                execute_ADD = 6'd4,
                execute_SUB = 6'd5,
                execute_NOT = 6'd6,
                execute_AND = 6'd7,
                execute_OR = 6'd8,
                execute_MUL = 6'd30,
                execute_MUL2 = 6'd31,
                
                // Move data between registers
                execute_MOV_RStoRD = 6'd9,
                
                // Ram write: M[address} <- RS
                execute_MOV_RStoM = 6'd10,
                execute_MOV_RStoM2 = 6'd11,
                execute_MOV_RStoM3 = 6'd12,
                
                // Move a constant into a register R0 through R3
                execute_MOV_DatatoRD = 6'd13,
                execute_MOV_DatatoRD2 = 6'd14,
                
                // Ram read: RD <- M[address]
                execute_MOV_MtoRD = 6'd15,
                execute_MOV_MtoRD2 = 6'd16,
                execute_MOV_MtoRD3 = 6'd17,
                execute_MOV_MtoRD4 = 6'd18,
                //execute_MOV_MtoRD5 = 6'd19, // Unneeded state, optimized to 4 states
                
                // Ram write: M[address] <- RHi & M[address + 1] <- RLo
                execute_MOV_RHiRLotoM = 6'd25,
                execute_MOV_RHiRLotoM2 = 6'd26,
                execute_MOV_RHiRLotoM3 = 6'd27,
                execute_MOV_RHiRLotoM4 = 6'd28,
                
                // JMP and JNZ
                execute_JMP = 6'd20,
                execute_JMP1 = 6'd21,
                execute_JMP2 = 6'd22,
                execute_JMP3 = 6'd23,
                execute_JNZ = 6'd24;
                
    always @ (posedge clock, posedge reset) begin
        if (reset) begin
            R0 <= 0; R1 <= 0; R2 <= 0; R3 <= 0;
            //RHi <= 0; RLo <= 0;
            rom_address <= 0;
            ram_address <= 0;
            ram_write <= 0;
            PC <= 0;
            state <= reset_cpu;
        end
        else begin
            case (state)
            reset_cpu: begin // Reset all registers when reset button is pressed
                R0 <= 0; R1 <= 0; R2 <= 0; R3 <= 0;
                //RHi <= 0; RLo <= 0;
                rom_address <= 0;
                ram_address <= 0;
                ram_write <= 0;
                PC <= 0;
                state <= fetch;
            end
            
            /////////////////////////////////////////////////////////////////////
            
            fetch: begin // Retrieve instruction from ROM
                IR <= rom_data;
                PC <= PC + 1; // Increment to either next instruction or operand
                state <= decode;
            end
            
            /////////////////////////////////////////////////////////////////////
            
            decode: begin // Determine which operation to execute
                rom_address <= PC; // With rom_data stored in IR, new rom_address can be pointed to
                case (IR[7:4])
                    // One-byte instruction
                    4'h0: state <= execute_NOP;
                    4'h1: state <= execute_ADD;
                    4'h2: state <= execute_SUB;
                    4'h3: state <= execute_NOT;
                    4'h4: state <= execute_AND;
                    4'h5: state <= execute_OR;
                    4'h6: state <= execute_MOV_RStoRD;
   
                    // Two-byte instruction
                    4'h7: begin
                        state = execute_MOV_RStoM;
                        PC <= PC + 1; // Increment PC to next instruction, but rom_address is left pointing to operand
                                      // Perform this step on all 2-byte instructions
                        end
                    4'h8: begin
                        state <= execute_MOV_DatatoRD; 
                        PC <= PC + 1; 
                        end
                    4'h9: begin
                        state <= execute_MOV_MtoRD;
                        PC <= PC + 1;
                        end
                    4'hA: begin
                        state <= execute_JMP;
                        PC <= PC +1;
                        end 
                    4'hB: begin
                        state <= execute_JNZ;
                        PC <= PC + 1;
                        end
                    4'hC: state <= execute_MUL; // One-byte instruction
                    4'hE: begin
                        state <= execute_MOV_RHiRLotoM;
                        PC <= PC + 1;
                    end
                    default: state <= execute_NOP;
                endcase
            end
            
            /////////////////////////////////////////////////////////////////////
            
            execute_NOP: begin // Perform no operations (Operation 0000 or 0)
                rom_address <= PC; // Make ROM data available on next clock cycle in fetch state
                state <= fetch;
            end
            
            ////////////////////////////////////////////////////////////////////
            
            // Perform an addition between registers (Operation 0001 or 1)
            execute_ADD: begin
                rom_address <= PC;
                case(IR[3:0])
                    0: R0 <= R0 + R0;
                    1: R0 <= R0 + R1;
                    2: R0 <= R0 + R2;
                    3: R0 <= R0 + R3;
                    4: R1 <= R1 + R0;
                    5: R1 <= R1 + R1;
                    6: R1 <= R1 + R2;
                    7: R1 <= R1 + R3;
                    8: R2 <= R2 + R0;
                    9: R2 <= R2 + R1;
                    10: R2 <= R2 + R2;
                    11: R2 <= R2 + R3;
                    12: R3 <= R3 + R0;
                    13: R3 <= R3 + R1;
                    14: R3 <= R3 + R2;
                    15: R3 <= R3 + R3;
                    default: begin R0 <= R0; R1 <= R1; R2 <= R2; R3 <=R3; end
                endcase
                state <= fetch;
            end
                
            /////////////////////////////////////////////////////////////////// 
               
            // Perform a subtraction between registers (Operation 0010 or 2)
            execute_SUB: begin
                rom_address <= PC;
                case(IR[3:0]) 
                    0: R0 <= R0 - R0;
                    1: R0 <= R0 - R1;
                    2: R0 <= R0 - R2;
                    3: R0 <= R0 - R3;
                    4: R1 <= R1 - R0;
                    5: R1 <= R1 - R1;
                    6: R1 <= R1 - R2;
                    7: R1 <= R1 - R3;
                    8: R2 <= R2 - R0;
                    9: R2 <= R2 - R1;
                    10: R2 <= R2 - R2;
                    11: R2 <= R2 - R3;
                    12: R3 <= R3 - R0;
                    13: R3 <= R3 - R1;
                    14: R3 <= R3 - R2;
                    15: R3 <= R3 - R3;
                    default: begin R0 <= R0; R1 <= R1; R2 <= R2; R3 <=R3; end
                endcase
                state <= fetch;
            end
                
            //////////////////////////////////////////////////////////////////////
            
            // Perform a not operation (Operation 0011 or 3)
            execute_NOT: begin
            rom_address <= PC;
                case(IR[3:0])
                    0: R0 <= ~R0;
                    1: R0 <= ~R1;
                    2: R0 <= ~R2;
                    3: R0 <= ~R3;
                    4: R1 <= ~R0;
                    5: R1 <= ~R1;
                    6: R1 <= ~R2;
                    7: R1 <= ~R3;
                    8: R2 <= ~R0;
                    9: R2 <= ~R1;
                    10: R2 <= ~R2;
                    11: R2 <= ~R3;
                    12: R3 <= ~R0;
                    13: R3 <= ~R1;
                    14: R3 <= ~R2;
                    15: R3 <= ~R3;
                    default: begin R0 <= R0; R1 <= R1; R2 <= R2; R3 <=R3; end
                endcase
                state <= fetch;
            end
                
            /////////////////////////////////////////////////////////////////////////
            
            // Perform AND operation between registers (Operation 0100 or 4)
            execute_AND: begin
                rom_address <= PC;
                case(IR[3:0]) 
                    0: R0 <= R0 & R0;
                    1: R0 <= R0 & R1;
                    2: R0 <= R0 & R2;
                    3: R0 <= R0 & R3;
                    4: R1 <= R1 & R0;
                    5: R1 <= R1 & R1;
                    6: R1 <= R1 & R2;
                    7: R1 <= R1 & R3;
                    8: R2 <= R2 & R0;
                    9: R2 <= R2 & R1;
                    10: R2 <= R2 & R2;
                    11: R2 <= R2 & R3;
                    12: R3 <= R3 & R0;
                    13: R3 <= R3 & R1;
                    14: R3 <= R3 & R2;
                    15: R3 <= R3 & R3;
                    default: begin R0 <= R0; R1 <= R1; R2 <= R2; R3 <=R3; end
                endcase
                state <= fetch;
            end
                
            /////////////////////////////////////////////////////////////////////////
                
            // Perform OR operation between registers (Operation 0101 or 5)
            execute_OR: begin
                rom_address <= PC;
                case(IR[3:0]) 
                    0: R0 <= R0 | R0;
                    1: R0 <= R0 | R1;
                    2: R0 <= R0 | R2;
                    3: R0 <= R0 | R3;
                    4: R1 <= R1 | R0;
                    5: R1 <= R1 | R1;
                    6: R1 <= R1 | R2;
                    7: R1 <= R1 | R3;
                    8: R2 <= R2 | R0;
                    9: R2 <= R2 | R1;
                    10: R2 <= R2 | R2;
                    11: R2 <= R2 | R3;
                    12: R3 <= R3 | R0;
                    13: R3 <= R3 | R1;
                    14: R3 <= R3 | R2;
                    15: R3 <= R3 | R3;
                    default: begin R0 <= R0; R1 <= R1; R2 <= R2; R3 <=R3; end
                endcase
                state <= fetch;
            end
                
            //////////////////////////////////////////////////////////////////////
                
            // Move data from one register to another (Operation 0110 or 6)
            execute_MOV_RStoRD: begin
                case (IR[3:0])
                    4'b0000: R0 <= R0;
                    4'b0001: R0 <= R1;
                    4'b0010: R0 <= R2;
                    4'b0011: R0 <= R3;
                    4'b0100: R1 <= R0;
                    4'b0101: R1 <= R1;
                    4'b0110: R1 <= R2;
                    4'b0111: R1 <= R3;
                    4'b1000: R2 <= R0;
                    4'b1001: R2 <= R1;
                    4'b1010: R2 <= R2;
                    4'b1011: R2 <= R3;
                    4'b1100: R3 <= R0;
                    4'b1101: R3 <= R1;
                    4'b1110: R3 <= R2;
                    4'b1111: R3 <= R3;
                    default: begin R0 <= R0; R1 <= R1; R2 <= R2; R3 <= R3; end
                endcase
                state <= fetch;
            end
            
            /////////////////////////////////////////////////////////////////////
                
            // Move value from the registers to the RAM (Operation 0111 or 7)
            execute_MOV_RStoM: 
                begin
                    state <= execute_MOV_RStoM2;
                end
              
            execute_MOV_RStoM2:
                begin
                    ram_address <= rom_data;
                    ram_write <= 1;
                    rom_address <= PC;
                    state <= execute_MOV_RStoM3;
                    case(IR[1:0])
                        0: ram_data_in <= R0;
                        1: ram_data_in <= R1;
                        2: ram_data_in <= R2;
                        3: ram_data_in <= R3;
                        default: ram_data_in <= ram_data_in;
                    endcase
                end
            
            execute_MOV_RStoM3:
                begin
                    ram_write <= 0;
                    state <= fetch;
                end
                
            /////////////////////////////////////////////////////////////////////////
            
            // Moves a constant into a register R0 through R3 (Operation 1000 or 8)
            execute_MOV_DatatoRD: begin
                rom_address <= PC; // rom_address updated for next fetch state
                                   // In next clock cycle, rom_address will be updated
                                   // rom_data won't update until positive clock edge
                                   // with new rom_address which changes to fetch state
                                   // Thus operand rom_data is available in next state
                state <= execute_MOV_DatatoRD2;
            end
            
            execute_MOV_DatatoRD2: begin // Store a constant to a register R0 through R3
                case(IR[1:0])
                    0: R0 <= rom_data;
                    1: R1 <= rom_data;
                    2: R2 <= rom_data;
                    3: R3 <= rom_data;
                    default: begin R0 <= R0; R1 <= R1; R2 <= R2; R3 <= R3; end
                endcase
                state <= fetch;
            end
                
            //////////////////////////////////////////////////////////////////////////////
            
            // Move data from memory into a register (Operation 1001 or 9)
            execute_MOV_MtoRD: begin
                state <= execute_MOV_MtoRD2;
                // Need to wait one clock cycle
                // In last state (decode) rom_address was updated to point to operand
                // so we must wait for clock with new rom_address effective to update
                // rom_data which is used to point to a new ram_address
            end
            
            execute_MOV_MtoRD2: begin
                ram_address <= rom_data; // With operand address being pointed to, retrieve data from RAM
                rom_address <= PC; // With ram_address being updated correctly, get rom_address ready for next fetch instruction
                state <= execute_MOV_MtoRD3;
            end
            
            execute_MOV_MtoRD3: begin // Need to wait one clock cycle for ram_address
                                      // to update ram_data_out
                state <= execute_MOV_MtoRD4;
            end
            
            execute_MOV_MtoRD4: begin
                case (IR[1:0])
                    2'b00: R0 <= ram_data_out;
                    2'b01: R1 <= ram_data_out;
                    2'b10: R2 <= ram_data_out;
                    2'b11: R3 <= ram_data_out;
                    default: begin R0 <= R0; R1 <= R1; R2 <= R2; R3 <= R3; end
                endcase
                state <= fetch;
            end
            
            ////////////////////////////////////////////////////////////////////////
                
            // Jump data from memory into a register (Operation 1010 or A)
            execute_JMP:                   
                state <= execute_JMP1;
                
            execute_JMP1: begin
                PC <= rom_data;
                state <= execute_JMP2;
            end 
                
            execute_JMP2: begin
                rom_address <= PC;
                state <= execute_JMP3;
            end
                
            execute_JMP3: 
                state <= fetch;
                
            ////////////////////////////////////////////////////////////////////////
            
            // Jump to different instruction if R0 != 0 (Operation 1011 or B)
            execute_JNZ:                 
                if (R0 != 8'b0)  state <= execute_JMP1;
                else state <= execute_JMP2;
                
            ////////////////////////////////////////////////////////////////////////
            
            // Performs multiplication between 2 registers and stores
            // result in RHi and RLo (Operation 1100 or C)
            execute_MUL: begin
                rom_address <= PC; // Prepare rom_address and rom_data for next fetch
                start_MUL <= 0; // Return multiplier to 1st state to reset RHi and RLo
                                // and then load in new values to be multiplied
                
                case (IR[3:2]) // Assign first number to be passed into multiplier
                    0: Rx <= R0;
                    1: Rx <= R1;
                    2: Rx <= R2;
                    3: Rx <= R3;
                endcase
                
                case (IR[1:0]) // Assign second number to be passed into multiplier
                    0: Ry <= R0;
                    1: Ry <= R1;
                    2: Ry <= R2;
                    3: Ry <= R3;
                endcase
                state <= execute_MUL2;
            end
            
            execute_MUL2: begin
                start_MUL <= 1; // Start will be set to one at clock edge
                                // Multiplier registers are simultaneously loaded
                                // Subsequent clock edge will move into shifting operations
                                // to perform multiplication
                                // Leaving start on will not affect operation of multiplier
                                // while in shifting and done states so it can be left on
                                
                case (MUL_done)
                    0: state <= execute_MUL2;
                    1: state <= fetch;
                endcase
            end
            
            ////////////////////////////////////////////////////////////////////////
            
            // Stores result from multiplication operation to RAM (Operation 1110 or E)
            execute_MOV_RHiRLotoM: begin
                state <= execute_MOV_RHiRLotoM2; // Need to wait for updated rom_address from last cycle
                                                 // to get new rom_data
            end
                
            execute_MOV_RHiRLotoM2: begin
                rom_address <= PC; // Get rom_address ready for next fetch instruction
                ram_address <= rom_data; // Set ram_address to operand prior to rom_address pulling new data
                ram_data_in <= RHi; // RAM data in wire set to RHi after clock edge
                ram_write <= 1; // RAM set to write after clock edge; new data won't be written until next clock edge
                state <= execute_MOV_RHiRLotoM3;
            end
            
            execute_MOV_RHiRLotoM3: begin
                // RHi is written into RAM on this clock cycle as below is updated
                ram_data_in <= RLo; // RAM data input updated to RLo after this clock edge
                ram_address <= ram_address + 1; // RLo will be written into next RAM location on next clock
                state <= execute_MOV_RHiRLotoM4;
            end
            
            execute_MOV_RHiRLotoM4: begin
                // Next memory location has RLo written in before turning off ram_write
                ram_write <= 0;
                state <= fetch;
            end
                
            ///////////////////////////////////////////////////////////////////
            
            endcase
        end
    end   
endmodule
