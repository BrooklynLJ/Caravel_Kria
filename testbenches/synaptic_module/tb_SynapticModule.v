`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Aster Zawaideh
// 
// Create Date: 02/21/2026 03:17:20 PM
// Design Name: 
// Module Name: tb_SynapticModule
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


module tb_SynapticModule;
    reg        reset;
    reg        clk;
    wire        irq;

    reg commitStatic;
    reg commit0;
    reg commit1;
    reg commit2;
    reg commit3;
    
    reg [31:0] next_dt;
    reg [31:0] next_Vmem;
    reg [31:0] next_Vt;
    
    reg  [31:0] next_f_0;
    reg  [31:0] next_g_syn_bar_0;
    reg  [31:0] next_T_rise_0;
    reg  [31:0] next_ho_0;
    reg  [31:0] next_AP_0;       // might change this to 1 bit but wanted to keep everyhting constant
    reg  [31:0] next_T_decay_0;
    reg  [31:0] next_h_0;
    reg  [31:0] next_g_0;
    reg  [31:0] next_Esyn_0;
    
    reg  [31:0] next_f_1;
    reg  [31:0] next_g_syn_bar_1;
    reg  [31:0] next_T_rise_1;
    reg  [31:0] next_ho_1;
    reg  [31:0] next_AP_1;       // might change this to 1 bit but wanted to keep everyhting constant
    reg  [31:0] next_T_decay_1;
    reg  [31:0] next_h_1;
    reg  [31:0] next_g_1;
    reg  [31:0] next_Esyn_1;
    
    reg  [31:0] next_f_2;
    reg  [31:0] next_g_syn_bar_2;
    reg  [31:0] next_T_rise_2;
    reg  [31:0] next_ho_2;
    reg  [31:0] next_AP_2;       // might change this to 1 bit but wanted to keep everyhting constant
    reg  [31:0] next_T_decay_2;
    reg  [31:0] next_h_2;
    reg  [31:0] next_g_2;
    reg  [31:0] next_Esyn_2;
    
    reg  [31:0] next_f_3;
    reg  [31:0] next_g_syn_bar_3;
    reg  [31:0] next_T_rise_3;
    reg  [31:0] next_ho_3;
    reg  [31:0] next_AP_3;       // might change this to 1 bit but wanted to keep everyhting constant
    reg  [31:0] next_T_decay_3;
    reg  [31:0] next_h_3;
    reg  [31:0] next_g_3;
    reg  [31:0] next_Esyn_3;
    
    SynapticModule_Standalone dut_SM(
        .RST_I(reset),
        .CLK_I(clk),
        
        .commitStatic(commitStatic),
        .commit0(commit0),
        .commit1(commit1),
        .commit2(commit2),
        .commit3(commit3),
        
        .next_dt(next_dt),
        .next_Vmem(next_Vmem),
        .next_Vt(next_Vt),
        
        .next_f_0(next_f_0),
        .next_g_syn_bar_0(next_g_syn_bar_0),
        .next_T_rise_0(next_T_rise_0),
        .next_ho_0(next_ho_0),
        .next_AP_0(next_AP_0),       // might change this to 1 bit but wanted to keep everyhting constant
        .next_T_decay_0(next_T_decay_0),
        .next_h_0(next_h_0),
        .next_g_0(next_g_0),
        .next_Esyn_0(next_Esyn_0),
        
        .next_f_1(next_f_1),
        .next_g_syn_bar_1(next_g_syn_bar_1),
        .next_T_rise_1(next_T_rise_1),
        .next_ho_1(next_ho_1),
        .next_AP_1(next_AP_1),       // might change this to 1 bit but wanted to keep everyhting constant
        .next_T_decay_1(next_T_decay_1),
        .next_h_1(next_h_1),
        .next_g_1(next_g_1),
        .next_Esyn_1(next_Esyn_1),
        
        .next_f_2(next_f_2),
        .next_g_syn_bar_2(next_g_syn_bar_2),
        .next_T_rise_2(next_T_rise_2),
        .next_ho_2(next_ho_2),
        .next_AP_2(next_AP_2),       // might change this to 1 bit but wanted to keep everyhting constant
        .next_T_decay_2(next_T_decay_2),
        .next_h_2(next_h_2),
        .next_g_2(next_g_2),
        .next_Esyn_2(next_Esyn_2),
        
        .next_f_3(next_f_3),
        .next_g_syn_bar_3(next_g_syn_bar_3),
        .next_T_rise_3(next_T_rise_3),
        .next_ho_3(next_ho_3),
        .next_AP_3(next_AP_3),       // might change this to 1 bit but wanted to keep everyhting constant
        .next_T_decay_3(next_T_decay_3),
        .next_h_3(next_h_3),
        .next_g_3(next_g_3),
        .next_Esyn_3(next_Esyn_3),
        
        
        .irq(irq)
    );
    
    
      // 10 ns clock
      initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
      end
        
    initial begin 
        reset <= 1;
        
        @(posedge clk);
        @(posedge clk);
        reset <=0; 
        @(posedge clk);
        next_dt = 32'h3f000000;  // 0.5 in decimal, represented as float
        next_Vmem = 32'h3ee00000; //0.4375 in decimal, represented as float
//        next_Vmem = 32'h3fc00000; //1.5 in decimal, represented as float
        next_Vt = 32'h3f933333;  //1.15 in decimal, represented as float
        
        next_f_0 = 32'h3e900000; //0.28125        
        next_g_syn_bar_0 = 32'h3e800000; //0.25
        next_T_rise_0 = 32'h3e4ccccd; //0.20
        next_ho_0 = 32'h3f000000; //0.5       
        next_AP_0 = 32'h00000000; //0       
        next_T_decay_0 = 32'h3f000000;  //0.5
        next_h_0 = 32'h3f000000;  //0.5        
        next_g_0 = 32'h3e700000; //0.23438      
        next_Esyn_0 = 32'h3f200000; //0.625    
                         
        next_f_1 = 32'h3e900000; //0.28125           
        next_g_syn_bar_1 = 32'h3e800000; //0.25
        next_T_rise_1 = 32'h3e4ccccd; //0.20
        next_ho_1 =  32'h3f000000; //0.5       
        next_AP_1 = 32'h00000000; //0      
        next_T_decay_1 = 32'h3f000000;  //0.5
        next_h_1 =32'h3f000000;  //0.5      
        next_g_1 = 32'h3e700000; //0.23438      
        next_Esyn_1 =  32'h3f200000; //0.625    
                         
        next_f_2 = 32'h3e900000; //0.28125             
        next_g_syn_bar_2 = 32'h3e800000; //0.25
        next_T_rise_2 = 32'h3e4ccccd; //0.20
        next_ho_2 =  32'h3f000000; //0.5       
        next_AP_2 = 32'h00000000; //0      
        next_T_decay_2 = 32'h3f000000;  //0.5
        next_h_2 = 32'h3f000000;  //0.5      
        next_g_2 = 32'h3e700000; //0.23438      
        next_Esyn_2 =  32'h3f200000; //0.625    
                         
        next_f_3 = 32'h3e900000; //0.28125           
        next_g_syn_bar_3 = 32'h3e800000; //0.25
        next_T_rise_3 = 32'h3e4ccccd; //0.20
        next_ho_3 =  32'h3f000000; //0.5           
        next_AP_3 = 32'h00000000; //0      
        next_T_decay_3 = 32'h3f000000;  //0.5
        next_h_3 = 32'h3f000000;  //0.5      
        next_g_3 = 32'h3e700000; //0.23438      
        next_Esyn_3 =  32'h3f200000; //0.625  
        
        commit0 <=1;
        commit1 <= 1;
        commit2 <= 1;
        commit3 <= 1;  
        commitStatic <= 1;  
        
        @(posedge clk);
        
        commit0 <=0;
        commit1 <= 0;
        commit2 <= 0;
        commit3 <= 0;
        commitStatic <= 0;  
                
        next_AP_0 = 32'h00000001; //1      
        next_AP_1 = 32'h00000001; //1      
        next_AP_2 = 32'h00000001; //1       
        next_AP_3 = 32'h00000001; //1      

        
        @(posedge clk);
        next_AP_0 = 32'h00000000; //0      
        next_AP_1 = 32'h00000000; //0      
        next_AP_2 = 32'h00000000; //0       
        next_AP_3 = 32'h00000000; //0      

        
//        @(posedge clk);

        
        @(posedge clk);
        next_AP_0 = 32'h00000001; //1      
        next_AP_1 = 32'h00000001; //1      
        next_AP_2 = 32'h00000001; //1       
        next_AP_3 = 32'h00000001; //1      

               
        @(posedge clk); 
        next_AP_0 = 32'h00000000; //0      
        next_AP_1 = 32'h00000000; //0      
        next_AP_2 = 32'h00000000; //0       
        next_AP_3 = 32'h00000000; //0      

//        @(posedge clk);
        
        
    end 
    

endmodule
