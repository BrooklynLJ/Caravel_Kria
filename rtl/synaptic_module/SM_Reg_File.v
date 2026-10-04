`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Bryce Chen, Aster Zawaideh
// 
// Create Date: 12/20/2025 06:05:23 AM
// Design Name: 
// Module Name: SM_Reg_File
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


module SM_Reg_File (
   input         clk,
    input         reset,

//    //read ports (dont know if i need this i saw it on the example register file code online)
//    input  [3:0]  rdAddrA,
//    output [31:0] rdDataA,
//    input  [3:0]  rdAddrB,
//    output [31:0] rdDataB,
    
    input         commit,   // commit to update all state and constant variables per time step
    input         done_g,
    input         done_h,
    input  [31:0] next_f,
    input  [31:0] next_g_syn_bar,
    input  [31:0] next_T_rise,
    input  [31:0] next_ho,
    input  [31:0] next_AP,       // might change this to 1 bit but wantted to keep everyhting constant
    //input  [31:0] next_dt,
    input  [31:0] next_T_decay,
    input  [31:0] next_h,
    //input  [31:0] next_Vt,
    input  [31:0] next_g,
    //input  [31:0] next_Vmem,
    input  [31:0] next_Esyn,
    input  [31:0] g_t,
    input  [31:0] h_t,
    input  next_exception_h_t,

    output [31:0] f,
    output [31:0] g_syn_bar,
    output [31:0] T_rise,
    output [31:0] ho,
    output        AP,         
    output [31:0] dt,
    output [31:0] T_decay,
    output [31:0] h,
    //output [31:0] Vt,
    output [31:0] g,
   // output [31:0] Vmem,
    output [31:0] Esyn,
    output reg flag_update_tn1,
    output reg exception_h_t = 1'b0
);

    // address map
    localparam F_REG         = 0;
    localparam G_SYN_BAR_REG = 1;
    localparam T_RISE_REG    = 2;
    localparam HO_REG        = 3;
    localparam AP_REG        = 4;
    //localparam DT_REG        = 5;
    localparam T_DECAY_REG   = 6;
    localparam H_REG         = 7;
   // localparam VT_REG        = 8;
    localparam G_REG         = 9;
   // localparam VMEM_REG      = 10;
    localparam ESYN_REG      = 11;

    reg [31:0] regfile [0:11];

//    //reads
//    assign rdDataA = regfile[rdAddrA];
//    assign rdDataB = regfile[rdAddrB];

    //outputs
    assign f         = regfile[F_REG];
    assign g_syn_bar = regfile[G_SYN_BAR_REG];
    assign T_rise    = regfile[T_RISE_REG];
    assign ho        = regfile[HO_REG];
    assign AP        = regfile[AP_REG][0];
  //  assign dt        = regfile[DT_REG];
    assign T_decay   = regfile[T_DECAY_REG];
    assign h         = regfile[H_REG];
   // assign Vt        = regfile[VT_REG];
    assign g         = regfile[G_REG];
   // assign Vmem      = regfile[VMEM_REG];
    assign Esyn      = regfile[ESYN_REG];

    integer i;
    reg initialized_hg;
    
    //updating the values in the register file
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 12; i = i + 1)
                regfile[i] <= 32'h00000000;
                flag_update_tn1 <= 1'b0;
                exception_h_t <= 1'b0;
                initialized_hg <= 1'b0;

        end else begin
            flag_update_tn1 <= 1'b0;
            if (commit) begin
                regfile[F_REG]         <= next_f;
                regfile[G_SYN_BAR_REG] <= next_g_syn_bar;
                regfile[T_RISE_REG]    <= next_T_rise;
                regfile[HO_REG]        <= next_ho;
                regfile[AP_REG]        <= next_AP;
                regfile[T_DECAY_REG]   <= next_T_decay;
                regfile[ESYN_REG]      <= next_Esyn;

                // only initialize h/g once
                if (!initialized_hg) begin
                    regfile[H_REG] <= next_h;
                    regfile[G_REG] <= next_g;
                    initialized_hg <= 1'b1;
                end

                flag_update_tn1 <= 1'b1;
            end
//            if (commit) begin
//                regfile[F_REG]         <= next_f;
//                regfile[G_SYN_BAR_REG] <= next_g_syn_bar;
//                regfile[T_RISE_REG]    <= next_T_rise;
//                regfile[HO_REG]        <= next_ho;
//                regfile[AP_REG]        <= next_AP;
//               // regfile[DT_REG]        <= next_dt;
//                regfile[T_DECAY_REG]   <= next_T_decay;
//                regfile[H_REG]         <= next_h;
//                //regfile[VT_REG]        <= next_Vt;
//                regfile[G_REG]         <= next_g;
//                //regfile[VMEM_REG]      <= next_Vmem;
//                regfile[ESYN_REG]      <= next_Esyn;
//                flag_update_tn1 <= 1'b1;

//            end
            if(done_g) begin
                regfile[G_REG]         <= g_t; //writeback from Update g module
                flag_update_tn1 <= 1'b1;

            end
            if(done_h) begin
                regfile[H_REG]         <= h_t; // writeback from update h module
                flag_update_tn1 <= 1'b1;
                exception_h_t <= next_exception_h_t;

            end
            if(next_AP != regfile[AP_REG])begin
                regfile[AP_REG] <= next_AP;
                flag_update_tn1 <= 1'b1;

            end
            
        end
    end
endmodule