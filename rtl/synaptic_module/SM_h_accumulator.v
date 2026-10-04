`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Aster Zawaideh
// 
// Create Date: 02/06/2026 12:38:52 PM
// Design Name: 
// Module Name: SM_h_accumulator
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


module SM_h_accumulator(
    input  wire       clk,
    input  wire       reset,
    input  wire       enable_h,
    input  wire [31:0] h0,
    input  wire [31:0] h_tn1,
    input  wire [31:0] tau_rise_inverse,
    input  wire       actionPotential_tn1,
    input  wire [31:0] dt,
    output wire [31:0] h_t,
    output wire       exception,
    output wire       done_h
);

    wire except_MAC1, except_MAC2;
    wire [31:0] result_MAC1, result_MAC2;

    // Gate *inputs* to reduce switching when enable_h=0 (optional but good)
    wire [31:0] h_tn1_gated = enable_h ? h_tn1 : 32'b0;
    wire [31:0] tau_gated   = enable_h ? tau_rise_inverse : 32'b0;
    wire [31:0] dt_gated    = enable_h ? dt : 32'b0;
    wire [31:0] b_MAC1      = (enable_h && actionPotential_tn1) ? h0 : 32'b0;
    
    wire [31:0] neg_h_tn1_gated;
    assign neg_h_tn1_gated = {~h_tn1_gated[31], h_tn1_gated[30:0]};

    LUT_MAC_Module MAC1(
        .M_value(neg_h_tn1_gated),
        .B_value(b_MAC1),
        .X_value(tau_gated),
        .Exception(except_MAC1),
        .Overflow(),
        .Underflow(),
        .result(result_MAC1)
    );

    LUT_MAC_Module MAC2(
        .M_value(result_MAC1),
        .B_value(h_tn1_gated),
        .X_value(dt_gated),
        .Exception(except_MAC2),
        .Overflow(),
        .Underflow(),
        .result(result_MAC2)
    );

    // Hold last valid output
    reg [31:0] h_hold;
    reg        exc_hold;
    reg        done_hold;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            h_hold   <= 32'b0;   // or h_tn1, your choice
            exc_hold <= 1'b0;
            done_hold<= 1'b0;
        end else begin
            // done_h as a 1-cycle pulse when enable_h is asserted
            done_hold <= enable_h;

            // only update held results when enabled
            if (enable_h) begin
                h_hold   <= result_MAC2;
                exc_hold <= (except_MAC1 | except_MAC2);
            end
        end
    end

    assign h_t       = h_hold;
    assign exception = exc_hold;
    assign done_h    = done_hold;

endmodule


//module SM_h_accumulator(
//    input reset,
//    input enable_h,
//    input [31:0] h0,
//    input [31:0] h_tn1,
//    input [31:0] tau_rise_inverse,
//    input actionPotential_tn1,
//    input [31:0] dt,
//    output wire [31:0] h_t,
//    output wire exception,
//    output wire done_h
//    );
    
    
//    wire except_MAC1,except_MAC2;
//    wire overF_MAC1,overF_MAC2;
//    wire underF_MAC1,underF_MAC2;
    
    
//    wire [31:0] result_MAC1, result_MAC2;

//    wire [31:0] b_MAC1;
//    assign b_MAC1 = actionPotential_tn1 ? h0 : 0; //if (event detected in pre-synaptic cell): add h0 , else: add 0

    
//    LUT_MAC_Module #(.DataWidth(32)) MAC1(
//        .M_value(h_tn1),
//        .B_value(b_MAC1),
//        .X_value(tau_rise_inverse),
//        .Exception(except_MAC1),
//        .Overflow(overF_MAC1),
//        .Underflow(underF_MAC1),
//        .result(result_MAC1)
//    );
    
//    LUT_MAC_Module #(.DataWidth(32)) MAC2(
//        .M_value(result_MAC1),
//        .B_value(h_tn1),
//        .X_value(dt),
//        .Exception(except_MAC2),
//        .Overflow(overF_MAC2),
//        .Underflow(underF_MAC2),
//        .result(result_MAC2)
//    );
    
//        assign exception = except_MAC1 | except_MAC2;
//        assign done_h = (reset ? 0 : (enable_h ? 1 : 0));
//        assign h_t = (enable_h ? result_MAC2 : h_tn1);

////    always @(reset or enable_h or result_MAC2)begin
////        if(reset)begin
////            done_h = 0;
////        end
////        else if(enable_h) begin
////            h_t = result_MAC2;
////            done_h = 1;
////        end else begin
////            h_t = h_tn1;
////            done_h = 0;
////        end
////        exception = except_MAC1 | except_MAC2;
////     end 
        
        
//endmodule
