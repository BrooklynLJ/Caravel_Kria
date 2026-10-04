`timescale 1ns / 1ps

module tb_SynapticModule_Standalone;

  reg RST_I;
  reg CLK_I;

  reg commitStatic;
  reg commit0, commit1, commit2, commit3;

  reg [31:0] next_dt, next_Vmem, next_Vt;

  reg [31:0] next_f_0, next_g_syn_bar_0, next_T_rise_0, next_ho_0, next_AP_0, next_T_decay_0, next_h_0, next_g_0, next_Esyn_0;
  reg [31:0] next_f_1, next_g_syn_bar_1, next_T_rise_1, next_ho_1, next_AP_1, next_T_decay_1, next_h_1, next_g_1, next_Esyn_1;
  reg [31:0] next_f_2, next_g_syn_bar_2, next_T_rise_2, next_ho_2, next_AP_2, next_T_decay_2, next_h_2, next_g_2, next_Esyn_2;
  reg [31:0] next_f_3, next_g_syn_bar_3, next_T_rise_3, next_ho_3, next_AP_3, next_T_decay_3, next_h_3, next_g_3, next_Esyn_3;

  wire irq;

  SynapticModule_Standalone dut (
    .RST_I(RST_I),
    .CLK_I(CLK_I),

    .commitStatic(commitStatic),
    .commit0(commit0), .commit1(commit1), .commit2(commit2), .commit3(commit3),

    .next_dt(next_dt), .next_Vmem(next_Vmem), .next_Vt(next_Vt),

    .next_f_0(next_f_0), .next_g_syn_bar_0(next_g_syn_bar_0), .next_T_rise_0(next_T_rise_0), .next_ho_0(next_ho_0),
    .next_AP_0(next_AP_0), .next_T_decay_0(next_T_decay_0), .next_h_0(next_h_0), .next_g_0(next_g_0), .next_Esyn_0(next_Esyn_0),

    .next_f_1(next_f_1), .next_g_syn_bar_1(next_g_syn_bar_1), .next_T_rise_1(next_T_rise_1), .next_ho_1(next_ho_1),
    .next_AP_1(next_AP_1), .next_T_decay_1(next_T_decay_1), .next_h_1(next_h_1), .next_g_1(next_g_1), .next_Esyn_1(next_Esyn_1),

    .next_f_2(next_f_2), .next_g_syn_bar_2(next_g_syn_bar_2), .next_T_rise_2(next_T_rise_2), .next_ho_2(next_ho_2),
    .next_AP_2(next_AP_2), .next_T_decay_2(next_T_decay_2), .next_h_2(next_h_2), .next_g_2(next_g_2), .next_Esyn_2(next_Esyn_2),

    .next_f_3(next_f_3), .next_g_syn_bar_3(next_g_syn_bar_3), .next_T_rise_3(next_T_rise_3), .next_ho_3(next_ho_3),
    .next_AP_3(next_AP_3), .next_T_decay_3(next_T_decay_3), .next_h_3(next_h_3), .next_g_3(next_g_3), .next_Esyn_3(next_Esyn_3),

    .irq(irq)
  );
  
  
  // 10ns clock
  initial begin
    CLK_I = 0;
    forever #5 CLK_I = ~CLK_I;
  end

  // --- helper: pulse commit0..3 for 1 cycle ---
  task automatic pulse_commit_all;
    begin
      @(posedge CLK_I);
      commit0 = 1; commit1 = 1; commit2 = 1; commit3 = 1;
      @(posedge CLK_I);
      commit0 = 0; commit1 = 0; commit2 = 0; commit3 = 0;
    end
  endtask

  // --- helper: wait until DUT finishes a timestep ---
  // Uses internal FSM state: state_send_IsynTotal = 3'b100
  // Then waits until it leaves that state so we don't immediately "re-detect" it.
  task automatic wait_step_done;
    integer guard;
    begin
      guard = 0;

      // wait to ENTER send state
      while (dut.present_state !== 3'b100) begin
        @(posedge CLK_I);
        guard = guard + 1;
        if (guard > 5000) begin
          $display("TIMEOUT waiting for send state. present_state=%b time=%0t", dut.present_state, $time);
          $stop;
        end
      end

      // wait to LEAVE send state (so next timestep has a clean edge)
      while (dut.present_state === 3'b100) begin
        @(posedge CLK_I);
      end
    end
  endtask

  integer step;

  initial begin
    // init
    RST_I = 1;
    commitStatic = 0;
    commit0 = 0; commit1 = 0; commit2 = 0; commit3 = 0;

    // blocking init (no X)
    next_dt   = 32'h3f000000; // 0.5
    next_Vmem = 32'h3ee00000; // 0.4375
    next_Vt   = 32'h3f200000; // 0.625

    next_g_syn_bar_0 = 32'h3e800000; // 0.25
    next_f_0         = 32'h3e900000; // 0.28125
    next_T_rise_0    = 32'h3e4ccccd; // 0.2
    next_ho_0        = 32'h3f000000; // 0.5
    next_AP_0        = 32'h00000000;
    next_T_decay_0   = 32'h3f000000; // 0.5
    next_h_0         = 32'h3f000000; // 0.5
    next_g_0         = 32'h3e700000; // ~0.234
    next_Esyn_0      = 32'h3f200000; // 0.625

    // copy to others
    next_g_syn_bar_1 = next_g_syn_bar_0; next_f_1 = next_f_0; next_T_rise_1 = next_T_rise_0; next_ho_1 = next_ho_0;
    next_AP_1 = 32'h00000000; next_T_decay_1 = next_T_decay_0; next_h_1 = next_h_0; next_g_1 = next_g_0; next_Esyn_1 = next_Esyn_0;

    next_g_syn_bar_2 = next_g_syn_bar_0; next_f_2 = next_f_0; next_T_rise_2 = next_T_rise_0; next_ho_2 = next_ho_0;
    next_AP_2 = 32'h00000000; next_T_decay_2 = next_T_decay_0; next_h_2 = next_h_0; next_g_2 = next_g_0; next_Esyn_2 = next_Esyn_0;

    next_g_syn_bar_3 = next_g_syn_bar_0; next_f_3 = next_f_0; next_T_rise_3 = next_T_rise_0; next_ho_3 = next_ho_0;
    next_AP_3 = 32'h00000000; next_T_decay_3 = next_T_decay_0; next_h_3 = next_h_0; next_g_3 = next_g_0; next_Esyn_3 = next_Esyn_0;

    // dump
    $dumpfile("tb_SynapticModule_Standalone.vcd");
    $dumpvars(0, tb_SynapticModule_Standalone);

    // release reset
    repeat (4) @(posedge CLK_I);
    RST_I = 0;

    // commit static for 1 cycle
    @(posedge CLK_I);
    commitStatic = 1;
    @(posedge CLK_I);
    commitStatic = 0;

    // commit all synapses for 1 cycle
    pulse_commit_all();

    // Now run EXACTLY 8 timesteps
    for (step = 0; step < 8; step = step + 1) begin
      // AP changes once per timestep BEFORE the computation
      // Example pattern: 0,1,0,1,... for all synapses
      if (step[0] == 1'b0) begin
        next_AP_0 = 32'h00000000;
        next_AP_1 = 32'h00000000;
        next_AP_2 = 32'h00000000;
        next_AP_3 = 32'h00000000;
      end else begin
        next_AP_0 = 32'h00000001;
        next_AP_1 = 32'h00000001;
        next_AP_2 = 32'h00000001;
        next_AP_3 = 32'h00000001;
      end

      // load AP into regfiles
      pulse_commit_all();

      // wait until DUT finishes this timestep (h/g + Isyn complete)
      wait_step_done();

      // optional prints (remove if you just want waves)
      $display("step=%0d time=%0t AP0=%b h0_t=%h g0_t=%h IsynSum=%h",
               step, $time, dut.AP0, dut.h0_t, dut.g0_t, dut.IsynSum_all);
    end

    $finish;
  end

endmodule