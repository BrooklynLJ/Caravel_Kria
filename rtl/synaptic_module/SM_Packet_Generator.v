`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Bryce Chen
// 
// Create Date: 02/20/2026 03:03:17 PM
// Design Name: 
// Module Name: SM_Packet_Generator
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


module SM_Packet_Generator(
    input  wire       clk,
    input  wire       reset,        // ACTIVE-HIGH reset (matches: if (reset) ...)

    // From synaptic core logic
    input  wire [3:0] neuron_id,
    input  wire       ap_level,     // current AP state (0/1)

    // Output toward "Ethernet/SPI side" later
    output reg  [7:0] pkt_byte,
    output reg        pkt_valid,
    input  wire       pkt_ready,

    output reg        dropped       // pulses if event happens while busy (optional debug)
);

    reg ap_prev;
    wire ap_change = ap_level ^ ap_prev;   // 1 when 0->1 OR 1->0

    reg pending;

    always @(posedge clk) begin
        if (reset) begin
            ap_prev   <= 1'b0;
            pending   <= 1'b0;
            pkt_byte  <= 8'd0;
            pkt_valid <= 1'b0;
            dropped   <= 1'b0;
        end else begin
            // track previous AP level
            ap_prev <= ap_level;

            // defaults
            dropped   <= 1'b0;
            pkt_valid <= pending;   // valid whenever a packet is pending

            // If AP changes state, create a new packet (if not already holding one)
            if (ap_change) begin
                if (!pending) begin
                    pending  <= 1'b1;
                    // format: {000, neuron_id[3:0], ap_level}
                    pkt_byte <= {3'b000, neuron_id, ap_level};
                end else begin
                    dropped <= 1'b1;  // change happened but we were still waiting to send
                end
            end

            // Handshake: if downstream accepts, clear pending
            if (pending && pkt_ready) begin
                pending <= 1'b0;
            end
        end
    end

endmodule