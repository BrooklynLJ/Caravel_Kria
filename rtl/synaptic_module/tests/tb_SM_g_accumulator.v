`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Aster Zawaideh
// 
// Create Date: 02/07/2026 07:45:10 PM
// Design Name: 
// Module Name: tb_SM_g_accumulator
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


module tb_SM_g_accumulator;
    reg reset;
    reg enable_g;
    reg [31:0] tau_decay_inv;
    reg [31:0] dt;
    reg [31:0] h_tn1;
    reg [31:0] g_tn1;
    reg exception_h_tn1;
    wire [31:0] g_t;
    wire exception;
    wire done_g;


  
    SM_g_accumulator dut(
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
  tau_decay_inv = 32'h3f000000; //0.5 in decimal (represented as a float)
  dt = 32'h40000000; //2 in decimal (represented as a floating point)
  h_tn1 = 32'h3f800000; //1 in decimal (represented as a floating point)t)
  g_tn1 = 32'h3f800000; //1 in decimal (represented as a floating point)t)
  exception_h_tn1 <= 0;
  enable_g <=0;
  
  #5 reset <=0; 
  h_tn1 <= 32'h40000000; //2

  #5 enable_g <=1;
  
  #5 enable_g <=0;
  g_tn1 <= g_t;
  h_tn1 <= 32'h40400000; //3

  
  #5 enable_g <=1;

  #5 enable_g <=0;
  g_tn1 <=g_t;
  h_tn1 <= 32'h40800000; //4

  #5 enable_g<=1;

  
  #5 enable_g <= 0;
  g_tn1 <= g_t;
  h_tn1 <= 32'h40a00000; //5


  #5 enable_g <=1;
  
  
  #5 enable_g <= 0;
  g_tn1 <= g_t;
  h_tn1 <= 32'h40c00000; //6

  #5 enable_g<=1;
  
  #5 enable_g <= 0;
  g_tn1 <= g_t;
  h_tn1 <= 32'h40e00000; //7

  
  #5 enable_g <=1;
  
  #5 enable_g <= 0;
  g_tn1 <= g_t;
  h_tn1 <= 32'h41000000; //8

  
  
  #5 enable_g<=1;
  
  #5 enable_g <= 0;
  g_tn1 <= g_t;
  h_tn1 <= 32'h41100000; //9


  end

endmodule
