`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Reference: https://github.com/akilm/FPU-IEEE-754/blob/main/srcs/sources/FloatingMultiplication.v
// Revised by Aster Zawaideh
// 
// Create Date: 02/11/2026 10:21:38 AM
// Design Name: 
// Module Name: FloatMultiplyIEEE754
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

module FloatMultiplyIEEE754 #(parameter XLEN=32)
                                (input [XLEN-1:0]A,
                                 input [XLEN-1:0]B,
                                 output [XLEN-1:0] result);

    wire [23:0] A_Mantissa = {1'b1, A[22:0]}, B_Mantissa = {1'b1, B[22:0]};
    wire [7:0] A_Exponent = A[30:23], B_Exponent = B[30:23];
    wire A_sign = A[31], B_sign = B[31];
    
    reg [47:0] Temp_Mantissa;
    wire [22:0] Mantissa = Temp_Mantissa[45:23];  // highest bits of Temp_Mantissa, except for 1 carry bit (which causes bitshift)
    reg [8:0] Temp_Exponent;  // one bit bigger because of potential overflow
    wire [7:0] Exponent;// = Temp_Exponent[7:0];
    reg Sign;
    assign Exponent = Temp_Exponent[7:0];
    assign result = {Sign, Exponent, Mantissa};
    
    
    always@(*)
        begin
        Temp_Exponent = (A_Exponent + B_Exponent < 'd127) ? 8'd0 : A_Exponent + B_Exponent - 'd127;  // prevent exponent underflow
        Temp_Mantissa = A_Mantissa*B_Mantissa;
        
        // "carry"... increase exponent, shift
        if (Temp_Mantissa[47]) begin
            Temp_Mantissa = Temp_Mantissa << 1;  // Mantissa = Temp_Mantissa[46:24]
            Temp_Exponent = Temp_Exponent + 1;
        end
        
        // prevent exponent overflow
        if (Temp_Exponent[8])
            Temp_Exponent[7:0] = 8'hff;
        
        Sign = A_sign^B_sign;
        end
endmodule