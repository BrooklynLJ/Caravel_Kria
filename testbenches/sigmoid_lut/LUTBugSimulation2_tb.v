`timescale 1ns / 1ps
`define HALF_CYCLE 5

//------------------------------------------------------------------------------
// LUTBugSimulation2_tb.v  (baseline-style TB) (note: file type is set to SystemVerilog in Vivado to avoid errors)
//------------------------------------------------------------------------------
// Targets: LUT_Module
// Goal:
//   - Isolate LUT coefficient corruption by running two scenarios:
//       (1) CPU-only: WB3 loads tables + WB3 compute. E.g, Directly send signals to the LUT to test if the LUT calculations rewrite their own values.
//       (2) CPU-only: WB4 loads tables + WB4 compute. E.g, 
//       (3) DMA->LUT: Use the DMA to send signals to the LUT to test if the write/read of the DMA changes the LUT values.
//
// Notes:
//   - WB4 "DMA" traffic is emulated by driving wb4_* master signals in the TB.
//   - Coefficient init vectors are taken from loadMemory() in our_userspace.c.
//   - This tb is an improvement of the previous LUTBugSimulation_tb. Unlike the prev tb,
//     this tb utilizes the DMA to send calculation requests to the LUT to check for errors
//------------------------------------------------------------------------------

module LUTBugSimulation2_tb();

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

  //------------------------------------------------------------------------------
  // ZipDMA integration (DMA master)
  //
  // The additions below instantiate the zipdma.v core, plus a small
  // Wishbone RAM model used as the DMA source. A address decoder
  // routes the ZipDMA master port either to:
  //   - the LUT WB4 slave (0x3050_xxxx), or
  //   - the RAM model (0x0000_xxxx)
  //
  // This enables a third testcase that uses the real DMA engine to initialize
  // the LUT coefficient tables and then runs a compute via WB3.
  //------------------------------------------------------------------------------

  // Select whether LUT's WB4 port is driven by TB-emulated WB4 signals
  // (use_zipdma_wb4=0) or the ZipDMA master via the fabric (use_zipdma_wb4=1)
  reg use_zipdma_wb4;

  // ZipDMA control (slave) port (Wishbone B3)
  reg         dma_swb_cyc_i, dma_swb_stb_i, dma_swb_we_i;
  reg  [1:0]  dma_swb_addr_i;
  reg  [31:0] dma_swb_dat_i;
  reg  [3:0]  dma_swb_sel_i;
  wire        dma_swb_ack_o;
  wire [31:0] dma_swb_dat_o;

  // ZipDMA master (Wishbone) port
  wire        dma_mwb_cyc, dma_mwb_stb, dma_mwb_we;
  wire [29:0] dma_mwb_addr;      // word-addressed (byte_addr >> 2)
  wire [31:0] dma_mwb_wdata;
  wire [3:0]  dma_mwb_sel;
  wire        dma_mwb_stall;
  wire        dma_mwb_ack;
  wire [31:0] dma_mwb_rdata;
  wire        dma_mwb_err;

  // Fabric -> LUT WB4 signals (when ZipDMA targets LUT)
  wire        fab_lut_cyc, fab_lut_stb, fab_lut_we;
  wire [31:0] fab_lut_adr;
  wire [3:0]  fab_lut_sel;
  wire [31:0] fab_lut_dat;

  // Simple DMA source RAM model (byte address base = 0)
  reg  [31:0] dma_src_mem [0:255];
  wire        ram_ack;
  wire [31:0]  ram_rdata;

  //------------------------------------------------------------------------------
  // memory_intf integration (SRAM/BRAM-style system memory)
  //
  // The TB previously used a simple reg-array RAM model as the ZipDMA source/destination.
  // The blocks below instantiate the project's memory_intf + arbiter + WB3/WB4 interfaces
  // so ZipDMA reads/writes go through the same memory interface used in the full design.
  //------------------------------------------------------------------------------

  // Wishbone B3 port into memory_intf (TB-driven, used to prefill DMA source buffers)
  reg         mem_wb3_cyc_i, mem_wb3_stb_i, mem_wb3_we_i;
  reg [31:0]  mem_wb3_adr_i;
  reg [3:0]   mem_wb3_sel_i;
  reg [31:0]  mem_wb3_dat_i;
  wire [31:0] mem_wb3_dat_o;
  wire        mem_wb3_ack_o;

  // Wishbone B4 port into memory_intf (ZipDMA master when dma_to_ram==1)
  wire        mem_wb4_cyc_i;
  wire        mem_wb4_stb_i;
  wire        mem_wb4_we_i;
  wire [31:0] mem_wb4_adr_i;
  wire [3:0]  mem_wb4_sel_i;
  wire [31:0] mem_wb4_dat_i;
  wire [31:0] mem_wb4_dat_o;
  wire        mem_wb4_ack_o;
  wire        mem_wb4_stall_o;
  wire        mem_wb4_err_o;

  // Muxed WB4 inputs into the DUT
  wire        lut_wb4_cyc_i = (use_zipdma_wb4) ? fab_lut_cyc : wb4_cyc_i;
  wire        lut_wb4_stb_i = (use_zipdma_wb4) ? fab_lut_stb : wb4_stb_i;
  wire        lut_wb4_we_i  = (use_zipdma_wb4) ? fab_lut_we  : wb4_we_i;
  wire [31:0] lut_wb4_adr_i = (use_zipdma_wb4) ? fab_lut_adr : wb4_adr_i;
  wire [3:0]  lut_wb4_sel_i = (use_zipdma_wb4) ? fab_lut_sel : wb4_sel_i;
  wire [31:0] lut_wb4_dat_i = (use_zipdma_wb4) ? fab_lut_dat : wb4_dat_i;

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

    .wb4_cyc_i(lut_wb4_cyc_i),
    .wb4_stb_i(lut_wb4_stb_i),
    .wb4_we_i (lut_wb4_we_i),
    .wb4_adr_i(lut_wb4_adr_i),
    .wb4_sel_i(lut_wb4_sel_i),
    .wb4_dat_i(lut_wb4_dat_i),
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

  //------------------------------------------------------------------------------
  // ZipDMA + Fabric
  //------------------------------------------------------------------------------

  // ZipDMA instance
  // NOTE: The ZipDMA master port is word-addressed. The fabric reconstructs
  //       byte addresses as {dma_mwb_addr,2'b00}.
  wire dma_interrupt;
  zipdma #(
    .ADDRESS_WIDTH(32),
    .LGMEMLEN(10),
    .LGDMALENGTH(32),
    .SLV_WIDTH(32),
    .BUS_WIDTH(32)
  ) u_zipdma (
    .i_clk(clock),
    .i_reset(reset),

    // Slave/control (WB3)
    .i_swb_cyc(dma_swb_cyc_i),
    .i_swb_stb(dma_swb_stb_i),
    .i_swb_we (dma_swb_we_i),
    .i_swb_addr(dma_swb_addr_i),
    .i_swb_data(dma_swb_dat_i),
    .i_swb_sel(dma_swb_sel_i),
    .o_swb_ack(dma_swb_ack_o),
    .o_swb_data(dma_swb_dat_o),

    // Master/DMA (WB)
    .o_mwb_cyc(dma_mwb_cyc),
    .o_mwb_stb(dma_mwb_stb),
    .o_mwb_we (dma_mwb_we),
    .o_mwb_addr(dma_mwb_addr),
    .o_mwb_data(dma_mwb_wdata),
    .o_mwb_sel(dma_mwb_sel),
    .i_mwb_stall(dma_mwb_stall),
    .i_mwb_ack(dma_mwb_ack),
    .i_mwb_data(dma_mwb_rdata),
    .i_mwb_err(dma_mwb_err),

    .i_dev_ints(32'h0),
    .o_interrupt(dma_interrupt)
  );

  // Fabric decode
  wire [31:0] dma_mwb_byte_addr = {dma_mwb_addr, 2'b00};
  wire        dma_to_lut = dma_mwb_cyc && (dma_mwb_byte_addr[31:16] == 16'h3050);
  wire        dma_to_ram = dma_mwb_cyc && !dma_to_lut;

  // memory_intf WB4 wiring for the ZipDMA master (system memory space)
  assign mem_wb4_cyc_i = use_zipdma_wb4 && dma_to_ram && dma_mwb_cyc;
  assign mem_wb4_stb_i = use_zipdma_wb4 && dma_to_ram && dma_mwb_stb;
  assign mem_wb4_we_i  = use_zipdma_wb4 && dma_to_ram && dma_mwb_we;
  assign mem_wb4_adr_i = dma_mwb_byte_addr;
  assign mem_wb4_sel_i = dma_mwb_sel;
  assign mem_wb4_dat_i = dma_mwb_wdata;

  // memory_intf instance (SRAM/BRAM-backed memory with WB3/WB4 arbitration)
  memory_intf u_mem_intf(
    .clock(clock),
    .reset(reset),

    .wb3_cyc_i(mem_wb3_cyc_i),
    .wb3_stb_i(mem_wb3_stb_i),
    .wb3_we_i (mem_wb3_we_i),
    .wb3_adr_i(mem_wb3_adr_i),
    .wb3_sel_i(mem_wb3_sel_i),
    .wb3_dat_i(mem_wb3_dat_i),
    .wb3_dat_o(mem_wb3_dat_o),
    .wb3_ack_o(mem_wb3_ack_o),

    .wb4_cyc_i(mem_wb4_cyc_i),
    .wb4_stb_i(mem_wb4_stb_i),
    .wb4_we_i (mem_wb4_we_i),
    .wb4_adr_i(mem_wb4_adr_i),
    .wb4_sel_i(mem_wb4_sel_i),
    .wb4_dat_i(mem_wb4_dat_i),
    .wb4_dat_o(mem_wb4_dat_o),
    .wb4_ack_o(mem_wb4_ack_o),
    .wb4_stall_o(mem_wb4_stall_o),
    .wb4_err_o(mem_wb4_err_o)
  );

  // Drive LUT WB4 inputs when ZipDMA is selected and DMA is targeting LUT space
  assign fab_lut_cyc = use_zipdma_wb4 && dma_to_lut && dma_mwb_cyc;
  assign fab_lut_stb = use_zipdma_wb4 && dma_to_lut && dma_mwb_stb;
  assign fab_lut_we  = use_zipdma_wb4 && dma_to_lut && dma_mwb_we;
  assign fab_lut_adr = dma_mwb_byte_addr;
  assign fab_lut_sel = dma_mwb_sel;
  assign fab_lut_dat = dma_mwb_wdata;

  // RAM model (used as DMA source)
  // - Address space: 0x0000_0000 ..
  // - One-cycle response, no stall, 32-bit words
  // - Byte enables honored on writes
  // NOTE: Implemented as zero-wait-state (ACK in same cycle) to avoid any pipelining/late-ACK mismatch with ZipDMA.
  wire [7:0] ram_word_index = dma_mwb_addr[7:0];
  wire       ram_req = use_zipdma_wb4 && dma_to_ram && dma_mwb_stb && dma_mwb_cyc;

  assign ram_ack   = ram_req;
  assign ram_rdata = dma_src_mem[ram_word_index];

  always @(posedge clock) begin
    if (!reset) begin
      if (ram_req && dma_mwb_we) begin
        if (dma_mwb_sel[0]) dma_src_mem[ram_word_index][ 7: 0] <= dma_mwb_wdata[ 7: 0];
        if (dma_mwb_sel[1]) dma_src_mem[ram_word_index][15: 8] <= dma_mwb_wdata[15: 8];
        if (dma_mwb_sel[2]) dma_src_mem[ram_word_index][23:16] <= dma_mwb_wdata[23:16];
        if (dma_mwb_sel[3]) dma_src_mem[ram_word_index][31:24] <= dma_mwb_wdata[31:24];
      end
    end
  end


  // Return path back into ZipDMA
  assign dma_mwb_stall = (use_zipdma_wb4 && dma_to_lut) ? wb4_stall_o : mem_wb4_stall_o;
  assign dma_mwb_ack   = (use_zipdma_wb4 && dma_to_lut) ? wb4_ack_o   : mem_wb4_ack_o;
  assign dma_mwb_rdata = (use_zipdma_wb4 && dma_to_lut) ? wb4_dat_o   : mem_wb4_dat_o;
  assign dma_mwb_err   = (use_zipdma_wb4 && dma_to_lut) ? wb4_err_o   : mem_wb4_err_o;

  // Function 1 addresses
  localparam [31:0] F1_XY_ADDR = 32'h3050_1000; // Input/output (Write X, Read Y)
  localparam [31:0] F1_V_BASE  = 32'h3050_1100; // V Values
  localparam [31:0] F1_M_BASE  = 32'h3050_1200; // M Values
  localparam [31:0] F1_B_BASE  = 32'h3050_1300; // B Values

  localparam integer LOOP_ITERS = 100; // Number of compute iterations in looped testcases

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
  // memory_intf WB3 master tasks (single-beat)
  //------------------------------------------------------------------------------
  task mem_wb3_write32;
    input [31:0] addr;
    input [31:0] data;
    begin
      @(posedge clock);
      mem_wb3_adr_i <= addr;
      mem_wb3_dat_i <= data;
      mem_wb3_sel_i <= 4'hF;
      mem_wb3_we_i  <= 1'b1;
      mem_wb3_cyc_i <= 1'b1;
      mem_wb3_stb_i <= 1'b1;

      while (!mem_wb3_ack_o) @(posedge clock);

      @(posedge clock);
      mem_wb3_cyc_i <= 1'b0;
      mem_wb3_stb_i <= 1'b0;
      mem_wb3_we_i  <= 1'b0;
      mem_wb3_sel_i <= 4'h0;
      mem_wb3_adr_i <= 32'h0;
      mem_wb3_dat_i <= 32'h0;
    end
  endtask

  task mem_wb3_read32;
    input [31:0] addr;
    output [31:0] data;
    begin
      @(posedge clock);
      mem_wb3_adr_i <= addr;
      mem_wb3_sel_i <= 4'hF;
      mem_wb3_we_i  <= 1'b0;
      mem_wb3_cyc_i <= 1'b1;
      mem_wb3_stb_i <= 1'b1;

      while (!mem_wb3_ack_o) @(posedge clock);

      @(posedge clock);
      data = mem_wb3_dat_o;

      mem_wb3_cyc_i <= 1'b0;
      mem_wb3_stb_i <= 1'b0;
      mem_wb3_sel_i <= 4'h0;
      mem_wb3_adr_i <= 32'h0;
    end
  endtask

  task init_sram_dma_buffers;
    integer k;
    begin
      // Fill system memory at 0x0000_0000/0x0000_0100/0x0000_0200 with V/M/B init vectors
      for (k = 0; k < 32; k = k + 1) begin
        mem_wb3_write32(32'h0000_0000 + (k<<2), V_INIT[k]);
        mem_wb3_write32(32'h0000_0100 + (k<<2), M_INIT[k]);
        mem_wb3_write32(32'h0000_0200 + (k<<2), B_INIT[k]);
      end
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
  // ZipDMA control tasks (B3 slave port) and DMA table load
  //------------------------------------------------------------------------------
  task dma_ctrl_write;
    input [1:0]  regsel;
    input [31:0] data;
    begin
      @(posedge clock);
      dma_swb_addr_i <= regsel;
      dma_swb_dat_i  <= data;
      dma_swb_sel_i  <= 4'hF;
      dma_swb_we_i   <= 1'b1;
      dma_swb_cyc_i  <= 1'b1;
      dma_swb_stb_i  <= 1'b1;

      while (!dma_swb_ack_o) @(posedge clock);

      @(posedge clock);
      dma_swb_cyc_i  <= 1'b0;
      dma_swb_stb_i  <= 1'b0;
      dma_swb_we_i   <= 1'b0;
      dma_swb_sel_i  <= 4'h0;
      dma_swb_addr_i <= 2'b00;
      dma_swb_dat_i  <= 32'h0;
    end
  endtask

  task dma_ctrl_read;
    input  [1:0]  regsel;
    output [31:0] data;
    begin
      @(posedge clock);
      dma_swb_addr_i <= regsel;
      dma_swb_sel_i  <= 4'hF;
      dma_swb_we_i   <= 1'b0;
      dma_swb_cyc_i  <= 1'b1;
      dma_swb_stb_i  <= 1'b1;

      while (!dma_swb_ack_o) @(posedge clock);

      @(posedge clock); // Wait an extra clk cycle to sample actual data
      data = dma_swb_dat_o;

      @(posedge clock);
      dma_swb_cyc_i  <= 1'b0;
      dma_swb_stb_i  <= 1'b0;
      dma_swb_sel_i  <= 4'h0;
      dma_swb_addr_i <= 2'b00;
    end
  endtask

  task dma_wait_done;
    integer timeout;
    reg [31:0] ctrl;
    begin
      // Wait for BUSY to go high (start accepted), then low (transfer complete)
      ctrl = 32'h0;
      timeout = 0;
      while (!ctrl[31] && timeout < 2000) begin
        dma_ctrl_read(2'b00, ctrl);
        timeout = timeout + 1;
      end
      if (timeout >= 2000) begin
        $display("%0t [ZipDMA] WARNING: BUSY never asserted (ctrl=%08h)", $time, ctrl);
      end

      timeout = 0;
      while (ctrl[31] && timeout < 200000) begin
        dma_ctrl_read(2'b00, ctrl);
        timeout = timeout + 1;
      end
      if (timeout >= 200000) begin
        $display("%0t [ZipDMA] ERROR: timeout waiting for BUSY deassert (ctrl=%08h)", $time, ctrl);
      end
    end
  endtask

  task zipdma_copy;
    input [31:0] src_byte_addr;
    input [31:0] dst_byte_addr;
    input [31:0] nbytes;
    begin
      // Configure inc/size but do not start yet (bit31=1 prevents start)
      // - i_data[22]=0 => s2mm_inc=1 (increment dst)
      // - i_data[18]=0 => mm2s_inc=1 (increment src)
      // - size fields left at 2'b00 (BUS width)
      dma_ctrl_write(2'b00, 32'h8000_0000);
      dma_ctrl_write(2'b01, src_byte_addr);
      dma_ctrl_write(2'b10, dst_byte_addr);
      dma_ctrl_write(2'b11, nbytes);

      // Start DMA (bit31=0) + clear any prior interrupt/error flags
      dma_ctrl_write(2'b00, 32'h4000_0000);
      dma_wait_done();
    end
  endtask

  task load_tables_zipdma;
    begin
      // Route ZipDMA master traffic into the LUT WB4 port
      use_zipdma_wb4 = 1'b1;

      // 3 DMAs (one per table), since the V/M/B base ranges are not contiguous
      zipdma_copy(32'h0000_0000, F1_V_BASE, 32'd128); // 32 words * 4 bytes
      zipdma_copy(32'h0000_0100, F1_M_BASE, 32'd128);
      zipdma_copy(32'h0000_0200, F1_B_BASE, 32'd128);

      // Return WB4 control to TB emulation
      use_zipdma_wb4 = 1'b0;
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

  // WB4 compute path (Write X, then read Y back via WB4)
  task compute_f1_wb4;
    input  [31:0] x;
    output [31:0] y;
    begin
      wb4_write32(F1_XY_ADDR, x);
      @(posedge clock);
      wb4_read32(F1_XY_ADDR, y);
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

  // Loop-dump helpers:
  //   - Creates a CSV with a single header line
  //   - Appends one full V/M/B snapshot per iteration, using index=(iter*32 + i)
  task init_loop_csv;
    input [8*128-1:0] fname;
    integer fh;
  begin
    fh = $fopen(fname, "w");
    if (fh == 0) begin
      $display("%0t [FILE] ERROR: could not open %s", $time, fname);
    end else begin
      $fwrite(fh, "bank,index,hex\n");
      $fclose(fh);
      $display("%0t [FILE] Wrote %s", $time, fname);
    end
  end
  endtask

  task append_tables_loop_csv;
    input [8*128-1:0] fname;
    input integer     iter;
    input [31:0] V_TAB [0:31];
    input [31:0] M_TAB [0:31];
    input [31:0] B_TAB [0:31];
    integer fh;
    integer base;
  begin
    fh = $fopen(fname, "a"); // Append rows
    if (fh == 0) begin
      $display("%0t [FILE] ERROR: could not open %s", $time, fname);
    end else begin
      base = iter * 32;
      for (i = 0; i < 32; i = i + 1) begin
        $fwrite(fh, "V,%0d,%08h\n", base + i, V_TAB[i]);
      end
      for (i = 0; i < 32; i = i + 1) begin
        $fwrite(fh, "M,%0d,%08h\n", base + i, M_TAB[i]);
      end
      for (i = 0; i < 32; i = i + 1) begin
        $fwrite(fh, "B,%0d,%08h\n", base + i, B_TAB[i]);
      end
      $fclose(fh);
    end
  end
  endtask


  //------------------------------------------------------------------------------
  // Testcases
  //------------------------------------------------------------------------------
  task testcase_wb3_only;
    reg [31:0] y;
    begin
      load_tables_wb3();
      snapshot_pre();
      dump_tables_to_file("testcase_wb3_only_pre.csv","testcase_wb3_only_pre", V_PRE, M_PRE, B_PRE);
      compute_f1_wb3(32'h40A00000, y); // x = 5.0 (example)
      snapshot_post();
      dump_tables_to_file("testcase_wb3_only_post.csv","testcase_wb3_only_post", V_POST, M_POST, B_POST);
      
    end
  endtask

  task testcase_wb4_only;
    reg [31:0] y;
    begin
      load_tables_wb4();
      snapshot_pre();
      dump_tables_to_file("testcase_wb4_only_pre.csv","testcase_wb4_only_pre", V_PRE, M_PRE, B_PRE);
      compute_f1_wb4(32'h40A00000, y); // x = 5.0 (example)
      snapshot_post();
      dump_tables_to_file("testcase_wb4_only_post.csv","testcase_wb4_only_post", V_POST, M_POST, B_POST);
      
    end
  endtask

  task testcase_zipdma;
    reg [31:0] y;
    begin
      load_tables_zipdma();
      snapshot_pre();
      dump_tables_to_file("testcase_zipdma_pre.csv","testcase_zipdma_pre", V_PRE, M_PRE, B_PRE);
      compute_f1_wb3(32'h40A00000, y); // x = 5.0 (example)
      snapshot_post();
      dump_tables_to_file("testcase_zipdma_post.csv","testcase_zipdma_post", V_POST, M_POST, B_POST);
      
    end
  endtask

  task testcase_wb3_only_loop;
    reg [31:0] y;
    integer iter;
    begin
      load_tables_wb3();
      init_loop_csv("testcase_wb3_only_pre_loop.csv");
      init_loop_csv("testcase_wb3_only_post_loop.csv");

      for (iter = 0; iter < LOOP_ITERS; iter = iter + 1) begin
        snapshot_pre();
        append_tables_loop_csv("testcase_wb3_only_pre_loop.csv", iter, V_PRE, M_PRE, B_PRE);

        compute_f1_wb3(32'h40A00000, y); // x = 5.0 (example)

        snapshot_post();
        append_tables_loop_csv("testcase_wb3_only_post_loop.csv", iter, V_POST, M_POST, B_POST);
      end
    end
  endtask

  task testcase_wb4_only_loop;
    reg [31:0] y;
    integer iter;
    begin
      load_tables_wb4();
      init_loop_csv("testcase_wb4_only_pre_loop.csv");
      init_loop_csv("testcase_wb4_only_post_loop.csv");

      for (iter = 0; iter < LOOP_ITERS; iter = iter + 1) begin
        snapshot_pre();
        append_tables_loop_csv("testcase_wb4_only_pre_loop.csv", iter, V_PRE, M_PRE, B_PRE);

        compute_f1_wb4(32'h40A00000, y); // x = 5.0 (example)

        snapshot_post();
        append_tables_loop_csv("testcase_wb4_only_post_loop.csv", iter, V_POST, M_POST, B_POST);
      end
    end
  endtask

  task testcase_zipdma_loop;
    reg [31:0] y;
    integer iter;
    begin
      load_tables_zipdma();
      init_loop_csv("testcase_zipdma_pre_loop.csv");
      init_loop_csv("testcase_zipdma_post_loop.csv");

      for (iter = 0; iter < LOOP_ITERS; iter = iter + 1) begin
        snapshot_pre();
        append_tables_loop_csv("testcase_zipdma_pre_loop.csv", iter, V_PRE, M_PRE, B_PRE);

        compute_f1_wb3(32'h40A00000, y); // x = 5.0 (example)

        snapshot_post();
        append_tables_loop_csv("testcase_zipdma_post_loop.csv", iter, V_POST, M_POST, B_POST);
      end
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

    // memory_intf WB3 init
    mem_wb3_cyc_i = 0;
    mem_wb3_stb_i = 0;
    mem_wb3_we_i  = 0;
    mem_wb3_adr_i = 0;
    mem_wb3_sel_i = 0;
    mem_wb3_dat_i = 0;

    // ZipDMA control defaults
    use_zipdma_wb4 = 1'b0;
    dma_swb_cyc_i  = 1'b0;
    dma_swb_stb_i  = 1'b0;
    dma_swb_we_i   = 1'b0;
    dma_swb_addr_i = 2'b00;
    dma_swb_dat_i  = 32'h0;
    dma_swb_sel_i  = 4'h0;

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

    // Populate the ZipDMA source RAM with the init vectors
    // Layout:
    //   0x0000_0000 : V[0..31]   (128 bytes)
    //   0x0000_0100 : M[0..31]   (128 bytes)
    //   0x0000_0200 : B[0..31]   (128 bytes)
    for (i = 0; i < 256; i = i + 1) begin
      dma_src_mem[i] = 32'h0;
    end
    for (i = 0; i < 32; i = i + 1) begin
      dma_src_mem[i]       = V_INIT[i];
      dma_src_mem[64+i]    = M_INIT[i]; // 0x0100 / 4 = 64
      dma_src_mem[128+i]   = B_INIT[i]; // 0x0200 / 4 = 128
    end

    // reset release
    #(`HALF_CYCLE*10);
    @(posedge clock);
    reset = 1'b0;

    // settle
    #(`HALF_CYCLE*10);

    // Initialize the system memory (memory_intf) used by ZipDMA as the source buffers
    init_sram_dma_buffers();

    testcase_wb3_only();
    testcase_wb4_only();
    testcase_zipdma();

    testcase_wb3_only_loop();
    testcase_wb4_only_loop();
    testcase_zipdma_loop();

    #(`HALF_CYCLE*10);
    $finish;
  end

endmodule

//------------------------------------------------------------------------------
// Simple behavioral BRAM used by memory_intf for simulation
//------------------------------------------------------------------------------
module bram(
    input  wire        clka,
    input  wire [9:0]  addra,
    input  wire [31:0] dina,
    output reg  [31:0] douta,
    input  wire [3:0]  wea,
    input  wire        ena
);
    reg [31:0] mem [0:1023];
    integer ii;
    initial begin
        for (ii = 0; ii < 1024; ii = ii + 1) begin
            mem[ii] = 32'h0;
        end
    end

    always @(posedge clka) begin
        if (ena) begin
            // write-first per-byte behavior
            if (wea[0]) mem[addra][ 7: 0] <= dina[ 7: 0];
            if (wea[1]) mem[addra][15: 8] <= dina[15: 8];
            if (wea[2]) mem[addra][23:16] <= dina[23:16];
            if (wea[3]) mem[addra][31:24] <= dina[31:24];
            douta <= mem[addra];
        end
    end
endmodule