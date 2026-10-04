//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: Bryce Chen
//// 
//// Create Date: 02/19/2026 12:59:41 AM
//// Design Name: 
//// Module Name: SM_Mem_Mapping
//// Project Name: 
//// Target Devices: 
//// Tool Versions: 
//// Description: 
//// 
//// Dependencies: 
//// 
//// Revision:
//// Revision 0.01 - File Created
//// Additional Comments:
//// 
////////////////////////////////////////////////////////////////////////////////////

//module SM_Mem_Mapping(
//    input  wire        clk,
//    input  wire        reset,

//    // WB3 interface (write-only for now)
//    input  wire        wb_cyc_i,
//    input  wire        wb_stb_i,
//    input  wire        wb_we_i,
//    input  wire [31:0] wb_adr_i,
//    input  wire [31:0] wb_dat_i,
//    output reg         wb_ack_o,

//    // Global tag outputs (for packet routing later)
//    output reg  [7:0]  hash0,
//    output reg  [7:0]  hash1,
//    output reg  [7:0]  hash2,
//    output reg  [7:0]  hash3,

//    // Outputs to SynapticModule
//    output reg         commitStatic,
//    output reg         commit0,
//    output reg         commit1,
//    output reg         commit2,
//    output reg         commit3,

//    output reg  [31:0] next_dt,
//    output reg  [31:0] next_Vmem,
//    output reg  [31:0] next_Vt,

//    output reg  [31:0] next_f_0,
//    output reg  [31:0] next_g_syn_bar_0,
//    output reg  [31:0] next_T_rise_0,
//    output reg  [31:0] next_ho_0,
//    output reg  [31:0] next_AP_0,
//    output reg  [31:0] next_T_decay_0,
//    output reg  [31:0] next_h_0,
//    output reg  [31:0] next_g_0,
//    output reg  [31:0] next_Esyn_0,

//    output reg  [31:0] next_f_1,
//    output reg  [31:0] next_g_syn_bar_1,
//    output reg  [31:0] next_T_rise_1,
//    output reg  [31:0] next_ho_1,
//    output reg  [31:0] next_AP_1,
//    output reg  [31:0] next_T_decay_1,
//    output reg  [31:0] next_h_1,
//    output reg  [31:0] next_g_1,
//    output reg  [31:0] next_Esyn_1,

//    output reg  [31:0] next_f_2,
//    output reg  [31:0] next_g_syn_bar_2,
//    output reg  [31:0] next_T_rise_2,
//    output reg  [31:0] next_ho_2,
//    output reg  [31:0] next_AP_2,
//    output reg  [31:0] next_T_decay_2,
//    output reg  [31:0] next_h_2,
//    output reg  [31:0] next_g_2,
//    output reg  [31:0] next_Esyn_2,

//    output reg  [31:0] next_f_3,
//    output reg  [31:0] next_g_syn_bar_3,
//    output reg  [31:0] next_T_rise_3,
//    output reg  [31:0] next_ho_3,
//    output reg  [31:0] next_AP_3,
//    output reg  [31:0] next_T_decay_3,
//    output reg  [31:0] next_h_3,
//    output reg  [31:0] next_g_3,
//    output reg  [31:0] next_Esyn_3
//);

//    // ----------------------------
//    // Address map constants
//    // ----------------------------
//    localparam [31:0] SYN_BASE = 32'h3070_0000;

//    // Synapse offsets (within each 0x100 page)
//    localparam [7:0] OFF_F         = 8'h00;
//    localparam [7:0] OFF_GSYNBAR   = 8'h04;
//    localparam [7:0] OFF_H0        = 8'h08;  // maps to ho in your RF
//    localparam [7:0] OFF_ESYN      = 8'h0C;
//    localparam [7:0] OFF_TRISEINV  = 8'h10;
//    localparam [7:0] OFF_TDECAYINV = 8'h14;
//    localparam [7:0] OFF_H         = 8'h18;
//    localparam [7:0] OFF_G         = 8'h1C;
//    localparam [7:0] OFF_AP        = 8'h20;

//    // Global region base offset (BASE + 0x400 + offset)
//    localparam [11:0] OFF_GLOBAL_BASE = 12'h400;

//    // Global offsets (within global page)
//    localparam [7:0] OFF_DT      = 8'h00;
//    localparam [7:0] OFF_VMEM    = 8'h04;
//    localparam [7:0] OFF_VTHRESH = 8'h08;

//    // Hash offsets (within global page)
//    localparam [7:0] OFF_HASH0   = 8'h14;
//    localparam [7:0] OFF_HASH1   = 8'h18;
//    localparam [7:0] OFF_HASH2   = 8'h1C;
//    localparam [7:0] OFF_HASH3   = 8'h20;

//    // Wishbone helpers
//    wire wb_xfer = wb_cyc_i & wb_stb_i;

//    // one-cycle ack for writes
//    always @(posedge clk) begin
//        if (reset) wb_ack_o <= 1'b0;
//        else       wb_ack_o <= wb_xfer & wb_we_i;
//    end

//    // base-relative address
//    wire [31:0] address_offset = wb_adr_i - SYN_BASE;

//    // global select: [0x400..0x4FF]
//    wire is_global = (address_offset[11:0] >= OFF_GLOBAL_BASE) &&
//                     (address_offset[11:0] <  (OFF_GLOBAL_BASE + 12'h100));

//    // synapse addressing: neuron_id in [15:8], reg_offset in [7:0]
//    wire [7:0] neuron_id  = address_offset[15:8];
//    wire [7:0] reg_offset = address_offset[7:0];

//    // legacy slot decode (0x000/0x100/0x200/0x300) from your old mapping
//    wire [1:0] decoded_synapse = address_offset[9:8];

//    // Tag compare: neuron_id -> slot
//    reg       slot_valid;
//    reg [1:0] slot_sel;

//    always @(*) begin
//        slot_valid = 1'b0;
//        slot_sel   = 2'd0;

//        if (neuron_id == hash0) begin slot_valid = 1'b1; slot_sel = 2'd0; end
//        else if (neuron_id == hash1) begin slot_valid = 1'b1; slot_sel = 2'd1; end
//        else if (neuron_id == hash2) begin slot_valid = 1'b1; slot_sel = 2'd2; end
//        else if (neuron_id == hash3) begin slot_valid = 1'b1; slot_sel = 2'd3; end
//    end

//    // choose slot: prefer hash-lookup, fallback to address decode
//    wire [1:0] slot = slot_valid ? slot_sel : decoded_synapse;

//    // Write / commit logic
//    always @(posedge clk) begin
//        if (reset) begin
//            // commit pulses low
//            commitStatic <= 1'b0;
//            commit0      <= 1'b0;
//            commit1      <= 1'b0;
//            commit2      <= 1'b0;
//            commit3      <= 1'b0;

//            // globals init
//            next_dt   <= 32'b0;
//            next_Vmem <= 32'b0;
//            next_Vt   <= 32'b0;

//            // hash init (optional default mapping)
//            hash0 <= 8'd0;
//            hash1 <= 8'd1;
//            hash2 <= 8'd2;
//            hash3 <= 8'd3;

//            // synapse regs init
//            next_f_0 <= 32'b0; next_g_syn_bar_0 <= 32'b0; next_T_rise_0 <= 32'b0; next_ho_0 <= 32'b0; next_AP_0 <= 32'b0; next_T_decay_0 <= 32'b0; next_h_0 <= 32'b0; next_g_0 <= 32'b0; next_Esyn_0 <= 32'b0;
//            next_f_1 <= 32'b0; next_g_syn_bar_1 <= 32'b0; next_T_rise_1 <= 32'b0; next_ho_1 <= 32'b0; next_AP_1 <= 32'b0; next_T_decay_1 <= 32'b0; next_h_1 <= 32'b0; next_g_1 <= 32'b0; next_Esyn_1 <= 32'b0;
//            next_f_2 <= 32'b0; next_g_syn_bar_2 <= 32'b0; next_T_rise_2 <= 32'b0; next_ho_2 <= 32'b0; next_AP_2 <= 32'b0; next_T_decay_2 <= 32'b0; next_h_2 <= 32'b0; next_g_2 <= 32'b0; next_Esyn_2 <= 32'b0;
//            next_f_3 <= 32'b0; next_g_syn_bar_3 <= 32'b0; next_T_rise_3 <= 32'b0; next_ho_3 <= 32'b0; next_AP_3 <= 32'b0; next_T_decay_3 <= 32'b0; next_h_3 <= 32'b0; next_g_3 <= 32'b0; next_Esyn_3 <= 32'b0;

//        end else begin
//            // default: drop commit pulses
//            commitStatic <= 1'b0;
//            commit0      <= 1'b0;
//            commit1      <= 1'b0;
//            commit2      <= 1'b0;
//            commit3      <= 1'b0;

//            // handle WB writes
//            if (wb_xfer && wb_we_i) begin

//                // GLOBAL WRITES (BASE + 0x400 + offset)
//                if (is_global) begin
//                    case (address_offset[7:0])
//                        OFF_DT: begin
//                            next_dt      <= wb_dat_i;
//                            commitStatic <= 1'b1;
//                        end
//                        OFF_VMEM: begin
//                            next_Vmem    <= wb_dat_i;
//                            commitStatic <= 1'b1;
//                        end
//                        OFF_VTHRESH: begin
//                            next_Vt      <= wb_dat_i;
//                            commitStatic <= 1'b1;
//                        end

//                        OFF_HASH0: hash0 <= wb_dat_i[7:0];
//                        OFF_HASH1: hash1 <= wb_dat_i[7:0];
//                        OFF_HASH2: hash2 <= wb_dat_i[7:0];
//                        OFF_HASH3: hash3 <= wb_dat_i[7:0];

//                        default: begin end
//                    endcase
//                end

//                // SYNAPSE WRITES (BASE + (neuron_id<<8) + reg_offset)
//                else begin
//                    case (slot)
//                        2'd0: begin
//                            case (reg_offset)
//                                OFF_F:         next_f_0         <= wb_dat_i;
//                                OFF_GSYNBAR:   next_g_syn_bar_0 <= wb_dat_i;
//                                OFF_H0:        next_ho_0        <= wb_dat_i;
//                                OFF_ESYN:      next_Esyn_0      <= wb_dat_i;
//                                OFF_TRISEINV:  next_T_rise_0    <= wb_dat_i;
//                                OFF_TDECAYINV: next_T_decay_0   <= wb_dat_i;
//                                OFF_H:         next_h_0         <= wb_dat_i;
//                                OFF_G:         next_g_0         <= wb_dat_i;
//                                OFF_AP:        next_AP_0        <= wb_dat_i;
//                                default: begin end
//                            endcase
//                            commit0 <= 1'b1;
//                        end

//                        2'd1: begin
//                            case (reg_offset)
//                                OFF_F:         next_f_1         <= wb_dat_i;
//                                OFF_GSYNBAR:   next_g_syn_bar_1 <= wb_dat_i;
//                                OFF_H0:        next_ho_1        <= wb_dat_i;
//                                OFF_ESYN:      next_Esyn_1      <= wb_dat_i;
//                                OFF_TRISEINV:  next_T_rise_1    <= wb_dat_i;
//                                OFF_TDECAYINV: next_T_decay_1   <= wb_dat_i;
//                                OFF_H:         next_h_1         <= wb_dat_i;
//                                OFF_G:         next_g_1         <= wb_dat_i;
//                                OFF_AP:        next_AP_1        <= wb_dat_i;
//                                default: begin end
//                            endcase
//                            commit1 <= 1'b1;
//                        end

//                        2'd2: begin
//                            case (reg_offset)
//                                OFF_F:         next_f_2         <= wb_dat_i;
//                                OFF_GSYNBAR:   next_g_syn_bar_2 <= wb_dat_i;
//                                OFF_H0:        next_ho_2        <= wb_dat_i;
//                                OFF_ESYN:      next_Esyn_2      <= wb_dat_i;
//                                OFF_TRISEINV:  next_T_rise_2    <= wb_dat_i;
//                                OFF_TDECAYINV: next_T_decay_2   <= wb_dat_i;
//                                OFF_H:         next_h_2         <= wb_dat_i;
//                                OFF_G:         next_g_2         <= wb_dat_i;
//                                OFF_AP:        next_AP_2        <= wb_dat_i;
//                                default: begin end
//                            endcase
//                            commit2 <= 1'b1;
//                        end

//                        2'd3: begin
//                            case (reg_offset)
//                                OFF_F:         next_f_3         <= wb_dat_i;
//                                OFF_GSYNBAR:   next_g_syn_bar_3 <= wb_dat_i;
//                                OFF_H0:        next_ho_3        <= wb_dat_i;
//                                OFF_ESYN:      next_Esyn_3      <= wb_dat_i;
//                                OFF_TRISEINV:  next_T_rise_3    <= wb_dat_i;
//                                OFF_TDECAYINV: next_T_decay_3   <= wb_dat_i;
//                                OFF_H:         next_h_3         <= wb_dat_i;
//                                OFF_G:         next_g_3         <= wb_dat_i;
//                                OFF_AP:        next_AP_3        <= wb_dat_i;
//                                default: begin end
//                            endcase
//                            commit3 <= 1'b1;
//                        end

//                        default: begin end
//                    endcase
//                end
//            end
//        end
//    end
// //harder than i thought need to figure out logic to decode into the register in the SM but encode them here.
// //chang said use decoder for the offserts
// //dont think we need arbiter since SM doesnt communicate with anything in the wishbone 4 bus

//endmodule









`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Bryce Chen
//
// Create Date: 02/19/2026 12:59:41 AM
// Design Name:
// Module Name: SM_Mem_Mapping
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

module SM_Mem_Mapping(
    input  wire        clk,
    input  wire        reset,

    // WB3 interface (write-only for now)
    input  wire        wb_cyc_i,
    input  wire        wb_stb_i,
    input  wire        wb_we_i,
    input  wire [31:0] wb_adr_i,
    input  wire [31:0] wb_dat_i,
    output reg         wb_ack_o,

    // Global tag outputs (for packet routing later)
    output reg  [7:0]  hash0,
    output reg  [7:0]  hash1,
    output reg  [7:0]  hash2,
    output reg  [7:0]  hash3,

    // Outputs to SynapticModule
    output reg         commitStatic,
    output reg         commit0,
    output reg         commit1,
    output reg         commit2,
    output reg         commit3,

    output reg  [31:0] next_dt,
    output reg  [31:0] next_Vmem,
    output reg  [31:0] next_Vt,

    output reg  [31:0] next_f_0,
    output reg  [31:0] next_g_syn_bar_0,
    output reg  [31:0] next_T_rise_0,
    output reg  [31:0] next_ho_0,
    output reg  [31:0] next_AP_0,
    output reg  [31:0] next_T_decay_0,
    output reg  [31:0] next_h_0,
    output reg  [31:0] next_g_0,
    output reg  [31:0] next_Esyn_0,

    output reg  [31:0] next_f_1,
    output reg  [31:0] next_g_syn_bar_1,
    output reg  [31:0] next_T_rise_1,
    output reg  [31:0] next_ho_1,
    output reg  [31:0] next_AP_1,
    output reg  [31:0] next_T_decay_1,
    output reg  [31:0] next_h_1,
    output reg  [31:0] next_g_1,
    output reg  [31:0] next_Esyn_1,

    output reg  [31:0] next_f_2,
    output reg  [31:0] next_g_syn_bar_2,
    output reg  [31:0] next_T_rise_2,
    output reg  [31:0] next_ho_2,
    output reg  [31:0] next_AP_2,
    output reg  [31:0] next_T_decay_2,
    output reg  [31:0] next_h_2,
    output reg  [31:0] next_g_2,
    output reg  [31:0] next_Esyn_2,

    output reg  [31:0] next_f_3,
    output reg  [31:0] next_g_syn_bar_3,
    output reg  [31:0] next_T_rise_3,
    output reg  [31:0] next_ho_3,
    output reg  [31:0] next_AP_3,
    output reg  [31:0] next_T_decay_3,
    output reg  [31:0] next_h_3,
    output reg  [31:0] next_g_3,
    output reg  [31:0] next_Esyn_3
);

    // ----------------------------
    // Address map constants
    // ----------------------------
    localparam [31:0] SYN_BASE = 32'h3070_0000;

    // Synapse offsets (within each 0x100 page)
    localparam [7:0] OFF_F         = 8'h00;
    localparam [7:0] OFF_GSYNBAR   = 8'h04;
    localparam [7:0] OFF_H0        = 8'h08;  // maps to ho in your RF
    localparam [7:0] OFF_ESYN      = 8'h0C;
    localparam [7:0] OFF_TRISEINV  = 8'h10;
    localparam [7:0] OFF_TDECAYINV = 8'h14;
    localparam [7:0] OFF_H         = 8'h18;
    localparam [7:0] OFF_G         = 8'h1C;
    localparam [7:0] OFF_AP        = 8'h20;
    localparam [7:0] OFF_COMMIT    = 8'h24;

    // Global region base offset (BASE + 0x400 + offset)
    localparam [11:0] OFF_GLOBAL_BASE = 12'h400;

    // Global offsets (within global page)
    localparam [7:0] OFF_DT           = 8'h00;
    localparam [7:0] OFF_VMEM         = 8'h04;
    localparam [7:0] OFF_VTHRESH      = 8'h08;
    localparam [7:0] OFF_COMMITSTATIC = 8'h0C;

    // Hash offsets (within global page)
    localparam [7:0] OFF_HASH0        = 8'h14;
    localparam [7:0] OFF_HASH1        = 8'h18;
    localparam [7:0] OFF_HASH2        = 8'h1C;
    localparam [7:0] OFF_HASH3        = 8'h20;

    // Wishbone helpers
    wire wb_xfer = wb_cyc_i & wb_stb_i;

    // one-cycle ack for writes
    always @(posedge clk) begin
        if (reset)
            wb_ack_o <= 1'b0;
        else
            wb_ack_o <= wb_xfer & wb_we_i;
    end

    // base-relative address
    wire [31:0] address_offset = wb_adr_i - SYN_BASE;

    // global select: [0x400..0x4FF]
    wire is_global = (address_offset[11:0] >= OFF_GLOBAL_BASE) &&
                     (address_offset[11:0] <  (OFF_GLOBAL_BASE + 12'h100));

    // synapse addressing: neuron_id in [15:8], reg_offset in [7:0]
    wire [7:0] neuron_id  = address_offset[15:8];
    wire [7:0] reg_offset = address_offset[7:0];

    // legacy slot decode (0x000/0x100/0x200/0x300) from old mapping
    wire [1:0] decoded_synapse = address_offset[9:8];

    // Tag compare: neuron_id -> slot
    reg       slot_valid;
    reg [1:0] slot_sel;

    always @(*) begin
        slot_valid = 1'b0;
        slot_sel   = 2'd0;

        if (neuron_id == hash0) begin
            slot_valid = 1'b1;
            slot_sel   = 2'd0;
        end else if (neuron_id == hash1) begin
            slot_valid = 1'b1;
            slot_sel   = 2'd1;
        end else if (neuron_id == hash2) begin
            slot_valid = 1'b1;
            slot_sel   = 2'd2;
        end else if (neuron_id == hash3) begin
            slot_valid = 1'b1;
            slot_sel   = 2'd3;
        end
    end

    // choose slot: prefer hash-lookup, fallback to address decode
    wire [1:0] slot = slot_valid ? slot_sel : decoded_synapse;

    // Write / commit logic
    always @(posedge clk) begin
        if (reset) begin
            commitStatic <= 1'b0;
            commit0      <= 1'b0;
            commit1      <= 1'b0;
            commit2      <= 1'b0;
            commit3      <= 1'b0;

            next_dt   <= 32'b0;
            next_Vmem <= 32'b0;
            next_Vt   <= 32'b0;

            hash0 <= 8'd0;
            hash1 <= 8'd1;
            hash2 <= 8'd2;
            hash3 <= 8'd3;

            next_f_0         <= 32'b0;
            next_g_syn_bar_0 <= 32'b0;
            next_T_rise_0    <= 32'b0;
            next_ho_0        <= 32'b0;
            next_AP_0        <= 32'b0;
            next_T_decay_0   <= 32'b0;
            next_h_0         <= 32'b0;
            next_g_0         <= 32'b0;
            next_Esyn_0      <= 32'b0;

            next_f_1         <= 32'b0;
            next_g_syn_bar_1 <= 32'b0;
            next_T_rise_1    <= 32'b0;
            next_ho_1        <= 32'b0;
            next_AP_1        <= 32'b0;
            next_T_decay_1   <= 32'b0;
            next_h_1         <= 32'b0;
            next_g_1         <= 32'b0;
            next_Esyn_1      <= 32'b0;

            next_f_2         <= 32'b0;
            next_g_syn_bar_2 <= 32'b0;
            next_T_rise_2    <= 32'b0;
            next_ho_2        <= 32'b0;
            next_AP_2        <= 32'b0;
            next_T_decay_2   <= 32'b0;
            next_h_2         <= 32'b0;
            next_g_2         <= 32'b0;
            next_Esyn_2      <= 32'b0;

            next_f_3         <= 32'b0;
            next_g_syn_bar_3 <= 32'b0;
            next_T_rise_3    <= 32'b0;
            next_ho_3        <= 32'b0;
            next_AP_3        <= 32'b0;
            next_T_decay_3   <= 32'b0;
            next_h_3         <= 32'b0;
            next_g_3         <= 32'b0;
            next_Esyn_3      <= 32'b0;

        end else begin
            // default: commit pulses low unless explicit commit address is written
            commitStatic <= 1'b0;
            commit0      <= 1'b0;
            commit1      <= 1'b0;
            commit2      <= 1'b0;
            commit3      <= 1'b0;

            if (wb_xfer && wb_we_i) begin

                // GLOBAL WRITES (BASE + 0x400 + offset)
                if (is_global) begin
                    case (address_offset[7:0])
                        OFF_DT:           next_dt   <= wb_dat_i;
                        OFF_VMEM:         next_Vmem <= wb_dat_i;
                        OFF_VTHRESH:      next_Vt   <= wb_dat_i;
                        OFF_COMMITSTATIC: commitStatic <= 1'b1;

                        OFF_HASH0:        hash0 <= wb_dat_i[7:0];
                        OFF_HASH1:        hash1 <= wb_dat_i[7:0];
                        OFF_HASH2:        hash2 <= wb_dat_i[7:0];
                        OFF_HASH3:        hash3 <= wb_dat_i[7:0];

                        default: begin end
                    endcase
                end

                // SYNAPSE WRITES (BASE + (neuron_id<<8) + reg_offset)
                else begin
                    case (slot)
                        2'd0: begin
                            case (reg_offset)
                                OFF_F:         next_f_0         <= wb_dat_i;
                                OFF_GSYNBAR:   next_g_syn_bar_0 <= wb_dat_i;
                                OFF_H0:        next_ho_0        <= wb_dat_i;
                                OFF_ESYN:      next_Esyn_0      <= wb_dat_i;
                                OFF_TRISEINV:  next_T_rise_0    <= wb_dat_i;
                                OFF_TDECAYINV: next_T_decay_0   <= wb_dat_i;
                                OFF_H:         next_h_0         <= wb_dat_i;
                                OFF_G:         next_g_0         <= wb_dat_i;
                                OFF_AP:        next_AP_0        <= wb_dat_i;
                                OFF_COMMIT:    commit0          <= 1'b1;
                                default: begin end
                            endcase
                        end

                        2'd1: begin
                            case (reg_offset)
                                OFF_F:         next_f_1         <= wb_dat_i;
                                OFF_GSYNBAR:   next_g_syn_bar_1 <= wb_dat_i;
                                OFF_H0:        next_ho_1        <= wb_dat_i;
                                OFF_ESYN:      next_Esyn_1      <= wb_dat_i;
                                OFF_TRISEINV:  next_T_rise_1    <= wb_dat_i;
                                OFF_TDECAYINV: next_T_decay_1   <= wb_dat_i;
                                OFF_H:         next_h_1         <= wb_dat_i;
                                OFF_G:         next_g_1         <= wb_dat_i;
                                OFF_AP:        next_AP_1        <= wb_dat_i;
                                OFF_COMMIT:    commit1          <= 1'b1;
                                default: begin end
                            endcase
                        end

                        2'd2: begin
                            case (reg_offset)
                                OFF_F:         next_f_2         <= wb_dat_i;
                                OFF_GSYNBAR:   next_g_syn_bar_2 <= wb_dat_i;
                                OFF_H0:        next_ho_2        <= wb_dat_i;
                                OFF_ESYN:      next_Esyn_2      <= wb_dat_i;
                                OFF_TRISEINV:  next_T_rise_2    <= wb_dat_i;
                                OFF_TDECAYINV: next_T_decay_2   <= wb_dat_i;
                                OFF_H:         next_h_2         <= wb_dat_i;
                                OFF_G:         next_g_2         <= wb_dat_i;
                                OFF_AP:        next_AP_2        <= wb_dat_i;
                                OFF_COMMIT:    commit2          <= 1'b1;
                                default: begin end
                            endcase
                        end

                        2'd3: begin
                            case (reg_offset)
                                OFF_F:         next_f_3         <= wb_dat_i;
                                OFF_GSYNBAR:   next_g_syn_bar_3 <= wb_dat_i;
                                OFF_H0:        next_ho_3        <= wb_dat_i;
                                OFF_ESYN:      next_Esyn_3      <= wb_dat_i;
                                OFF_TRISEINV:  next_T_rise_3    <= wb_dat_i;
                                OFF_TDECAYINV: next_T_decay_3   <= wb_dat_i;
                                OFF_H:         next_h_3         <= wb_dat_i;
                                OFF_G:         next_g_3         <= wb_dat_i;
                                OFF_AP:        next_AP_3        <= wb_dat_i;
                                OFF_COMMIT:    commit3          <= 1'b1;
                                default: begin end
                            endcase
                        end

                        default: begin end
                    endcase
                end
            end
        end
    end

endmodule