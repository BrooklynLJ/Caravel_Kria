`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Aster Zawaideh
// 
// Create Date: 02/17/2026 03:16:02 PM
// Design Name: 
// Module Name: SM_Reg_File_Synapse_tn1
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


module SM_Reg_File_Synapse_tn1(
    input         clk,
    input         reset,
    input         enable,

    input   AP_t,       
    input  [31:0] h_t,
    input  [31:0] g_t,
    input exception_h_t,
    
    output reg        AP_tn1,         
    output reg [31:0] h_tn1,
    output reg [31:0] g_tn1,
    output reg        updated_regFile_tn1 = 1'b0,
    output reg        exception_h_tn1 = 1'b0

);

    //updating the values in the register file
    always @(posedge clk) begin
        if (reset) begin
            AP_tn1 <= 32'h00000000;
            h_tn1 <= 32'h00000000;
            g_tn1 <= 32'h00000000;
            updated_regFile_tn1 <= 1'b0;
            exception_h_tn1 <= 1'b0;

        end else begin
            if (enable) begin
                AP_tn1 <= AP_t;
                h_tn1 <= h_t;
                g_tn1 <= g_t;
                updated_regFile_tn1 <= 1'b1;
                exception_h_tn1 <= exception_h_t;

            end else begin
                updated_regFile_tn1 <= 1'b0;

            end
        end
    end
endmodule
