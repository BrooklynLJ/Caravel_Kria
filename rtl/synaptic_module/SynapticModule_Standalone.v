`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/21/2026 08:42:23 PM
// Design Name: 
// Module Name: SynapticModule_Standalone
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


module SynapticModule_Standalone(
    input wire RST_I,
    input wire CLK_I,
     
    input wire commitStatic,

    input wire commit0,
    input wire commit1, 
    input wire commit2, 
    input wire commit3,
    
    input wire [31:0] next_dt,
    input wire [31:0] next_Vmem,
    input wire [31:0] next_Vt,
    
    input wire [31:0] next_f_0,
    input wire [31:0] next_g_syn_bar_0,
    input wire [31:0] next_T_rise_0,
    input wire [31:0] next_ho_0,
    input wire [31:0] next_AP_0,       // might change this to 1 bit but wantted to keep everyhting constant
    input wire [31:0] next_T_decay_0,
    input wire [31:0] next_h_0,
    input wire [31:0] next_g_0,
    input wire [31:0] next_Esyn_0,
          
    input wire [31:0] next_f_1,
    input wire [31:0] next_g_syn_bar_1,
    input wire [31:0] next_T_rise_1,
    input wire [31:0] next_ho_1,
    input wire [31:0] next_AP_1,       // might change this to 1 bit but wantted to keep everyhting constant
    input wire [31:0] next_T_decay_1,
    input wire [31:0] next_h_1,
    input wire [31:0] next_g_1,
    input wire [31:0] next_Esyn_1,
          
    input wire [31:0] next_f_2,
    input wire [31:0] next_g_syn_bar_2,
    input wire [31:0] next_T_rise_2,
    input wire [31:0] next_ho_2,
    input wire [31:0] next_AP_2,       // might change this to 1 bit but wantted to keep everyhting constant
    input wire [31:0] next_T_decay_2,
    input wire [31:0] next_h_2,
    input wire [31:0] next_g_2,
    input wire [31:0] next_Esyn_2,
          
    input wire [31:0] next_f_3,
    input wire [31:0] next_g_syn_bar_3,
    input wire [31:0] next_T_rise_3,
    input wire [31:0] next_ho_3,
    input wire [31:0] next_AP_3,       // might change this to 1 bit but wantted to keep everyhting constant
    input wire [31:0] next_T_decay_3,
    input wire [31:0] next_h_3,
    input wire [31:0] next_g_3,
    input wire [31:0] next_Esyn_3,
    
    output wire irq

);

    assign irq    = 1'b0;


    // Outputs from each regfile
    wire [31:0] f0, gsyn0, Trise0, ho0, Tdecay0, h0, g0, Esyn0;
    wire        AP0;
    wire [31:0] f1, gsyn1, Trise1, ho1, Tdecay1, h1, g1, Esyn1;
    wire        AP1;
    wire [31:0] f2, gsyn2, Trise2, ho2, Tdecay2, h2, g2, Esyn2;
    wire        AP2;
    wire [31:0] f3, gsyn3, Trise3, ho3, Tdecay3, h3, g3, Esyn3;
    wire        AP3;
    
    reg reset_g, reset_h;
    wire [31:0] g0_t, g1_t, g2_t, g3_t;
    wire [31:0] h0_t, h1_t, h2_t, h3_t;
    wire [3:0]  flag_update_tn1;
    wire [3:0] exception_h;
    wire [3:0] updated_regFile_tn1;
    wire [31:0] dt, Vmem, Vt;

 SM_Reg_File_Static neuronStaticParameters(
        .clk(CLK_I),
        .reset(RST_I),
        .enable(commitStatic),
    
        .V_membrane(next_Vmem),
        .V_threshold(next_Vt),
        .dt(next_dt),
       
        .dt_out(dt),         
        .V_membrane_out(Vmem),
        .V_threshold_out(Vt)
    );



    SM_Reg_File RF0 (
        .clk(CLK_I), .reset(RST_I),
        .commit(commit0),
        .done_g(done_g0),
        .done_h(done_h0),
        .h_t(h0_t),
        .g_t(g0_t),
        .next_f(next_f_0),
        .next_g_syn_bar(next_g_syn_bar_0),
        .next_T_rise(next_T_rise_0),
        .next_ho(next_ho_0),
        .next_AP(next_AP_0),
        .next_T_decay(next_T_decay_0),
        .next_h(next_h_0),
        .next_g(next_g_0),
        .next_Esyn(next_Esyn_0),
        .next_exception_h_t(exception_h0),

        .f(f0), .g_syn_bar(gsyn0), .T_rise(Trise0), .ho(ho0), .AP(AP0),
         .T_decay(Tdecay0), .h(h0), .g(g0), .Esyn(Esyn0), .flag_update_tn1(flag_update_tn1[0]), .exception_h_t(exception_h[0])
    );

    SM_Reg_File RF1 (
        .clk(CLK_I), .reset(RST_I),
        .commit(commit1),
        .done_g(done_g1),
        .done_h(done_h1),
        .h_t(h1_t),
        .g_t(g1_t),
        .next_f(next_f_1),
        .next_g_syn_bar(next_g_syn_bar_1),
        .next_T_rise(next_T_rise_1),
        .next_ho(next_ho_1),
        .next_AP(next_AP_1),
        .next_T_decay(next_T_decay_1),
        .next_h(next_h_1),
        .next_g(next_g_1),
        .next_Esyn(next_Esyn_1),
        .next_exception_h_t(exception_h1),

        .f(f1), .g_syn_bar(gsyn1), .T_rise(Trise1), .ho(ho1), .AP(AP1),
         .T_decay(Tdecay1), .h(h1),  .g(g1), .Esyn(Esyn1), .flag_update_tn1(flag_update_tn1[1]), .exception_h_t(exception_h[1])
    );

    SM_Reg_File RF2 (
        .clk(CLK_I), .reset(RST_I),
        .commit(commit2),
        .done_g(done_g2),
        .done_h(done_h2),
        .h_t(h2_t),
        .g_t(g2_t),
        .next_f(next_f_2),
        .next_g_syn_bar(next_g_syn_bar_2),
        .next_T_rise(next_T_rise_2),
        .next_ho(next_ho_2),
        .next_AP(next_AP_2),
        .next_T_decay(next_T_decay_2),
        .next_h(next_h_2),
        .next_g(next_g_2),
        .next_Esyn(next_Esyn_2),
        .next_exception_h_t(exception_h2),


        .f(f2), .g_syn_bar(gsyn2), .T_rise(Trise2), .ho(ho2), .AP(AP2),
         .T_decay(Tdecay2), .h(h2), .g(g2), .Esyn(Esyn2), .flag_update_tn1(flag_update_tn1[2]), .exception_h_t(exception_h[2])
    );

    SM_Reg_File RF3 (
        .clk(CLK_I), .reset(RST_I),
        .commit(commit3),
        .done_g(done_g3),
        .done_h(done_h3),
        .h_t(h3_t),
        .g_t(g3_t),
        .next_f(next_f_3),
        .next_g_syn_bar(next_g_syn_bar_3),
        .next_T_rise(next_T_rise_3),
        .next_ho(next_ho_3),
        .next_AP(next_AP_3),
        .next_T_decay(next_T_decay_3),
        .next_h(next_h_3),
        .next_g(next_g_3),
        .next_Esyn(next_Esyn_3),
        .next_exception_h_t(exception_h3),


        .f(f3), .g_syn_bar(gsyn3), .T_rise(Trise3), .ho(ho3), .AP(AP3),
         .T_decay(Tdecay3), .h(h3), .g(g3), .Esyn(Esyn3), .flag_update_tn1(flag_update_tn1[3]), .exception_h_t(exception_h[3])
    );
    
    wire  AP0_tn1, AP1_tn1,  AP2_tn1, AP3_tn1; 
    wire [31:0] h0_tn1, g0_tn1;
    wire [31:0] h1_tn1, g1_tn1;
    wire [31:0] h2_tn1, g2_tn1;
    wire [31:0] h3_tn1, g3_tn1;
    reg [3:0] enable_g, enable_h, enable_Isyn;
    wire done_g0, done_g1, done_g2, done_g3;
    wire done_h0, done_h1, done_h2, done_h3;
    wire done_Isyn0, done_Isyn1, done_Isyn2, done_Isyn3;
    wire exception_h0, exception_h1, exception_h2, exception_h3;
    wire exception_hg0, exception_hg1, exception_hg2, exception_hg3;
    
    wire exception_h0_tn1, exception_h1_tn1, exception_h2_tn1, exception_h3_tn1;


    wire [31:0] Isyn0, Isyn1, Isyn2, Isyn3;
    wire [31:0] IsynSum_0_1, IsynSum_2_3, IsynSum_all;
    wire [3:0] done_g, done_h, done_Isyn;
    assign done_g = {done_g0, done_g1, done_g2, done_g3};
    assign done_h = {done_h0, done_h1, done_h2, done_h3};
    assign done_Isyn = {done_Isyn0, done_Isyn1, done_Isyn2, done_Isyn3};

    
    SM_Reg_File_Synapse_tn1 Syn0_tn1(
        .clk(CLK_I),
        .reset(RST_I),
        .enable(flag_update_tn1[0]),
        .AP_t(AP0),       
        .h_t(h0),
        .g_t(g0),
        .AP_tn1(AP0_tn1),         
        .h_tn1(h0_tn1),
        .g_tn1(g0_tn1),
        .updated_regFile_tn1(updated_regFile_tn1[0]),
        .exception_h_t(exception_h[0]),
        .exception_h_tn1(exception_h0_tn1)
        
    );
    
    
     SM_Reg_File_Synapse_tn1 Syn1_tn1(
        .clk(CLK_I),
        .reset(RST_I),
        .enable(flag_update_tn1[1]),
        .AP_t(AP1),       
        .h_t(h1),
        .g_t(g1),
        .AP_tn1(AP1_tn1),         
        .h_tn1(h1_tn1),
        .g_tn1(g1_tn1),
        .updated_regFile_tn1(updated_regFile_tn1[1]),
        .exception_h_t(exception_h[1]),
        .exception_h_tn1(exception_h1_tn1)

    );
    
     SM_Reg_File_Synapse_tn1 Syn2_tn1(
        .clk(CLK_I),
        .reset(RST_I),
        .enable(flag_update_tn1[2]),
        .AP_t(AP2),       
        .h_t(h2),
        .g_t(g2),
        .AP_tn1(AP2_tn1),         
        .h_tn1(h2_tn1),
        .g_tn1(g2_tn1),
        .updated_regFile_tn1(updated_regFile_tn1[2]),
        .exception_h_t(exception_h[2]),
        .exception_h_tn1(exception_h2_tn1)

    );
    
       SM_Reg_File_Synapse_tn1 Syn3_tn1(
        .clk(CLK_I),
        .reset(RST_I),
        .enable(flag_update_tn1[3]),
        .AP_t(AP3),       
        .h_t(h3),
        .g_t(g3),
        .AP_tn1(AP3_tn1),         
        .h_tn1(h3_tn1),
        .g_tn1(g3_tn1),
        .updated_regFile_tn1(updated_regFile_tn1[3]),
        .exception_h_t(exception_h[3]),
        .exception_h_tn1(exception_h3_tn1)

    );
    
     SM_h_accumulator hUpdate0(
        .clk(CLK_I),
        .reset(reset_h),
        .enable_h(enable_h[0]),
        .h0(ho0),
        .h_tn1(h0_tn1),
        .tau_rise_inverse(Trise0),
        .actionPotential_tn1(AP0_tn1),
        .dt(dt),
        .h_t(h0_t),
        .exception(exception_h0),
        .done_h(done_h0)
    );
    
    
     SM_g_accumulator gUpdate0(
        .clk(CLK_I),
        .reset(reset_g),
        .enable_g(enable_g[0]),
        .h_tn1(h0_tn1),
        .g_tn1(g0_tn1),
        .tau_decay_inverse(Tdecay0),
        .dt(dt),
        .exception_h_tn1(exception_h0_tn1),
        .g_t(g0_t),
        .exception(exception_hg0),
        .done_g(done_g0)
        );


     SM_h_accumulator hUpdate1(
        .clk(CLK_I),
        .reset(reset_h),
        .enable_h(enable_h[1]),
        .h0(ho1),
        .h_tn1(h1_tn1),
        .tau_rise_inverse(Trise1),
        .actionPotential_tn1(AP1_tn1),
        .dt(dt),
        .h_t(h1_t),
        .exception(exception_h1),
        .done_h(done_h1)
    );
    
    
     SM_g_accumulator gUpdate1(
        .clk(CLK_I),
        .reset(reset_g),
        .enable_g(enable_g[1]),
        .h_tn1(h1_tn1),
        .g_tn1(g1_tn1),
        .tau_decay_inverse(Tdecay1),
        .dt(dt),
        .exception_h_tn1(exception_h1_tn1),
        .g_t(g1_t),
        .exception(exception_hg1),
        .done_g(done_g1)
        );
        
        
     SM_h_accumulator hUpdate2(
         .clk(CLK_I),
        .reset(reset_h),
        .enable_h(enable_h[2]),
        .h0(ho2),
        .h_tn1(h2_tn1),
        .tau_rise_inverse(Trise2),
        .actionPotential_tn1(AP2_tn1),
        .dt(dt),
        .h_t(h2_t),
        .exception(exception_h2),
        .done_h(done_h2)
    );
    
    
     SM_g_accumulator gUpdate2(
        .clk(CLK_I),
        .reset(reset_g),
        .enable_g(enable_g[2]),
        .h_tn1(h2_tn1),
        .g_tn1(g2_tn1),
        .tau_decay_inverse(Tdecay2),
        .dt(dt),
        .exception_h_tn1(exception_h2_tn1),
        .g_t(g2_t),
        .exception(exception_hg2),
        .done_g(done_g2)
        );

     SM_h_accumulator hUpdate3(
         .clk(CLK_I),
        .reset(reset_h),
        .enable_h(enable_h[3]),
        .h0(ho3),
        .h_tn1(h3_tn1),
        .tau_rise_inverse(Trise3),
        .actionPotential_tn1(AP3_tn1),
        .dt(dt),
        .h_t(h3_t),
        .exception(exception_h3),
        .done_h(done_h3)
    );
    
    
     SM_g_accumulator gUpdate3(
        .clk(CLK_I),
        .reset(reset_g),
        .enable_g(enable_g[3]),
        .h_tn1(h3_tn1),
        .g_tn1(g3_tn1),
        .tau_decay_inverse(Tdecay3),
        .dt(dt),
        .exception_h_tn1(exception_h3_tn1),
        .g_t(g3_t),
        .exception(exception_hg3),
        .done_g(done_g3)
        );


    
     SM_I_SYN_Accumulator IsynUpdate0(
        .clk(CLK_I),
        .reset(RST_I),
        .enable_i_syn(enable_Isyn[0]),
        .g_syn_bar(gsyn0),
        .f(f0),
        .g(g0_t),
        .Vmem(Vmem),
        .E_syn(Esyn0),
    
        .i_syn_sum(Isyn0),
        .done_i_syn(done_Isyn0)
    );

    
     SM_I_SYN_Accumulator IsynUpdate1(
        .clk(CLK_I),
        .reset(RST_I),
        .enable_i_syn(enable_Isyn[1]),
        .g_syn_bar(gsyn1),
        .f(f1),
        .g(g1_t),
        .Vmem(Vmem),
        .E_syn(Esyn1),
    
        .i_syn_sum(Isyn1),
        .done_i_syn(done_Isyn1)
    );
    
    SM_I_SYN_Accumulator IsynUpdate2(
        .clk(CLK_I),
        .reset(RST_I),
        .enable_i_syn(enable_Isyn[2]),
        .g_syn_bar(gsyn2),
        .f(f2),
        .g(g2_t),
        .Vmem(Vmem),
        .E_syn(Esyn2),
    
        .i_syn_sum(Isyn2),
        .done_i_syn(done_Isyn2)
    );


    
     SM_I_SYN_Accumulator IsynUpdate3(
        .clk(CLK_I),
        .reset(RST_I),
        .enable_i_syn(enable_Isyn[3]),
        .g_syn_bar(gsyn3),
        .f(f3),
        .g(g3_t),
        .Vmem(Vmem),
        .E_syn(Esyn3),
    
        .i_syn_sum(Isyn3),
        .done_i_syn(done_Isyn3)
    );

    FloatingAddition addIsyn_firstHalf(
        .A(Isyn0),
        .B(Isyn1),
        .Exception(),
        .result(IsynSum_0_1)
    );
    
    wire addIsyn_firstHalf_ready;
    wire addIsyn_secondHalf_ready;
    wire addIsyn_sumAll_ready;
    assign addIsyn_firstHalf_ready = done_Isyn[0] && done_Isyn[1];
    assign addIsyn_secondHalf_ready = done_Isyn[2] && done_Isyn[3];
    assign addIsyn_sumAll_ready = addIsyn_firstHalf_ready & addIsyn_secondHalf_ready;

    FloatingAddition addIsyn_secondHalf(
        .A(Isyn2),
        .B(Isyn3),
        .Exception(),
        .result(IsynSum_2_3)
    );
    
    FloatingAddition addIsyn_sumAll(
        .A(IsynSum_0_1),
        .B(IsynSum_2_3),
        .Exception(),
        .result(IsynSum_all)
    );
    
    
    //local parameters for state machine
    localparam state_setup = 3'b000;
    localparam state_no_gh = 3'b001;
    localparam state_gh_done = 3'b010;
    localparam state_Isyn_done = 3'b011;
    localparam state_send_IsynTotal = 3'b100;
    
    reg [2:0] present_state, next_state;
    
    always @(*) begin
            //default statements
            next_state = state_no_gh; 
            enable_g = 4'b0000;
            enable_h = 4'b0000;
            reset_g = 1'b0;
            reset_h = 1'b0;
            enable_Isyn = 4'b0000;
            case(present_state)
                state_setup : begin
                    next_state = (!RST_I && updated_regFile_tn1==4'hF) ? state_no_gh : state_setup;

                end
                state_no_gh: begin
                    enable_g = 4'b1111;
                    enable_h = 4'b1111;
                    reset_g = 1'b0;
                    reset_h = 1'b0;
                    next_state = (done_g == 4'hF && done_h == 4'hF && !RST_I) ? state_gh_done : state_no_gh;
                end
                state_gh_done: begin
                    enable_g = 4'b0000;
                    enable_h = 4'b0000;
                    enable_Isyn = 4'b1111; //calculate I syn
                    reset_g = 1'b0;          // <<< KEEP LOW
                    reset_h = 1'b0;          // <<< KEEP LOW
//                    reset_g = 1'b1;
//                    reset_h = 1'b1;
                    //next_state = (done_Isyn == 4'hF) ? state_Isyn_done : state_gh_done;
                    next_state = addIsyn_sumAll_ready ? state_send_IsynTotal : state_Isyn_done;

                end
                state_Isyn_done: begin
                    enable_Isyn = 4'b0000;
                    reset_g = 1'b0;
                    reset_h = 1'b0;
//                    reset_g = 1'b1;
//                    reset_h = 1'b1;
//                    enable_Isyn = 4'b0000;
                    
                    next_state = addIsyn_sumAll_ready ? state_send_IsynTotal : state_Isyn_done;
                end
                state_send_IsynTotal: begin
                    enable_Isyn = 4'b0000;
                    reset_g = 1'b1;
                    reset_h = 1'b1; 
                    next_state = state_no_gh;

                end
                default: begin 
                    next_state = present_state; 
                end  
            endcase
        
     end          
    
    always @(posedge CLK_I, posedge RST_I)
    begin
        if(RST_I == 1'b1)
            present_state <= state_setup;
        else
            present_state <= next_state;
    end
    
endmodule