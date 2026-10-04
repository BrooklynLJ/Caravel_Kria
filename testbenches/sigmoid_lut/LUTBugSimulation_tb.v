`timescale 1ns / 1ps
`define HALF_CYCLE 5

//------------------------------------------------------------------------------
// LUTBugSimulation_tb.v  (baseline-style TB) (note: file type is set to SystemVerilog in Vivado)
//------------------------------------------------------------------------------
// Targets: LUT_Module
// Goal:
//   - Isolate LUT coefficient corruption by running two scenarios:
//       (1) CPU-only: WB3 loads tables + WB3 compute. E.g, Directly send signals to the LUT to test if the LUT calculations rewrite their own values.
//       (2) DMA->CPU: WB4 loads tables + WB3 compute. E.g, Use the DMA to send signals to the LUT to test if the write/read of the DMA changes the LUT values.
//
// Notes:
//   - WB4 "DMA" traffic is emulated by driving wb4_* master signals in the TB.
//   - Coefficient init vectors are taken from loadMemory() in our_userspace.c.
//------------------------------------------------------------------------------

module LUTBugSimulation_tb();

  // Universal
  reg clock, reset;

  // Wishbone B3 (processor-side)
  reg         wb3_cyc_i, wb3_stb_i, wb3_we_i;
  reg [31:0]  wb3_adr_i;
  reg [3:0]   wb3_sel_i;
  reg [31:0]  wb3_dat_i;
  wire [31:0] wb3_dat_o;
  wire        wb3_ack_o;

  // Wishbone B4 (DMA-side)
  reg         wb4_cyc_i, wb4_stb_i, wb4_we_i;
  reg [31:0]  wb4_adr_i;
  reg [3:0]   wb4_sel_i;
  reg [31:0]  wb4_dat_i;
  wire [31:0] wb4_dat_o;
  wire        wb4_ack_o, wb4_stall_o, wb4_err_o;

  // Diagnostic flags from LUT
  wire Exception, Invalid, Overflow, Underflow;

  // DUT
  LUT_Module dut (
    .clock(clock),
    .reset(reset),

    .wb3_cyc_i(wb3_cyc_i),
    .wb3_stb_i(wb3_stb_i),
    .wb3_we_i (wb3_we_i),
    .wb3_adr_i(wb3_adr_i),
    .wb3_sel_i(wb3_sel_i),
    .wb3_dat_i(wb3_dat_i),
    .wb3_dat_o(wb3_dat_o),
    .wb3_ack_o(wb3_ack_o),

    .wb4_cyc_i(wb4_cyc_i),
    .wb4_stb_i(wb4_stb_i),
    .wb4_we_i (wb4_we_i),
    .wb4_adr_i(wb4_adr_i),
    .wb4_sel_i(wb4_sel_i),
    .wb4_dat_i(wb4_dat_i),
    .wb4_dat_o(wb4_dat_o),
    .wb4_ack_o(wb4_ack_o),
    .wb4_stall_o(wb4_stall_o),
    .wb4_err_o(wb4_err_o),

    .Exception(Exception),
    .Invalid(Invalid),
    .Overflow(Overflow),
    .Underflow(Underflow)
  );

  // Clock generation
  always #`HALF_CYCLE clock = ~clock;

  // Function 1 addresses
  localparam [31:0] F1_XY_ADDR = 32'h3050_1000; // Input/output (Write X, Read Y)
  localparam [31:0] F1_V_BASE  = 32'h3050_1100; // V Values
  localparam [31:0] F1_M_BASE  = 32'h3050_1200; // M Values
  localparam [31:0] F1_B_BASE  = 32'h3050_1300; // B Values

  // Init vectors (from userspace.c)
  reg [31:0] V_INIT [0:31];
  reg [31:0] M_INIT [0:31];
  reg [31:0] B_INIT [0:31];

  // Readback snapshots
  reg [31:0] V_PRE  [0:31];
  reg [31:0] M_PRE  [0:31];
  reg [31:0] B_PRE  [0:31];
  reg [31:0] V_POST [0:31];
  reg [31:0] M_POST [0:31];
  reg [31:0] B_POST [0:31];

  integer i;
  reg [31:0] tmp;

  //------------------------------------------------------------------------------
  // WB3 master tasks (single-beat)
  //------------------------------------------------------------------------------
  task wb3_write32;
    input [31:0] addr;
    input [31:0] data;
    begin
      @(posedge clock);
      wb3_adr_i <= addr;
      wb3_dat_i <= data;
      wb3_sel_i <= 4'hF;
      wb3_we_i  <= 1'b1;
      wb3_cyc_i <= 1'b1;
      wb3_stb_i <= 1'b1;

      while (!wb3_ack_o) @(posedge clock);

      @(posedge clock);
      wb3_cyc_i <= 1'b0;
      wb3_stb_i <= 1'b0;
      wb3_we_i  <= 1'b0;
      wb3_sel_i <= 4'h0;
      wb3_adr_i <= 32'h0;
      wb3_dat_i <= 32'h0;
    end
  endtask

  task wb3_read32;
    input [31:0] addr;
    output [31:0] data;
    begin
      @(posedge clock);
      wb3_adr_i <= addr;
      wb3_sel_i <= 4'hF;
      wb3_we_i  <= 1'b0;
      wb3_cyc_i <= 1'b1;
      wb3_stb_i <= 1'b1;

      while (!wb3_ack_o) @(posedge clock);

      @(posedge clock); // Wait an extra clk cycle to sample actual data
      data = wb3_dat_o;

      @(posedge clock);
      wb3_cyc_i <= 1'b0;
      wb3_stb_i <= 1'b0;
      wb3_sel_i <= 4'h0;
      wb3_adr_i <= 32'h0;
    end
  endtask

  //------------------------------------------------------------------------------
  // WB4 master tasks (single-beat; honors stall)
  //------------------------------------------------------------------------------
  task wb4_write32;
    input [31:0] addr;
    input [31:0] data;
    begin
      @(posedge clock);
      wb4_adr_i <= addr;
      wb4_dat_i <= data;
      wb4_sel_i <= 4'hF;
      wb4_we_i  <= 1'b1;
      wb4_cyc_i <= 1'b1;
      wb4_stb_i <= 1'b1;

      while (wb4_stall_o) @(posedge clock);
      while (!wb4_ack_o) @(posedge clock);

      @(posedge clock);
      wb4_cyc_i <= 1'b0;
      wb4_stb_i <= 1'b0;
      wb4_we_i  <= 1'b0;
      wb4_sel_i <= 4'h0;
      wb4_adr_i <= 32'h0;
      wb4_dat_i <= 32'h0;
    end
  endtask

  task wb4_read32;
    input [31:0] addr;
    output [31:0] data;
    begin
      @(posedge clock);
      wb4_adr_i <= addr;
      wb4_sel_i <= 4'hF;
      wb4_we_i  <= 1'b0;
      wb4_cyc_i <= 1'b1;
      wb4_stb_i <= 1'b1;

      while (wb4_stall_o) @(posedge clock);
      while (!wb4_ack_o) @(posedge clock);

      @(posedge clock); // Wait an extra clk cycle to sample actual data
      data = wb4_dat_o;

      @(posedge clock);
      wb4_cyc_i <= 1'b0;
      wb4_stb_i <= 1'b0;
      wb4_sel_i <= 4'h0;
      wb4_adr_i <= 32'h0;
    end
  endtask

  //------------------------------------------------------------------------------
  // Load Function-1 tables
  //------------------------------------------------------------------------------
  task load_tables_wb3;
    begin
      for (i = 0; i < 32; i = i + 1) begin
        wb3_write32(F1_V_BASE + (i*4), V_INIT[i]);
        wb3_write32(F1_M_BASE + (i*4), M_INIT[i]);
        wb3_write32(F1_B_BASE + (i*4), B_INIT[i]);
      end
    end
  endtask

  task load_tables_wb4;
    begin
      for (i = 0; i < 32; i = i + 1) begin
        wb4_write32(F1_V_BASE + (i*4), V_INIT[i]);
        wb4_write32(F1_M_BASE + (i*4), M_INIT[i]);
        wb4_write32(F1_B_BASE + (i*4), B_INIT[i]);
      end
    end
  endtask

  //------------------------------------------------------------------------------
  // Snapshot tables via WB3 reads
  //------------------------------------------------------------------------------
  task snapshot_pre;
    begin
      for (i = 0; i < 32; i = i + 1) begin
        wb3_read32(F1_V_BASE + (i*4), tmp); V_PRE[i] = tmp;
        wb3_read32(F1_M_BASE + (i*4), tmp); M_PRE[i] = tmp;
        wb3_read32(F1_B_BASE + (i*4), tmp); B_PRE[i] = tmp;
      end
    end
  endtask

  task snapshot_post;
    begin
      for (i = 0; i < 32; i = i + 1) begin
        wb3_read32(F1_V_BASE + (i*4), tmp); V_POST[i] = tmp;
        wb3_read32(F1_M_BASE + (i*4), tmp); M_POST[i] = tmp;
        wb3_read32(F1_B_BASE + (i*4), tmp); B_POST[i] = tmp;
      end
    end
  endtask

  //------------------------------------------------------------------------------
  // Compute Function 1 via WB3: write X then read Y
  //------------------------------------------------------------------------------
  task compute_f1_wb3;
    input  [31:0] x;
    output [31:0] y;
    begin
      wb3_write32(F1_XY_ADDR, x);
      @(posedge clock);
      wb3_read32(F1_XY_ADDR, y);
    end
  endtask

  //------------------------------------------------------------------------------
  // Export PRE & POST values to text file for external comparison
  //
  // Outputted file format is
  //
  //  tag=<...>,time_ns=<...>
  //  bank,index,hex
  //  V,0,XXXXXXXX
  //  ...
  //  M,0,XXXXXXXX
  //  ...
  //  B,0,XXXXXXXX
  //  ...
  //------------------------------------------------------------------------------
  task dump_tables_to_file;
    input [8*128-1:0] fname;
    input [8*32-1:0]  tag;
    input [31:0] V_TAB [0:31];
    input [31:0] M_TAB [0:31];
    input [31:0] B_TAB [0:31];
    integer fh;
  begin
    fh = $fopen(fname, "w"); // Write to file (overwrite any prev values)
    if (fh == 0) begin
      $display("%0t [FILE] ERROR: could not open %s", $time, fname);
    end else begin // If we have something to write, begin
      $fwrite(fh, "tag=%s,time_ns=%0t\n", tag, $time);
      $fwrite(fh, "bank,index,hex\n");
      for (i = 0; i < 32; i = i + 1) begin
        $fwrite(fh, "V,%0d,%08h\n", i, V_TAB[i]);
      end
      for (i = 0; i < 32; i = i + 1) begin
        $fwrite(fh, "M,%0d,%08h\n", i, M_TAB[i]);
      end
      for (i = 0; i < 32; i = i + 1) begin
        $fwrite(fh, "B,%0d,%08h\n", i, B_TAB[i]);
      end
      $fclose(fh);
      $display("%0t [FILE] Wrote %s", $time, fname);
    end
  end
  endtask

  //------------------------------------------------------------------------------
  // Testcases
  //------------------------------------------------------------------------------
  task testcase_cpu_only_wb3;
    reg [31:0] y;
    begin
      load_tables_wb3();
      snapshot_pre();
      dump_tables_to_file("cpu-pre-calc.csv","cpu-pre", V_PRE, M_PRE, B_PRE);
      compute_f1_wb3(32'h40A00000, y); // x = 5.0 (example)
      snapshot_post();
      dump_tables_to_file("cpu-post-calc.csv","cpu-post", V_POST, M_POST, B_POST);
      
    end
  endtask

  task testcase_cpu_only_wb4;
    reg [31:0] y;
    begin
      load_tables_wb4();
      snapshot_pre();
      dump_tables_to_file("dma-pre-calc.csv","dma-pre", V_PRE, M_PRE, B_PRE);
      compute_f1_wb3(32'h40A00000, y); // x = 5.0 (example)
      snapshot_post();
      dump_tables_to_file("dma-post-calc.csv","dma-post", V_POST, M_POST, B_POST);
      
    end
  endtask

  //------------------------------------------------------------------------------
  // Initial block
  //------------------------------------------------------------------------------
  initial begin
    // defaults
    clock = 1'b0;
    reset = 1'b1;

    wb3_cyc_i = 0; wb3_stb_i = 0; wb3_we_i = 0;
    wb3_adr_i = 0; wb3_sel_i = 0; wb3_dat_i = 0;

    wb4_cyc_i = 0; wb4_stb_i = 0; wb4_we_i = 0;
    wb4_adr_i = 0; wb4_sel_i = 0; wb4_dat_i = 0;

    // Init vectors from userspace loadMemory()
    V_INIT[0] = 32'hc1400000;
    V_INIT[1] = 32'hc1339ce7;
    V_INIT[2] = 32'hc12739ce;
    V_INIT[3] = 32'hc11ad6b6;
    V_INIT[4] = 32'hc10e739d;
    V_INIT[5] = 32'hc1021084;
    V_INIT[6] = 32'hc0eb5ad7;
    V_INIT[7] = 32'hc0d294a5;
    V_INIT[8] = 32'hc0b9ce74;
    V_INIT[9] = 32'hc0a10842;
    V_INIT[10] = 32'hc0884211;
    V_INIT[11] = 32'hc05ef7be;
    V_INIT[12] = 32'hc02d6b5b;
    V_INIT[13] = 32'hbff7bdef;
    V_INIT[14] = 32'hbf94a529;
    V_INIT[15] = 32'hbec6318c;
    V_INIT[16] = 32'h3ec6318c;
    V_INIT[17] = 32'h3f94a529;
    V_INIT[18] = 32'h3ff7bdef;
    V_INIT[19] = 32'h402d6b5b;
    V_INIT[20] = 32'h405ef7be;
    V_INIT[21] = 32'h40884211;
    V_INIT[22] = 32'h40a10842;
    V_INIT[23] = 32'h40b9ce74;
    V_INIT[24] = 32'h40d294a5;
    V_INIT[25] = 32'h40eb5ad7;
    V_INIT[26] = 32'h41021084;
    V_INIT[27] = 32'h410e739d;
    V_INIT[28] = 32'h411ad6b6;
    V_INIT[29] = 32'h412739ce;
    V_INIT[30] = 32'h41339ce7;
    V_INIT[31] = 32'h41400000;

    M_INIT[0] = 32'h2d0300f8;
    M_INIT[1] = 32'h2d4060f1;
    M_INIT[2] = 32'h2d8d106e;
    M_INIT[3] = 32'h2dce77a8;
    M_INIT[4] = 32'h2e16a99c;
    M_INIT[5] = 32'h2e5b0964;
    M_INIT[6] = 32'h2ea7b8e1;
    M_INIT[7] = 32'h2ee90772;
    M_INIT[8] = 32'h2f356eba;
    M_INIT[9] = 32'h2f767e12;
    M_INIT[10] = 32'h2fbf6fef;
    M_INIT[11] = 32'h3007115d;
    M_INIT[12] = 32'h3049293d;
    M_INIT[13] = 32'h3092644f;
    M_INIT[14] = 32'h30d238a3;
    M_INIT[15] = 32'h311a2d06;
    M_INIT[16] = 32'h311a2d06;
    M_INIT[17] = 32'h30d238a3;
    M_INIT[18] = 32'h3092644f;
    M_INIT[19] = 32'h3049293d;
    M_INIT[20] = 32'h3007115d;
    M_INIT[21] = 32'h2fbf6fef;
    M_INIT[22] = 32'h2f767e12;
    M_INIT[23] = 32'h2f356eba;
    M_INIT[24] = 32'h2ee90772;
    M_INIT[25] = 32'h2ea7b8e1;
    M_INIT[26] = 32'h2e5b0964;
    M_INIT[27] = 32'h2e16a99c;
    M_INIT[28] = 32'h2dce77a8;
    M_INIT[29] = 32'h2d8d106e;
    M_INIT[30] = 32'h2d4060f1;
    M_INIT[31] = 32'h2d0300f8;

    B_INIT[0] = 32'h3f7fffff;
    B_INIT[1] = 32'h3f7fffff;
    B_INIT[2] = 32'h3f7fffff;
    B_INIT[3] = 32'h3f7fffff;
    B_INIT[4] = 32'h3f7fffff;
    B_INIT[5] = 32'h3f7fffff;
    B_INIT[6] = 32'h3f7fffff;
    B_INIT[7] = 32'h3f7fffff;
    B_INIT[8] = 32'h3f7fffff;
    B_INIT[9] = 32'h3f7fffff;
    B_INIT[10] = 32'h3f7fffff;
    B_INIT[11] = 32'h3f7fffff;
    B_INIT[12] = 32'h3f7fffff;
    B_INIT[13] = 32'h3f7fffff;
    B_INIT[14] = 32'h3f7fffff;
    B_INIT[15] = 32'h3f7fffff;
    B_INIT[16] = 32'h3f800000;
    B_INIT[17] = 32'h3f800000;
    B_INIT[18] = 32'h3f800000;
    B_INIT[19] = 32'h3f800000;
    B_INIT[20] = 32'h3f800000;
    B_INIT[21] = 32'h3f800000;
    B_INIT[22] = 32'h3f800000;
    B_INIT[23] = 32'h3f800000;
    B_INIT[24] = 32'h3f800000;
    B_INIT[25] = 32'h3f800000;
    B_INIT[26] = 32'h3f800000;
    B_INIT[27] = 32'h3f800000;
    B_INIT[28] = 32'h3f800000;
    B_INIT[29] = 32'h3f800000;
    B_INIT[30] = 32'h3f800000;
    B_INIT[31] = 32'h3f800000;

    // reset release
    #(`HALF_CYCLE*10);
    @(posedge clock);
    reset = 1'b0;

    // settle
    #(`HALF_CYCLE*10);

    testcase_cpu_only_wb3();
    testcase_cpu_only_wb4();

    #(`HALF_CYCLE*10);
    $finish;
  end

endmodule
