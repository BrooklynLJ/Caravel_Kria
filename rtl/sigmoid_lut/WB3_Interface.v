`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: RHIT 24-25 Team
// Engineer: Simarjit Dhillon
// 
// Create Date: 12/08/2024
// Design Name: WB3_Interface
// Module Name: WB3_Interface
// Project Name: NPU
// Description: Default handler for B3 wb communication, to be used with all
//              modules in userspace. Currently the device must understand what
//              is being requested and handle much of the data itself, as this
//              only handles the protocol.
//////////////////////////////////////////////////////////////////////////////////


// use the following to instantiate this module
// WB3_Interface #(.PERIPHERAL_ADDR_START(start), .PERIPHERAL_ADDR_END(end) NAME (i/o definitions)
module WB3_Interface (
    input wire wb3_clk_i,
    input wire wb3_rst_i, 
    input wire wbs3_stb_i,
    input wire wbs3_cyc_i,
    input wire wbs3_we_i,           
    input wire [3:0] wbs3_sel_i,    
    input wire [31:0] wbs3_dat_i,   
    input wire [31:0] wbs3_adr_i,   
    output wire wbs3_ack_o,     
    output wire [31:0] wbs3_dat_o,
    
    // "internal" I/O
    output wire b3_active,
    input wire b3_busy,
    input wire [31:0] per3_dat_o,
    output wire [31:0] b3_int_address,
    output wire [31:0] b3_int_dataIn,
    output wire b3_int_write,
    output wire [3:0] b3_int_select
    
);
    // State definitions
    localparam  [1:0] READY = 2'd0, READ_ACK = 2'd1, WRITE_ACK = 2'd2; 
    reg [1:0] current_state, next_state;
    
    //logic to determine if module is active
    reg active_reg;
    wire strobe = (wbs3_stb_i && wbs3_cyc_i);
    assign b3_active = strobe | active_reg;

    //direct connection for input wires
    assign b3_int_address = strobe ? wbs3_adr_i : 32'b0; // Added strobe conditional to make it symmetrical to wb4
    assign b3_int_dataIn = strobe ? wbs3_dat_i : 32'b0;
    assign b3_int_write = strobe ? wbs3_we_i : 1'b0;
    assign b3_int_select = strobe ? wbs3_sel_i : 4'b0;
    
    //logical control for output wires
    assign wbs3_dat_o = b3_active ? per3_dat_o : 32'b0;
    assign wbs3_ack_o = b3_active ? (current_state == WRITE_ACK | (current_state == READ_ACK & ~b3_busy)) : 1'b0;
    
    // State transition logic
    always @(posedge wb3_clk_i) begin
        if (wb3_rst_i) begin
            current_state <= READY;
        end else begin
            current_state <= next_state;    
        end
    end
 
    // Next state logic
    always @(*) begin
        case (current_state)
            READY: begin
                if (strobe & ~b3_busy) 
                    if (wbs3_we_i)
                        next_state <= WRITE_ACK;
                    else    
                        next_state <= READ_ACK;
                else if (strobe & b3_busy)
                    if (wbs3_we_i)
                        next_state <= READY;
                    else    
                        next_state <= READ_ACK;
                else
                    next_state <= READY;
            end
            READ_ACK: begin
                if (~b3_busy) 
                    next_state <= READY;
                else
                    next_state <= READ_ACK;
            end
            WRITE_ACK: begin
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