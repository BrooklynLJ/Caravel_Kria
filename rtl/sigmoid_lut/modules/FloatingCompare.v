`timescale 1ns / 1ps
//https://github.com/akilm/FPU-IEEE-754/blob/main/srcs/sources/FloatingCompare.v

`ifndef _floating_compare
`define _floating_compare

// returns A >= B via the output register
module FloatingCompare (input [31:0]A,
                        input [31:0]B,
                        output reg result);

    always @(*) begin
        // compare signs
        if (A[31] != B[31])
            result <= ~A[31];  // A is positive (0) -> A >= B -> result = 1

        // compare exponents
        else begin
            if (A[30:23] != B[30:23]) begin
                if (A[31])
                    result <= (A[30:23] > B[30:23]) ? 1'b0 : 1'b1;  // B has bigger exponent than A, so it is bigger
                else
                    result <= (A[30:23] > B[30:23]) ? 1'b1 : 1'b0;  // A has bigger exponent than B, so it is bigger
            end
            // compare mantissas
            else begin
                if (A[31])
                    result <= (A[22:0] > B[22:0]) ? 1'b0 : 1'b1;  // B has bigger mantissa than A, so it is bigger
                else
                    result <= (A[22:0] > B[22:0]) ? 1'b1 : 1'b0;  // A has bigger mantissa than B, so it is bigger
            end
        end
    end

endmodule
`endif //_floating_compare