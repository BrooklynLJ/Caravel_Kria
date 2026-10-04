`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Aster Zawaideh
// 
// Create Date: 01/15/2026 09:14:56 PM
// Design Name: 
// Module Name: SM_g_accumulator
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

module SM_g_accumulator(
    input  wire        clk,
    input  wire        reset,
    input  wire        enable_g,
    input  wire [31:0] h_tn1,
    input  wire [31:0] g_tn1,
    input  wire [31:0] tau_decay_inverse,
    input  wire [31:0] dt,
    input  wire        exception_h_tn1,
    output wire [31:0] g_t,
    output wire        exception,
    output wire        done_g
);

    wire except_MAC1, except_MAC2;
    wire [31:0] result_MAC1, result_MAC2;

    // Gate inputs to reduce switching when enable_g=0
    wire [31:0] g_tn1_gated = enable_g ? g_tn1 : 32'b0;
    wire [31:0] h_tn1_gated = enable_g ? h_tn1 : 32'b0;
    wire [31:0] tau_gated   = enable_g ? tau_decay_inverse : 32'b0;
    wire [31:0] dt_gated    = enable_g ? dt : 32'b0;
    
    wire [31:0] neg_g_tn1_gated;
    assign neg_g_tn1_gated = {~g_tn1_gated[31], g_tn1_gated[30:0]};

    LUT_MAC_Module #(.DataWidth(32)) MAC1(
        .M_value(neg_g_tn1_gated),
        .B_value(h_tn1_gated),
        .X_value(tau_gated),
        .Exception(except_MAC1),
        .Overflow(),
        .Underflow(),
        .result(result_MAC1)
    );

    LUT_MAC_Module #(.DataWidth(32)) MAC2(
        .M_value(result_MAC1),
        .B_value(g_tn1_gated),
        .X_value(dt_gated),
        .Exception(except_MAC2),
        .Overflow(),
        .Underflow(),
        .result(result_MAC2)
    );

    // Hold last valid g_t and exception
    reg [31:0] g_hold;
    reg        exc_hold;
    reg        done_hold;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            g_hold    <= 32'b0;   // or g_tn1 if you prefer
            exc_hold  <= 1'b0;
            done_hold <= 1'b0;
        end else begin
            // done pulse = 1 cycle whenever enable_g is asserted for that cycle
            done_hold <= enable_g;

            if (enable_g) begin
                g_hold   <= result_MAC2;
                exc_hold <= (except_MAC1 | except_MAC2 | exception_h_tn1);
            end
        end
    end

    assign g_t       = g_hold;
    assign exception = exc_hold;
    assign done_g    = done_hold;

endmodule


//module SM_g_accumulator(
//    input reset,
//    input enable_g,
//    input [31:0] h_tn1,
//    input [31:0] g_tn1,
//    input [31:0] tau_decay_inverse,
//    input [31:0] dt,
//    input exception_h_tn1,
//    output wire [31:0] g_t,
//    output wire exception,
//    output wire done_g
//    );
    
//    wire except_MAC1,except_MAC2;
//    wire overF_MAC1,overF_MAC2;
//    wire underF_MAC1,underF_MAC2;
//    wire [31:0] result_MAC1, result_MAC2;

    
//    LUT_MAC_Module #(.DataWidth(32)) MAC1(
//        .M_value(g_tn1),
//        .B_value(h_tn1),
//        .X_value(tau_decay_inverse),
//        .Exception(except_MAC1),
//        .Overflow(overF_MAC1),
//        .Underflow(underF_MAC1),
//        .result(result_MAC1)
//    );
    
//    LUT_MAC_Module #(.DataWidth(32)) MAC2(
//        .M_value(result_MAC1),
//        .B_value(g_tn1),
//        .X_value(dt),
//        .Exception(except_MAC2),
//        .Overflow(overF_MAC2),
//        .Underflow(underF_MAC2),
//        .result(result_MAC2)
//    );

//    assign exception = except_MAC1 | except_MAC2 | exception_h_tn1;
//    assign done_g = (reset ? 0 : (enable_g ? 1 : 0));
//    assign g_t = (enable_g ? result_MAC2 : g_tn1);

    
////     always @(reset or enable_g or result_MAC2)begin
////        if(reset)begin
////            done_g = 0;
////        end
////        else if(enable_g) begin
////            g_t = result_MAC2;
////            done_g = 1;
////        end else begin
////            g_t = g_tn1;
////            done_g = 0;
////        end
////        exception = except_MAC1 | except_MAC2 | exception_h_tn1;
 
////     end 
    
//endmodule