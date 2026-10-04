//`timescale 1ns / 1ps

//module tb_SynapticModule_2;

//  reg RST_I;
//  reg CLK_I;

//  // Wishbone B3 (classic)
//  reg         CYC_I;
//  reg         STB_I;
//  reg         WE_I;
//  reg [31:0]  ADR_I;
//  reg [31:0]  DAT_I;
//  reg [3:0]   SEL_I;

//  wire        ACK_O;
//  wire [31:0] DAT_O;
//  wire        irq;

//  // DUT = SynapticModule with mem mapping inside
//  SynapticModule dut (
//    .RST_I(RST_I),
//    .CLK_I(CLK_I),

//    .CYC_I(CYC_I),
//    .STB_I(STB_I),
//    .WE_I (WE_I),
//    .ADR_I(ADR_I),
//    .DAT_I(DAT_I),
//    .SEL_I(SEL_I),

//    .ACK_O(ACK_O),
//    .DAT_O(DAT_O),

//    .irq(irq)
//  );

//  // 10ns clock
//  initial begin
//    CLK_I = 0;
//    forever #5 CLK_I = ~CLK_I;
//  end

//  // ----------------------------
//  // Address map (from your sheet)
//  // ----------------------------
//  localparam [31:0] BASE = 32'h3070_0000;

//  // Synapse base offsets
//  localparam [31:0] SYN0 = 32'h0000;
//  localparam [31:0] SYN1 = 32'h0100;
//  localparam [31:0] SYN2 = 32'h0200;
//  localparam [31:0] SYN3 = 32'h0300;

//  // Per-syn offsets
//  localparam [31:0] OFF_F         = 32'h00;
//  localparam [31:0] OFF_GSYNBAR   = 32'h04;
//  localparam [31:0] OFF_H0        = 32'h08;
//  localparam [31:0] OFF_ESYN      = 32'h0C;
//  localparam [31:0] OFF_TRISEINV  = 32'h10;
//  localparam [31:0] OFF_TDECAYINV = 32'h14;
//  localparam [31:0] OFF_H         = 32'h18;
//  localparam [31:0] OFF_G         = 32'h1C;
//  localparam [31:0] OFF_AP        = 32'h20;

//  // Global page
//  localparam [31:0] GLOB = 32'h0400;
//  localparam [31:0] OFF_DT      = 32'h00;
//  localparam [31:0] OFF_VMEM    = 32'h04;
//  localparam [31:0] OFF_VTHRESH = 32'h08;

//  // -----------------------------------------
//  // WB helper: single write, wait for ACK_O
//  // -----------------------------------------
//  task wb_write32;
//    input [31:0] addr;
//    input [31:0] data;
//    integer guard;
//    begin
//      guard = 0;

//      @(posedge CLK_I);
//      ADR_I <= addr;
//      DAT_I <= data;
//      SEL_I <= 4'hF;
//      WE_I  <= 1'b1;
//      CYC_I <= 1'b1;
//      STB_I <= 1'b1;

//      // wait for ack
//      while (ACK_O !== 1'b1) begin
//        @(posedge CLK_I);
//        guard = guard + 1;
//        if (guard > 100) begin
//          $display("WB TIMEOUT addr=%h data=%h time=%0t", addr, data, $time);
//          $stop;
//        end
//      end

//      // drop bus next cycle
//      @(posedge CLK_I);
//      CYC_I <= 1'b0;
//      STB_I <= 1'b0;
//      WE_I  <= 1'b0;
//      ADR_I <= 32'h0;
//      DAT_I <= 32'h0;
//      SEL_I <= 4'h0;
//    end
//  endtask

//  // -----------------------------------------
//  // helper: wait until DUT finishes a timestep
//  // EXACTLY like your standalone TB
//  // -----------------------------------------
//  task wait_step_done;
//    integer guard;
//    begin
//      guard = 0;

//      // wait to ENTER send state
//      while (dut.present_state !== 3'b100) begin
//        @(posedge CLK_I);
//        guard = guard + 1;
//        if (guard > 5000) begin
//          $display("TIMEOUT waiting for send state. present_state=%b time=%0t",
//                   dut.present_state, $time);
//          $stop;
//        end
//      end

//      // wait to LEAVE send state
//      while (dut.present_state === 3'b100) begin
//        @(posedge CLK_I);
//      end
//    end
//  endtask

//  // -----------------------------------------
//  // init one synapse (same values as your TB)
//  // -----------------------------------------
//  task init_syn;
//    input [31:0] syn_off;
//    begin
//      wb_write32(BASE + syn_off + OFF_GSYNBAR,   32'h3e800000); // 0.25
//      wb_write32(BASE + syn_off + OFF_F,         32'h3e900000); // 0.28125
//      wb_write32(BASE + syn_off + OFF_TRISEINV,  32'h3e4ccccd); // 0.2
//      wb_write32(BASE + syn_off + OFF_H0,        32'h3f000000); // 0.5
//      wb_write32(BASE + syn_off + OFF_AP,        32'h00000000); // 0
//      wb_write32(BASE + syn_off + OFF_TDECAYINV, 32'h3f000000); // 0.5
//      wb_write32(BASE + syn_off + OFF_H,         32'h3f000000); // 0.5
//      wb_write32(BASE + syn_off + OFF_G,         32'h3e700000); // ~0.234
//      wb_write32(BASE + syn_off + OFF_ESYN,      32'h3f200000); // 0.625
//    end
//  endtask
 

//  integer step;

//  initial begin
//    // init WB to known values
//    CYC_I = 0; STB_I = 0; WE_I = 0;
//    ADR_I = 0; DAT_I = 0; SEL_I = 0;

//    // reset
//    RST_I = 1;

//    // dump
//    $dumpfile("tb_SynapticModule_2.vcd");
//    $dumpvars(0, tb_SynapticModule_2);

//    // release reset
//    repeat (4) @(posedge CLK_I);
//    RST_I = 0;

//    // -------------------------
//    // "commitStatic" equivalent:
//    // write dt/Vmem/Vt via WB
//    // -------------------------
//    wb_write32(BASE + GLOB + OFF_DT,      32'h3f000000); // 0.5
//    wb_write32(BASE + GLOB + OFF_VMEM,    32'h3ee00000); // 0.4375
//    wb_write32(BASE + GLOB + OFF_VTHRESH, 32'h3f200000); // 0.625

//    // -------------------------
//    // "commit all synapses":
//    // init syn0..syn3 via WB
//    // -------------------------
//    init_syn(SYN0);
//    init_syn(SYN1);
//    init_syn(SYN2);
//    init_syn(SYN3);

//    // Now run EXACTLY 8 timesteps (identical loop)
//    for (step = 0; step < 8; step = step + 1) begin

//      // AP changes once per timestep BEFORE the computation
//      if (step[0] == 1'b0) begin
//        wb_write32(BASE + SYN0 + OFF_AP, 32'h00000000);
//        wb_write32(BASE + SYN1 + OFF_AP, 32'h00000000);
//        wb_write32(BASE + SYN2 + OFF_AP, 32'h00000000);
//        wb_write32(BASE + SYN3 + OFF_AP, 32'h00000000);
//      end else begin
//        wb_write32(BASE + SYN0 + OFF_AP, 32'h00000001);
//        wb_write32(BASE + SYN1 + OFF_AP, 32'h00000001);
//        wb_write32(BASE + SYN2 + OFF_AP, 32'h00000001);
//        wb_write32(BASE + SYN3 + OFF_AP, 32'h00000001);
//      end

//      // wait until DUT finishes this timestep (h/g + Isyn complete)
//      wait_step_done();

//      // same style print (signals exist in SynapticModule too)
//      $display("step=%0d time=%0t AP0=%b h0_t=%h g0_t=%h IsynSum=%h",
//               step, $time, dut.AP0, dut.h0_t, dut.g0_t, dut.IsynSum_all);
//    end

//    $finish;
//  end

//endmodule





//`timescale 1ns / 1ps

//module tb_SynapticModule_2;

//  reg RST_I;
//  reg CLK_I;

//  // Wishbone B3 (classic)
//  reg         CYC_I;
//  reg         STB_I;
//  reg         WE_I;
//  reg [31:0]  ADR_I;
//  reg [31:0]  DAT_I;
//  reg [3:0]   SEL_I;

//  wire        ACK_O;
//  wire [31:0] DAT_O;
//  wire        irq;

//  // DUT = SynapticModule with mem mapping inside
//  SynapticModule dut (
//    .RST_I(RST_I),
//    .CLK_I(CLK_I),

//    .CYC_I(CYC_I),
//    .STB_I(STB_I),
//    .WE_I (WE_I),
//    .ADR_I(ADR_I),
//    .DAT_I(DAT_I),
//    .SEL_I(SEL_I),

//    .ACK_O(ACK_O),
//    .DAT_O(DAT_O),

//    .irq(irq)
//  );

//  // 10ns clock
//  initial begin
//    CLK_I = 0;
//    forever #5 CLK_I = ~CLK_I;
//  end

//  // ----------------------------
//  // Address map
//  // ----------------------------
//  localparam [31:0] BASE = 32'h3070_0000;

//  // Synapse base offsets
//  localparam [31:0] SYN0 = 32'h0000;
//  localparam [31:0] SYN1 = 32'h0100;
//  localparam [31:0] SYN2 = 32'h0200;
//  localparam [31:0] SYN3 = 32'h0300;

//  // Per-syn offsets
//  localparam [31:0] OFF_F         = 32'h00;
//  localparam [31:0] OFF_GSYNBAR   = 32'h04;
//  localparam [31:0] OFF_H0        = 32'h08;
//  localparam [31:0] OFF_ESYN      = 32'h0C;
//  localparam [31:0] OFF_TRISEINV  = 32'h10;
//  localparam [31:0] OFF_TDECAYINV = 32'h14;
//  localparam [31:0] OFF_H         = 32'h18;
//  localparam [31:0] OFF_G         = 32'h1C;
//  localparam [31:0] OFF_AP        = 32'h20;
//  localparam [31:0] OFF_COMMIT    = 32'h24;

//  // Global page
//  localparam [31:0] GLOB             = 32'h0400;
//  localparam [31:0] OFF_DT           = 32'h00;
//  localparam [31:0] OFF_VMEM         = 32'h04;
//  localparam [31:0] OFF_VTHRESH      = 32'h08;
//  localparam [31:0] OFF_COMMITSTATIC = 32'h0C;

//  // -----------------------------------------
//  // WB helper: single write, wait for ACK_O
//  // -----------------------------------------
//  task wb_write32;
//    input [31:0] addr;
//    input [31:0] data;
//    integer guard;
//    begin
//      guard = 0;

//      @(posedge CLK_I);
//      ADR_I <= addr;
//      DAT_I <= data;
//      SEL_I <= 4'hF;
//      WE_I  <= 1'b1;
//      CYC_I <= 1'b1;
//      STB_I <= 1'b1;

//      // wait for ack
//      while (ACK_O !== 1'b1) begin
//        @(posedge CLK_I);
//        guard = guard + 1;
//        if (guard > 100) begin
//          $display("WB TIMEOUT addr=%h data=%h time=%0t", addr, data, $time);
//          $stop;
//        end
//      end

//      // drop bus next cycle
//      @(posedge CLK_I);
//      CYC_I <= 1'b0;
//      STB_I <= 1'b0;
//      WE_I  <= 1'b0;
//      ADR_I <= 32'h0;
//      DAT_I <= 32'h0;
//      SEL_I <= 4'h0;
//    end
//  endtask

//  // -----------------------------------------
//  // explicit commit helpers
//  // -----------------------------------------
//  task commit_static;
//    begin
//      wb_write32(BASE + GLOB + OFF_COMMITSTATIC, 32'h00000001);
//    end
//  endtask

//  task commit_syn;
//    input [31:0] syn_off;
//    begin
//      wb_write32(BASE + syn_off + OFF_COMMIT, 32'h00000001);
//    end
//  endtask

//  task commit_all_syns;
//    begin
//      commit_syn(SYN0);
//      commit_syn(SYN1);
//      commit_syn(SYN2);
//      commit_syn(SYN3);
//    end
//  endtask

//  // -----------------------------------------
//  // helper: wait until DUT finishes a timestep
//  // -----------------------------------------
//  task wait_step_done;
//    integer guard;
//    begin
//      guard = 0;

//      // wait to ENTER send state
//      while (dut.present_state !== 3'b100) begin
//        @(posedge CLK_I);
//        guard = guard + 1;
//        if (guard > 5000) begin
//          $display("TIMEOUT waiting for send state. present_state=%b time=%0t",
//                   dut.present_state, $time);
//          $display("static_seen=%b syn_seen=%b commitStatic=%b commits=%b%b%b%b",
//                   dut.static_seen, dut.syn_seen,
//                   dut.commitStatic, dut.commit3, dut.commit2, dut.commit1, dut.commit0);
//          $stop;
//        end
//      end

//      // wait to LEAVE send state
//      while (dut.present_state === 3'b100) begin
//        @(posedge CLK_I);
//      end
//    end
//  endtask

//  // -----------------------------------------
//  // init one synapse
//  // -----------------------------------------
//  task init_syn;
//    input [31:0] syn_off;
//    begin
//      wb_write32(BASE + syn_off + OFF_GSYNBAR,   32'h3e800000); // 0.25
//      wb_write32(BASE + syn_off + OFF_F,         32'h3e900000); // 0.28125
//      wb_write32(BASE + syn_off + OFF_TRISEINV,  32'h3e4ccccd); // 0.2
//      wb_write32(BASE + syn_off + OFF_H0,        32'h3f000000); // 0.5
//      wb_write32(BASE + syn_off + OFF_AP,        32'h00000000); // 0
//      wb_write32(BASE + syn_off + OFF_TDECAYINV, 32'h3f000000); // 0.5
//      wb_write32(BASE + syn_off + OFF_H,         32'h3f000000); // 0.5
//      wb_write32(BASE + syn_off + OFF_G,         32'h3e700000); // ~0.234
//      wb_write32(BASE + syn_off + OFF_ESYN,      32'h3f200000); // 0.625

//      // THIS IS THE IMPORTANT PART
//      commit_syn(syn_off);
//    end
//  endtask

//  integer step;

//  initial begin
//    // init WB to known values
//    CYC_I = 0;
//    STB_I = 0;
//    WE_I  = 0;
//    ADR_I = 0;
//    DAT_I = 0;
//    SEL_I = 0;

//    // reset
//    RST_I = 1;

//    // dump
//    $dumpfile("tb_SynapticModule_2.vcd");
//    $dumpvars(0, tb_SynapticModule_2);

//    // release reset
//    repeat (4) @(posedge CLK_I);
//    RST_I = 0;

//    // -------------------------
//    // write static values
//    // -------------------------
//    wb_write32(BASE + GLOB + OFF_DT,      32'h3f000000); // 0.5
//    wb_write32(BASE + GLOB + OFF_VMEM,    32'h3ee00000); // 0.4375
//    wb_write32(BASE + GLOB + OFF_VTHRESH, 32'h3f200000); // 0.625

//    // commit static register file
//    commit_static();

//    // -------------------------
//    // init syn0..syn3 via WB
//    // each init_syn now also commits
//    // -------------------------
//    init_syn(SYN0);
//    init_syn(SYN1);
//    init_syn(SYN2);
//    init_syn(SYN3);

//    // optional: wait a couple cycles after setup commits
//    repeat (2) @(posedge CLK_I);

//    // Now run EXACTLY 8 timesteps
////    for (step = 0; step < 8; step = step + 1) begin
//    for (step = 0; step < 5; step = step + 1) begin

//      // AP changes once per timestep BEFORE the computation
//      if (step == 0 || step == 1 || step == 3) begin
//        wb_write32(BASE + SYN0 + OFF_AP, 32'h00000000);
//        wb_write32(BASE + SYN1 + OFF_AP, 32'h00000000);
//        wb_write32(BASE + SYN2 + OFF_AP, 32'h00000000);
//        wb_write32(BASE + SYN3 + OFF_AP, 32'h00000000);
//      end else begin
//        wb_write32(BASE + SYN0 + OFF_AP, 32'h00000001);
//        wb_write32(BASE + SYN1 + OFF_AP, 32'h00000001);
//        wb_write32(BASE + SYN2 + OFF_AP, 32'h00000001);
//        wb_write32(BASE + SYN3 + OFF_AP, 32'h00000001);
//      end
////      if (step[0] == 1'b0) begin
////        wb_write32(BASE + SYN0 + OFF_AP, 32'h00000000);
////        wb_write32(BASE + SYN1 + OFF_AP, 32'h00000000);
////        wb_write32(BASE + SYN2 + OFF_AP, 32'h00000000);
////        wb_write32(BASE + SYN3 + OFF_AP, 32'h00000000);
////      end else begin
////        wb_write32(BASE + SYN0 + OFF_AP, 32'h00000001);
////        wb_write32(BASE + SYN1 + OFF_AP, 32'h00000001);
////        wb_write32(BASE + SYN2 + OFF_AP, 32'h00000001);
////        wb_write32(BASE + SYN3 + OFF_AP, 32'h00000001);
////      end

//      // commit AP updates into all 4 synapse regfiles
//      commit_all_syns();

//      // wait until DUT finishes this timestep (h/g + Isyn complete)
//      wait_step_done();

//      $display("step=%0d time=%0t AP0=%b h0_t=%h g0_t=%h IsynSum=%h state=%b",
//               step, $time, dut.AP0, dut.h0_t, dut.g0_t, dut.IsynSum_all, dut.present_state);
//    end

//    $finish;
//  end
  
//  always @(posedge CLK_I) begin
//    if (dut.commit0) begin
//        $display("time=%0t COMMIT0: next_h_0=%h next_g_0=%h h0=%h g0=%h",
//                $time, dut.next_h_0, dut.next_g_0, dut.h0, dut.g0);
//    end
//    if (dut.commit1) begin
//        $display("time=%0t COMMIT1: next_h_1=%h next_g_1=%h h1=%h g1=%h",
//                $time, dut.next_h_1, dut.next_g_1, dut.h1, dut.g1);
//    end
//    if (dut.commit2) begin
//        $display("time=%0t COMMIT2: next_h_2=%h next_g_2=%h h2=%h g2=%h",
//                $time, dut.next_h_2, dut.next_g_2, dut.h2, dut.g2);
//    end
//    if (dut.commit3) begin
//        $display("time=%0t COMMIT3: next_h_3=%h next_g_3=%h h3=%h g3=%h",
//                $time, dut.next_h_3, dut.next_g_3, dut.h3, dut.g3);
//    end
//  end

//endmodule












`timescale 1ns / 1ps

module tb_SynapticModule_2;

  reg RST_I;
  reg CLK_I;
  reg step_en;

  // Wishbone B3
  reg         CYC_I;
  reg         STB_I;
  reg         WE_I;
  reg [31:0]  ADR_I;
  reg [31:0]  DAT_I;
  reg [3:0]   SEL_I;

  wire        ACK_O;
  wire [31:0] DAT_O;
  wire        irq;

  // DUT
  SynapticModule dut (
    .RST_I(RST_I),
    .CLK_I(CLK_I),
    .step_en(step_en),

    .CYC_I(CYC_I),
    .STB_I(STB_I),
    .WE_I (WE_I),
    .ADR_I(ADR_I),
    .DAT_I(DAT_I),
    .SEL_I(SEL_I),

    .ACK_O(ACK_O),
    .DAT_O(DAT_O),

    .irq(irq)
  );

  // 10ns clock
  initial begin
    CLK_I = 0;
    forever #1 CLK_I = ~CLK_I;
  end

  // ----------------------------
  // Address map
  // ----------------------------
  localparam [31:0] BASE = 32'h3070_0000;

  localparam [31:0] SYN0 = 32'h0000;
  localparam [31:0] SYN1 = 32'h0100;
  localparam [31:0] SYN2 = 32'h0200;
  localparam [31:0] SYN3 = 32'h0300;

  localparam [31:0] OFF_F         = 32'h00;
  localparam [31:0] OFF_GSYNBAR   = 32'h04;
  localparam [31:0] OFF_H0        = 32'h08;
  localparam [31:0] OFF_ESYN      = 32'h0C;
  localparam [31:0] OFF_TRISEINV  = 32'h10;
  localparam [31:0] OFF_TDECAYINV = 32'h14;
  localparam [31:0] OFF_H         = 32'h18;
  localparam [31:0] OFF_G         = 32'h1C;
  localparam [31:0] OFF_AP        = 32'h20;
  localparam [31:0] OFF_COMMIT    = 32'h24;

  localparam [31:0] GLOB             = 32'h0400;
  localparam [31:0] OFF_DT           = 32'h00;
  localparam [31:0] OFF_VMEM         = 32'h04;
  localparam [31:0] OFF_VTHRESH      = 32'h08;
  localparam [31:0] OFF_COMMITSTATIC = 32'h0C;

  integer step;

  // -----------------------------------------
  // WB helper: single write, wait for ACK_O
  // -----------------------------------------
  task wb_write32;
    input [31:0] addr;
    input [31:0] data;
    integer guard;
    begin
      guard = 0;

      @(posedge CLK_I);
      ADR_I <= addr;
      DAT_I <= data;
      SEL_I <= 4'hF;
      WE_I  <= 1'b1;
      CYC_I <= 1'b1;
      STB_I <= 1'b1;

      while (ACK_O !== 1'b1) begin
        @(posedge CLK_I);
        guard = guard + 1;
        if (guard > 100) begin
          $display("WB TIMEOUT addr=%h data=%h time=%0t", addr, data, $time);
          $stop;
        end
      end

      @(posedge CLK_I);
      CYC_I <= 1'b0;
      STB_I <= 1'b0;
      WE_I  <= 1'b0;
      ADR_I <= 32'h0;
      DAT_I <= 32'h0;
      SEL_I <= 4'h0;
    end
  endtask

  // -----------------------------------------
  // Commit helpers
  // -----------------------------------------
  task commit_static;
    begin
      wb_write32(BASE + GLOB + OFF_COMMITSTATIC, 32'h00000001);
    end
  endtask

  task commit_syn;
    input [31:0] syn_off;
    begin
      wb_write32(BASE + syn_off + OFF_COMMIT, 32'h00000001);
    end
  endtask

  task commit_all_syns;
    begin
      commit_syn(SYN0);
      commit_syn(SYN1);
      commit_syn(SYN2);
      commit_syn(SYN3);
    end
  endtask

  // -----------------------------------------
  // Initialize one synapse
  // -----------------------------------------
  task init_syn;
    input [31:0] syn_off;
    begin
//        wb_write32(BASE + syn_off + OFF_GSYNBAR,   32'h3456bf95); // 2.0e-07
//        wb_write32(BASE + syn_off + OFF_F,         32'hbf413a93); // -0.7548
//        wb_write32(BASE + syn_off + OFF_TRISEINV,  32'h3ecccccd); // 0.4 = 1/2.5
//        wb_write32(BASE + syn_off + OFF_H0,        32'h3d0f5c29); // 0.035
//        wb_write32(BASE + syn_off + OFF_AP,        32'h00000000); // set per timestep below
//        wb_write32(BASE + syn_off + OFF_TDECAYINV, 32'h3dba2e8c); // 1/11
//        wb_write32(BASE + syn_off + OFF_H,         32'h3d0f5c29); // h_0 = 0.035
//        wb_write32(BASE + syn_off + OFF_G,         32'h00000000); // g_0 = 0
//        wb_write32(BASE + syn_off + OFF_ESYN,      32'h3d3851ec); // 0.045
        
      wb_write32(BASE + syn_off + OFF_GSYNBAR,   32'h3e800000); // 0.25
      wb_write32(BASE + syn_off + OFF_F,         32'h3e900000); // 0.28125
      wb_write32(BASE + syn_off + OFF_TRISEINV,  32'h3e4ccccd); // 0.2
      wb_write32(BASE + syn_off + OFF_H0,        32'h3f000000); // 0.5
      wb_write32(BASE + syn_off + OFF_AP,        32'h00000000); // 0
      wb_write32(BASE + syn_off + OFF_TDECAYINV, 32'h3f000000); // 0.5
      wb_write32(BASE + syn_off + OFF_H,         32'h3f000000); // 0.5
      wb_write32(BASE + syn_off + OFF_G,         32'h3e700000); // ~0.234375
      wb_write32(BASE + syn_off + OFF_ESYN,      32'h3f200000); // 0.625

      commit_syn(syn_off);
    end
  endtask

  // -----------------------------------------
  // Load AP for the next timestep
  // Debug mode: only SYN0 toggles, SYN1-3 stay 0
  // -----------------------------------------
  task load_ap_for_step;
    input integer step_num;
    reg ap_bit;
    begin
      ap_bit = ~step_num[0];

      wb_write32(BASE + SYN0 + OFF_AP, {31'b0, ap_bit});
      wb_write32(BASE + SYN1 + OFF_AP, {31'b0, ap_bit});
      wb_write32(BASE + SYN2 + OFF_AP, {31'b0, ap_bit});
      wb_write32(BASE + SYN3 + OFF_AP, {31'b0, ap_bit});
//      commit_syn(SYN0);

//      commit_all_syns();
      wb_write32(BASE + SYN0 + OFF_COMMIT, 32'h1);
      

      $display("Loaded AP0=%0d for timestep %0d at time %0t",
               ap_bit, step_num, $time);
    end
  endtask

  // -----------------------------------------
  // Run exactly one timestep
  // Requires SynapticModule state_gap to wait for step_en
  // and state_send_IsynTotal = 3'b101
  // -----------------------------------------
  task run_one_timestep;
    integer guard;
    begin
      // launch one timestep
//      @(posedge CLK_I);
      step_en <= 1'b1;

      @(posedge CLK_I);
      step_en <= 1'b0;

      // wait to ENTER done/send state
      guard = 0;
      while (dut.present_state !== 3'b101) begin
        @(posedge CLK_I);
        guard = guard + 1;
        if (guard > 5000) begin
          $display("TIMEOUT waiting for timestep done. state=%b time=%0t",
                   dut.present_state, $time);
          $stop;
        end
      end

      // wait to LEAVE done/send state and return toward gap
      while (dut.present_state === 3'b101) begin
        @(posedge CLK_I);
      end
    end
  endtask

  initial begin
    // init WB + control
    CYC_I   = 0;
    STB_I   = 0;
    WE_I    = 0;
    ADR_I   = 0;
    DAT_I   = 0;
    SEL_I   = 0;
    step_en = 0;

    // reset
    RST_I = 1;

    $dumpfile("tb_SynapticModule_2.vcd");
    $dumpvars(0, tb_SynapticModule_2);

    repeat (4) @(posedge CLK_I);
    RST_I = 0;

    // -------------------------
    // Write static values
    // -------------------------
    wb_write32(BASE + GLOB + OFF_DT,      32'h3f000000); // 0.5
    wb_write32(BASE + GLOB + OFF_VMEM,    32'h3ee00000); // 0.4375
//    wb_write32(BASE + GLOB + OFF_DT,      32'h3a83126f); // 0.001
//    wb_write32(BASE + GLOB + OFF_VMEM,    32'hc27a0000); // -62.5
    wb_write32(BASE + GLOB + OFF_VTHRESH, 32'h3f200000); // 0.625
    commit_static();

    // -------------------------
    // Init syn0..syn3
    // -------------------------
    init_syn(SYN0);
    init_syn(SYN1);
    init_syn(SYN2);
    init_syn(SYN3);

    // allow DUT to settle in state_gap
    repeat (1) @(posedge CLK_I);

    // -------------------------
    // Run exactly 10 timesteps
    // -------------------------
    for (step = 0; step < 10; step = step + 1) begin
      // DUT should be parked in state_gap here
      load_ap_for_step(step);

      // optional extra cycle after commit
//      @(posedge CLK_I);

      run_one_timestep();

      $display("TIMESTEP %0d DONE: time=%0t AP0=%0d h0_t=%h g0_t=%h Isyn0=%h IsynSum_all=%h state=%b",
               step, $time, dut.AP0, dut.h0_t, dut.g0_t, dut.Isyn0, dut.IsynSum_all, dut.present_state);
    end

    repeat (10) @(posedge CLK_I);
    $finish;
  end

  // Optional debug prints
  always @(posedge CLK_I) begin
    if (dut.commit0) begin
      $display("time=%0t COMMIT0: AP0=%0d next_AP_0=%h h0=%h g0=%h",
               $time, dut.AP0, dut.next_AP_0, dut.h0, dut.g0);
    end
    if (dut.enable_h != 4'b0000 || dut.enable_g != 4'b0000 || dut.enable_Isyn != 4'b0000) begin
      $display("time=%0t state=%b step_en=%b enable_h=%b enable_g=%b enable_Isyn=%b",
               $time, dut.present_state, step_en, dut.enable_h, dut.enable_g, dut.enable_Isyn);
    end
  end

endmodule