`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Aster Zawaideh
// 
// Create Date: 02/07/2026 07:57:16 PM
// Design Name: 
// Module Name: tb_SM_h_g_accumulators
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


module tb_SM_h_g_accumulators;
    reg reset;
    reg enable_h;
    reg [31:0] tau_rise_inv;
    reg [31:0] h0;
    reg [31:0] dt;
    reg [31:0] h_tn1;
    reg AP_tn1;
    wire [31:0] h_t;
    wire exception_h_t;
    wire done_h;
    
    reg enable_g;
    reg [31:0] tau_decay_inv;
    reg [31:0] g_tn1;
    reg exception_h_tn1;
    wire [31:0] g_t;
    wire exception;
    wire done_g;


  
    SM_h_accumulator dut_h(
    .reset(reset),
    .enable_h(enable_h),
    .h0(h0),
    .h_tn1(h_tn1),
    .tau_rise_inverse(tau_rise_inv),
    .actionPotential_tn1(AP_tn1),
    .dt(dt),
    .h_t(h_t),
    .exception(exception_h_t),
    .done_h(done_h)
    );
    
    SM_g_accumulator dut_g(
    .reset(reset),
    .enable_g(enable_g),
    .h_tn1(h_tn1),
    .g_tn1(g_tn1),
    .tau_decay_inverse(tau_decay_inv),
    .dt(dt),
    .g_t(g_t),
    .exception_h_tn1(exception_h_tn1),
    .exception(exception),
    .done_g(done_g)
    );

    initial begin
      reset <=1;
      tau_rise_inv <= 32'h3e4ccccd; //0.2 in decimal (represented as a float)
      h0 <= 32'h3f000000; //0.5 in decimal (represented as a floating point)
      dt <= 32'h3f000000; //0.5 in decimal (represented as a floating point)
      h_tn1 <= 32'h3f000000; //0.5 in decimal (represented as a floating point)t)
      AP_tn1 <= 1'b0;
      enable_h <=1'b0;
      tau_decay_inv <= 32'h3f000000; //0.5 in decimal (represented as a float)
      //g_tn1 <= 32'h3eaaaaab; //0.33333333 in decimal (represented as a floating point (works)
//      g_tn1 <= 32'h3e800000; //0.25 in decimal (represented as a floating point) (works)
      g_tn1 <= 32'h3e700000; //0.23438 in decimal (represented as a floating point) (works)
      //g_tn1 <= 32'h3e19999a; //0.15 in decimal (represented as a floating point) (works)
      exception_h_tn1 <= 1'b0;
      enable_g <= 1'b0;
      
      
      
      #5 reset <=0; 

  
      #5 enable_h <=1;
      enable_g <=1;
      AP_tn1 <= 1'b0;
      
      #5 enable_h <=0;
      enable_g <=0;
      g_tn1 <= g_t;
      exception_h_tn1 <= exception_h_t;
      h_tn1 <= h_t;
    
      
      #5 enable_h <=1;
      enable_g <=1;
      AP_tn1<=1'b1;
    
      #5 enable_h <=0;
      h_tn1 <=h_t;
      enable_g <=0;
      g_tn1 <= g_t;
      exception_h_tn1 <= exception_h_t;
    
      #5 enable_h<=1;
      enable_g <=1;
      AP_tn1 <= 1'b0;
      
      #5 enable_h <= 0;
      h_tn1 <= h_t;
      enable_g <=0;
      g_tn1 <= g_t;
      exception_h_tn1 <= exception_h_t;
    
      #5 enable_h <=1;
      enable_g <=1;
      AP_tn1 <= 1'b1;
      
      #5 enable_h <= 0;
      h_tn1 <= h_t;
      enable_g <=0;
      g_tn1 <= g_t;
      exception_h_tn1 <= exception_h_t;
    
      #5 enable_h<=1;
      enable_g <=1;
      AP_tn1 <= 1'b0;
      
      #5 enable_h <= 0;
      h_tn1 <= h_t;
      enable_g <=0;
      g_tn1 <= g_t;
      exception_h_tn1 <= exception_h_t;
      
      
     #5 enable_h <=1;
      enable_g <=1;
      AP_tn1 <= 1'b1;
      
      #5 enable_h <= 0;
      h_tn1 <= h_t;
      enable_g <=0;
      g_tn1 <= g_t;
      exception_h_tn1 <= exception_h_t;
      
      
      #5 enable_h<=1;
      enable_g <=1;
      AP_tn1 <= 1'b0;
      
      
      #5 enable_h <= 0;
      enable_g <=0;
      g_tn1 <= g_t;
      exception_h_tn1 <= exception_h_t;
      h_tn1 <= h_t;
      
    end


endmodule
