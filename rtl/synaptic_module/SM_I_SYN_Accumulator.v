`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Bryce Chen
//
// Create Date: 01/11/2026 01:18:36 AM
// why do i do this to myself
// Design Name: 
// Module Name: SM_I_SYN_Accumulator
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

module SM_I_SYN_Accumulator(
    input             clk,          // NEW
    input             reset,
    input             enable_i_syn,
    input      [31:0] g_syn_bar,
    input      [31:0] f,
    input      [31:0] g,
    input      [31:0] Vmem,
    input      [31:0] E_syn,

    output reg [31:0] i_syn_sum,     // CHANGED to reg (same name)
    output reg        done_i_syn     // CHANGED to reg (same name)
);

    wire [31:0] E_syn_neg;
    assign E_syn_neg = {~E_syn[31], E_syn[30:0]};  // flip sign bit

    // Vmem - E_syn
    wire [31:0] diff;
    wire diff_exc;

    FloatingAddition diff_Vmem_E_syn (
        .A(Vmem),
        .B(E_syn_neg),
        .Exception(diff_exc),
        .result(diff)
    );

    wire [31:0] t1, t2, i_syn;
    wire mul1_exc, mul1_ovf, mul1_udf;
    wire mul2_exc, mul2_ovf, mul2_udf;
    wire mul3_exc, mul3_ovf, mul3_udf;

    FloatingMultiplication mul_g_syn_bar_f (
        .A(g_syn_bar),
        .B(f),
        .Exception(mul1_exc),
        .Overflow(mul1_ovf),
        .Underflow(mul1_udf),
        .result(t1)
    );

    FloatingMultiplication mul_t1_g (
        .A(t1),
        .B(g),
        .Exception(mul2_exc),
        .Overflow(mul2_ovf),
        .Underflow(mul2_udf),
        .result(t2)
    );

    FloatingMultiplication mul_t2_diff (
        .A(t2),
        .B(diff),
        .Exception(mul3_exc),
        .Overflow(mul3_ovf),
        .Underflow(mul3_udf),
        .result(i_syn)
    );

    // Clocked handshake + output register:
    // - done_i_syn is a 1-cycle pulse when enable_i_syn is high
    // - i_syn_sum only updates when enable_i_syn is high (otherwise holds)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            done_i_syn <= 1'b0;
            i_syn_sum  <= 32'b0;
        end else begin
            done_i_syn <= enable_i_syn;

            if (enable_i_syn) begin
                i_syn_sum <= i_syn;
            end
        end
    end

endmodule



//module SM_I_SYN_Accumulator(
//    input             reset,
//    input             enable_i_syn,
//    input      [31:0] g_syn_bar,
//    input      [31:0] f,
//    input      [31:0] g,
//    input      [31:0] Vmem,
//    input      [31:0] E_syn,

//    output wire [31:0] i_syn_sum,
//    output wire done_i_syn
//);

//    wire [31:0] E_syn_neg;
//    assign E_syn_neg = {~E_syn[31], E_syn[30:0]};  // flip sign bit


//    //Vmem - E_syn
//    wire [31:0] diff;
//    wire diff_exc;

//    FloatingAddition diff_Vmem_E_syn (
//        .A(Vmem),
//        .B(E_syn_neg),
//        .Exception(diff_exc),
//        .result(diff)
//    );


//    wire [31:0] t1, t2, i_syn;
//    wire mul1_exc, mul1_ovf, mul1_udf;
//    wire mul2_exc, mul2_ovf, mul2_udf;
//    wire mul3_exc, mul3_ovf, mul3_udf;

//    FloatingMultiplication mul_g_syn_bar_f (
//        .A(g_syn_bar),
//        .B(f),
//        .Exception(mul1_exc),
//        .Overflow(mul1_ovf),
//        .Underflow(mul1_udf),
//        .result(t1)
//    );

//    FloatingMultiplication mul_t1_g (
//        .A(t1),
//        .B(g),
//        .Exception(mul2_exc),
//        .Overflow(mul2_ovf),
//        .Underflow(mul2_udf),
//        .result(t2)
//    );

//    FloatingMultiplication mul_t2_diff (
//        .A(t2),
//        .B(diff),
//        .Exception(mul3_exc),
//        .Overflow(mul3_ovf),
//        .Underflow(mul3_udf),
//        .result(i_syn)
//    );
    
//    assign done_i_syn = (reset ? 0 : (enable_i_syn ? 1 : 0));
//    assign i_syn_sum = enable_i_syn ? i_syn: 0;
//endmodule