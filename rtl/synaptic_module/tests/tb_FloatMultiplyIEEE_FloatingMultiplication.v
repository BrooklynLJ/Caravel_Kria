`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/12/2026 11:28:36 AM
// Design Name: 
// Module Name: tb_FloatMultiplyIEEE_FloatingMultiplication
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


//module tb_FloatMultiplyIEEE_FloatingMultiplication;
module tb_FloatMultiplyIEEE_FloatingMultiplication;

reg  [31:0] A, B;
wire        Exception, Overflow, Underflow;
wire [31:0] result;

real expected_value;
real calculated_value;

FloatingMultiplication dut (
    .A(A),
    .B(B),
    .Exception(Exception),
    .Overflow(Overflow),
    .Underflow(Underflow),
    .result(result)
);

initial begin
    // Case 1: 3.2 * 4.2
    A = 32'b0_10000000_10011001100110011001100;  // 3.2
    B = 32'b0_10000001_00001100110011001100110;  // 4.2
    #20

    // Case 2: -0.5 * -6.4
    A = 32'b1_01111110_00000000000000000000000;  // -0.5
    B = 32'b1_10000001_10011001100110011001100;  // -6.4
    #20

    // Case 3: -0.5 * 6.4
    A = 32'b1_01111110_00000000000000000000000;  // -0.5
    B = 32'b0_10000001_10011001100110011001100;  //  6.4
    #20

    // Case 4: 2.82 * -0.94
    A = 32'h4034b4b5;  // 2.82
    B = 32'hbf70f0f1;  // -0.94
    #20

    // Extra cases to catch the "nonzero * nonzero -> 0" type problems:

    // Case 5: 1.0 * 1.0  (should be exactly 1.0)
    A = 32'h3f800000;  // 1.0
    B = 32'h3f800000;  // 1.0
    #20

    // Case 6: 2.0 * 0.5  (should be exactly 1.0)
    A = 32'h40000000;  // 2.0
    B = 32'h3f000000;  // 0.5
    #20

    // Case 7: smallest normal * 2.0 (should still be normal, not zero)
    A = 32'h3D000000; //0.03125
    B = 32'h40000000;  // 2.0
    #20

    // Case 8: a "random" mantissa-heavy number * another
    A = 32'h3eaaaaab;  // ~0.33333334
    B = 32'h41200000;  // 10.0
    #20

    $finish;
end

initial begin
    #15;

    // -------- Helper: decode fp32 result into a real (normal numbers only)
    // NOTE: This matches your earlier style; it assumes normalized results.
    // If result becomes 0/inf/denormal, calculated_value may not match.
    // --------

    // Case 1 print
    expected_value   = 3.2 * 4.2;
    calculated_value = (2.0**(result[30:23]-127)) *
                       ($itor({1'b1,result[22:0]})/2.0**23) *
                       ((-1.0)**(result[31]));
    $display("Case1  Expected: %f  Calculated: %f  result=%h  Exc=%b Ovf=%b Udf=%b",
              expected_value, calculated_value, result, Exception, Overflow, Underflow);

    #20;
    // Case 2 print
    expected_value   = (-0.5) * (-6.4);
    calculated_value = (2.0**(result[30:23]-127)) *
                       ($itor({1'b1,result[22:0]})/2.0**23) *
                       ((-1.0)**(result[31]));
    $display("Case2  Expected: %f  Calculated: %f  result=%h  Exc=%b Ovf=%b Udf=%b",
              expected_value, calculated_value, result, Exception, Overflow, Underflow);

    #20;
    // Case 3 print
    expected_value   = (-0.5) * (6.4);
    calculated_value = (2.0**(result[30:23]-127)) *
                       ($itor({1'b1,result[22:0]})/2.0**23) *
                       ((-1.0)**(result[31]));
    $display("Case3  Expected: %f  Calculated: %f  result=%h  Exc=%b Ovf=%b Udf=%b",
              expected_value, calculated_value, result, Exception, Overflow, Underflow);

    #20;
    // Case 4 print
    expected_value   = 2.82 * (-0.94);
    calculated_value = (2.0**(result[30:23]-127)) *
                       ($itor({1'b1,result[22:0]})/2.0**23) *
                       ((-1.0)**(result[31]));
    $display("Case4  Expected: %f  Calculated: %f  result=%h  Exc=%b Ovf=%b Udf=%b",
              expected_value, calculated_value, result, Exception, Overflow, Underflow);

    #20;
    // Case 5 print
    expected_value   = 1.0 * 1.0;
    calculated_value = (2.0**(result[30:23]-127)) *
                       ($itor({1'b1,result[22:0]})/2.0**23) *
                       ((-1.0)**(result[31]));
    $display("Case5  Expected: %f  Calculated: %f  result=%h  Exc=%b Ovf=%b Udf=%b",
              expected_value, calculated_value, result, Exception, Overflow, Underflow);

    #20;
    // Case 6 print
    expected_value   = 2.0 * 0.5;
    calculated_value = (2.0**(result[30:23]-127)) *
                       ($itor({1'b1,result[22:0]})/2.0**23) *
                       ((-1.0)**(result[31]));
    $display("Case6  Expected: %f  Calculated: %f  result=%h  Exc=%b Ovf=%b Udf=%b",
              expected_value, calculated_value, result, Exception, Overflow, Underflow);

    #20;
    // Case 7 print
    expected_value   = 0.03125 * 2.0;
    calculated_value = (2.0**(result[30:23]-127)) *
                       ($itor({1'b1,result[22:0]})/2.0**23) *
                       ((-1.0)**(result[31]));
    $display("Case7  Expected: %e  Calculated: %e  result=%h  Exc=%b Ovf=%b Udf=%b",
              expected_value, calculated_value, result, Exception, Overflow, Underflow);

    #20;
    // Case 8 print
    expected_value   = 0.33333334 * 10.0;
    calculated_value = (2.0**(result[30:23]-127)) *
                       ($itor({1'b1,result[22:0]})/2.0**23) *
                       ((-1.0)**(result[31]));
    $display("Case8  Expected: %f  Calculated: %f  result=%h  Exc=%b Ovf=%b Udf=%b",
              expected_value, calculated_value, result, Exception, Overflow, Underflow);
end

endmodule