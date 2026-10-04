`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/21/2026 09:20:26 PM
// Design Name: 
// Module Name: SM_Reg_File_Static
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


module SM_Reg_File_Static(
    input wire clk,
    input wire reset,
    input wire enable,

    input wire [31:0] V_membrane,
    input wire [31:0] V_threshold,
    input wire [31:0] dt,
    
    output reg [31:0] dt_out,         
    output reg [31:0] V_membrane_out,
    output reg [31:0] V_threshold_out
);

    //updating the values in the register file
    always @(posedge clk) begin
        if (reset) begin
            dt_out <= 32'h00000000;
            V_membrane_out <= 32'h00000000;
            V_threshold_out <= 32'h00000000;

        end else begin
            if (enable) begin
                dt_out <= dt;
                V_membrane_out <= V_membrane;
                V_threshold_out <= V_threshold;
            end
        end
    end
endmodule

