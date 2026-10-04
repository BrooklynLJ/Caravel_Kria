`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Bryce Chen
// 
// Create Date: 02/21/2026 03:49:56 PM
// Design Name: 
// Module Name: tb_SM_Packet_Generator
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


module tb_SM_Packet_Generator;

  reg        clk;
  reg        reset;       // ACTIVE-HIGH reset (matches DUT: if (reset) ...)
  reg  [3:0] neuron_id;
  reg        ap_level;
  wire [7:0] pkt_byte;
  wire       pkt_valid;
  reg        pkt_ready;
  wire       dropped;

  // "Nothing sent" indicator for debug/readability in waveform/log
  reg        nothing_sent;

  SM_Packet_Generator dut (
    .clk(clk),
    .reset(reset),
    .neuron_id(neuron_id),
    .ap_level(ap_level),
    .pkt_byte(pkt_byte),
    .pkt_valid(pkt_valid),
    .pkt_ready(pkt_ready),
    .dropped(dropped)
  );

  // 100 MHz clock (10ns period)
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  task step;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task expect;
    input cond;
    input [1023:0] msg;
    begin
      if (!cond) begin
        $display("[%0t] FAIL: %0s", $time, msg);
        $stop;
      end
    end
  endtask

  function [7:0] make_pkt;
    input ap;
    input [3:0] id;
    begin
      make_pkt = {3'b000, id, ap}; // matches DUT packing
    end
  endfunction

  // Convenience: step N cycles and assert "no packet should be produced"
  task expect_nothing_for;
    input integer cycles;
    input [1023:0] label;
    integer k;
    begin
      for (k = 0; k < cycles; k = k + 1) begin
        nothing_sent = 1'b1;
        step;
        expect(pkt_valid === 1'b0, label);
        expect(dropped   === 1'b0, label);
      end
      nothing_sent = 1'b0;
    end
  endtask

  // Generate a change event, verify one packet appears (with DUT latency),
  // optionally hold it (pkt_ready=0), then accept it.
  task send_change_and_consume;
    input       new_ap;
    input integer hold_cycles; // number of cycles to hold with pkt_ready=0 after pkt_valid asserts
    integer k;
    begin
      // cause the change
      ap_level   = new_ap;
      pkt_ready  = 1'b0;

      // Cycle 1: DUT detects change, captures pkt_byte, sets pending
      nothing_sent = 1'b0;
      step;
      expect(pkt_byte === make_pkt(new_ap, neuron_id), "Event: pkt_byte mismatch right after change capture");
      expect(dropped  === 1'b0, "Event: dropped should be 0 on capture");

      // Cycle 2: pkt_valid should assert (pending reflected)
      step;
      expect(pkt_valid === 1'b1, "Event: pkt_valid should assert one cycle after capture");
      expect(dropped   === 1'b0, "Event: dropped should remain 0");

      // Hold while not ready
      for (k = 0; k < hold_cycles; k = k + 1) begin
        step;
        expect(pkt_valid === 1'b1, "Hold: pkt_valid should stay high while pkt_ready=0");
        expect(pkt_byte  === make_pkt(new_ap, neuron_id), "Hold: pkt_byte should stay stable");
      end

      // Accept
      pkt_ready = 1'b1;

      // Cycle 3: handshake clears pending internally
      step;

      // Cycle 4: pkt_valid drops due to 1-cycle latency
      step;
      expect(pkt_valid === 1'b0, "After accept: pkt_valid should deassert");
      pkt_ready = 1'b0;
    end
  endtask

  initial begin
    // Constant neuron id = 0001
    neuron_id = 4'b0001;

    // init
    ap_level      = 1'b0;
    pkt_ready     = 1'b0;
    nothing_sent  = 1'b0;

    // ASSERT reset (active-high)
    reset = 1'b1;

    // hold reset for 3 cycles (extra-safe)
    step; step; step;

    expect(pkt_valid == 1'b0, "Reset: pkt_valid should be 0");
    expect(dropped   == 1'b0, "Reset: dropped should be 0");

    // deassert reset
    reset = 1'b0;
    step;

    // ------------------------------------------------------------
    // Phase 1: ap_level stays 0 for many cycles -> NO packets
    // ------------------------------------------------------------
    ap_level = 1'b0;
    expect_nothing_for(6, "No-change (ap_level=0): pkt_valid should remain 0");

    // ------------------------------------------------------------
    // Phase 2: Change 0 -> 1 -> exactly one packet, hold it a bit, consume
    // ------------------------------------------------------------
    send_change_and_consume(1'b1, 3);

    // After consuming, keep ap_level at 1 for many cycles -> NO packets
    ap_level = 1'b1;
    expect_nothing_for(6, "No-change (ap_level=1): pkt_valid should remain 0");

    // ------------------------------------------------------------
    // Phase 3: Change 1 -> 0 -> exactly one packet, consume immediately
    // ------------------------------------------------------------
    send_change_and_consume(1'b0, 0);

    // After consuming, keep ap_level at 0 again -> NO packets
    ap_level = 1'b0;
    expect_nothing_for(6, "No-change again (ap_level=0): pkt_valid should remain 0");

    $display("[%0t] ALL TESTS PASSED (neuron_id=0001, packets ONLY on ap_level change)", $time);
    $finish;
  end

endmodule