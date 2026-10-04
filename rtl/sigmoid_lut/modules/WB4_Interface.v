`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Simarjit Dhillon and Josh Schrock
// 
// Create Date: 01/29/2025 06:07:54 PM
// Design Name: 
// Module Name: WB4_Interface
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: WB B4 interface for the LUT Module
// Revision 0.01 - File Created
// 
//////////////////////////////////////////////////////////////////////////////////
 
 
module WB4_Interface (
    input wire wb4_clk_i,
    input wire wb4_rst_i, 
    input wire wbs4_stb_i,
    input wire wbs4_cyc_i,
    input wire wbs4_we_i,           
    input wire [3:0] wbs4_sel_i,    
    input wire [31:0] wbs4_dat_i,   
    input wire [31:0] wbs4_adr_i,   
    output wire wbs4_ack_o, 
    output wire wbs4_stall_o,     
    output wire [31:0] wbs4_dat_o,

     // "internal" I/O
    output wire b4_active,
    input wire b4_busy,
    input wire [31:0] per4_dat_o,
    output wire [31:0] b4_int_address,
    output wire [31:0] b4_int_dataIn,
    output wire b4_int_write,
    output wire [3:0] b4_int_select
);

    // State definitions
    localparam  [1:0] READY = 2'd0, READ_ACK = 2'd1, WRITE_ACK = 2'd2; 
    reg [1:0] current_state, next_state;

    //logic to determine if module is active
    reg active_reg;
    wire strobe = (wbs4_stb_i && wbs4_cyc_i);
    assign b4_active = strobe | active_reg;

    //direct connection for input wires
    assign b4_int_address = strobe ? wbs4_adr_i : 32'b0;
    assign b4_int_dataIn = strobe ? wbs4_dat_i : 32'b0;
    assign b4_int_write = strobe ? wbs4_we_i : 1'b0;
    assign b4_int_select = strobe ? wbs4_sel_i : 4'b0;
    
    //logical control for output wires
    assign wbs4_dat_o = b4_active ? per4_dat_o : 32'b0;
    assign wbs4_stall_o = b4_active ? b4_busy : 1'b0;
    assign wbs4_ack_o = b4_active ? (current_state == WRITE_ACK | (current_state == READ_ACK & ~b4_busy)) : 1'b0;
    
    // State transition logic
    always @(posedge wb4_clk_i) begin
        if (wb4_rst_i) begin
            current_state <= READY;
        end else begin
            current_state <= next_state;    
        end
    end
 
    // Next state logic
    always @(*) begin
        case (current_state)
            READY: begin
                if (strobe & ~b4_busy) 
                    if (wbs4_we_i)
                        next_state <= WRITE_ACK;
                    else    
                        next_state <= READ_ACK;
                else if (strobe & b4_busy)
                    if (wbs4_we_i)
                        next_state <= READY;
                    else    
                        next_state <= READ_ACK;
                else
                    next_state <= READY;
            end
            READ_ACK: begin
                if (strobe & ~b4_busy) 
                    if (wbs4_we_i)
                        next_state <= WRITE_ACK;
                    else    
                        next_state <= READ_ACK;
                else if (~strobe & ~b4_busy)
                    next_state <= READY;
                else
                    next_state <= READ_ACK;
            end
            WRITE_ACK: begin
                if (strobe & ~b4_busy) 
                    if (wbs4_we_i)
                        next_state <= WRITE_ACK;
                    else    
                        next_state <= READ_ACK;
                else
                    next_state <= READY;
            end
            default: begin
                next_state <= READY;
            end
        endcase
    end
    
    always @(current_state) begin
        case(current_state)
        READY: active_reg <= 0;
        READ_ACK: active_reg <= 1;
        WRITE_ACK: active_reg <= 1;
        default:  active_reg <= 0;
        endcase
    end
 
endmodule