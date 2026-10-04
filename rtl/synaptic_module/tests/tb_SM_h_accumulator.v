`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Aster Zawaideh
// 
// Create Date: 01/15/2026 09:40:05 PM
// Design Name: 
// Module Name: tb_SM_h_accumulator
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


module tb_SM_h_accumulator;
    reg reset;
    reg enable_h;
    reg [31:0] tau_rise_inv;
    reg [31:0] h0;
    reg [31:0] dt;
    reg [31:0] h_tn1;
    reg [1:0] synapseID;
    reg AP_tn1;
    wire [31:0] h_t;
    wire exception;
    wire done_h;


  
    SM_h_accumulator dut(
    .reset(reset),
    .enable_h(enable_h),
    .h0(h0),
    .h_tn1(h_tn1),
    .tau_rise_inverse(tau_rise_inv),
    .actionPotential_tn1(AP_tn1),
    .dt(dt),
    .h_t(h_t),
    .exception(exception),
    .done_h(done_h)
    );
    
  
  initial begin
  reset <=1;
  tau_rise_inv = 32'h3e4ccccd; //0.2 in decimal (represented as a float)
  h0 = 32'h3f000000; //0.5 in decimal (represented as a floating point)
  dt = 32'h40000000; //2 in decimal (represented as a floating point)
  h_tn1 = 32'h3f000000; //0.5 in decimal (represented as a floating point)t)
  
  AP_tn1 <= 1'b0;
  enable_h <=0;
  
  #5 reset <=0; 

  
  #10 enable_h <=1;
  AP_tn1 <= 1'b0;
  
  #15 enable_h <=0;
  h_tn1 <= h_t;

  
  #20 enable_h <=1;
  AP_tn1<=1'b1;

  #25 enable_h <=0;
  h_tn1 <=h_t;

  #30 enable_h<=1;
  AP_tn1 <= 1'b0;
  
  #35 enable_h <= 0;
  h_tn1 <= h_t;

  #40 enable_h <=1;
  AP_tn1 <= 1'b1;
  
  #45 enable_h <= 0;
  h_tn1 <= h_t;

  #50 enable_h<=1;
  AP_tn1 <= 1'b0;
  
  #55 enable_h <= 0;
  h_tn1 <= h_t;
  
  
 #60 enable_h <=1;
  AP_tn1 <= 1'b1;
  
  #65 enable_h <= 0;
  h_tn1 <= h_t;
  
  
  #70 enable_h<=1;
  AP_tn1 <= 1'b0;
  
  #75 enable_h <= 0;
  h_tn1 <= h_t;

  end
  
  
    
endmodule