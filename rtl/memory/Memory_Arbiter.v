`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Team 08 - Neuroprocessor
// Engineer: Josh Schrock
// 
// Create Date: 2/27/2025 9:08:17 PM
// Module Name: Memory_Arbiter
// Description: Arbitration module between Wishbone interfaces.
// 
//////////////////////////////////////////////////////////////////////////////////


module Memory_Arbiter #(parameter 
    WAIT_TIME = 0,
    AddressWidth=32, 
    DataWidth=32
    )(
    input wire clock, reset,
    
    // b3 I/O wires
    input wire b3_active,
    input wire [AddressWidth-1:0] b3_adr,
    input wire [DataWidth-1:0] b3_dataIn,
    input wire b3_write,
    input wire [3:0] b3_select,
    output wire b3_busy,
    output wire [DataWidth-1:0] b3_dataOut,
    
    // b4 I/O wires
    input wire b4_active,
    input wire [AddressWidth-1:0] b4_adr,
    input wire [DataWidth-1:0] b4_dataIn,
    input wire b4_write,
    input wire [3:0] b4_select,
    output wire b4_busy,
    output wire [DataWidth-1:0] b4_dataOut,
    
    // LUT wires
    input wire process,
    input wire [DataWidth-1:0] dataOut,
    output wire [AddressWidth-1:0] address,
    output wire [DataWidth-1:0] dataIn,
    output wire write,
    output wire [3:0] select
    );
    
    // State definitions
    localparam FREE = 2'd0, PROCESSING = 2'd1, ACK = 2'd2;
    reg [1:0] current_state, next_state;
    reg [2:0] counter;
    
    //simple priority arbitration prioritizing b3
    wire sel_wb = b3_active | !(b4_active);
    wire strobe = sel_wb ? b3_active : b4_active;
    
    //saveing registers
    reg LUT_busy;
    reg [AddressWidth-1:0] address_reg;
    reg [DataWidth-1:0] dataIn_reg;
    reg write_reg;
    reg [3:0] select_reg;
    reg [DataWidth-1:0] dataOut_reg;
    
    //set outputs to passthrough or register
    reg processing_flag;
    wire [31:0] address_in = sel_wb ? b3_adr : b4_adr;
    wire [31:0] data_in = sel_wb ? b3_dataIn : b4_dataIn;
    wire write_in = sel_wb ? b3_write : b4_write;
    wire [3:0] select_in = sel_wb ? b3_select : b4_select;
    assign address = processing_flag ? address_reg : address_in;
    assign dataIn = processing_flag ? dataIn_reg : data_in;
    assign write = processing_flag ? write_reg : write_in;
    assign select = processing_flag ? select_reg : select_in;
    assign b3_busy = processing_flag ? 1 : (sel_wb ? 0 : 1);
    assign b4_busy = processing_flag ? 1 : (sel_wb ? 1 : 0);
    assign b3_dataOut = dataOut;
    assign b4_dataOut = dataOut;
    
    always @ (posedge clock)
        if (reset) begin
            address_reg <= 32'b0;
            dataIn_reg <= 32'b0;
            write_reg <= 1'b0;
            select_reg <= 4'b0;
        end else if (!processing_flag) begin
            address_reg <= address_in;
            dataIn_reg <= data_in;
            write_reg <= write_in;
            select_reg <= select_in;
        end

    
    //counter logic
    always @(posedge clock) begin
        if (current_state == PROCESSING) begin
            counter <= counter + 1;
        end else begin
            counter <= 0;
        end
    end
    
    // State transition logic
    always @(posedge clock) begin
        if (reset) begin
            current_state <= FREE;
        end else begin
            current_state <= next_state;    
        end
    end
    
    // Next state logic
    always @(*) begin
        case (current_state)
            FREE: begin 
                if (process == 1 & strobe)
                    next_state <= PROCESSING;
                else
                    next_state <= FREE;
                end
            PROCESSING: begin
                if (counter >= WAIT_TIME)
                    if (sel_wb == 1)
                        next_state <= ACK;
                    else
                        next_state <= FREE;
                else
                    next_state <= PROCESSING;
                end
            ACK: begin
                next_state <= FREE;
                end
            default:
                next_state <= FREE;
        endcase
    end
    
    //output logic
    always @(current_state) begin
        case(current_state)
            FREE: begin
                // Free
                processing_flag <= 1'b0;
            end
            PROCESSING:begin
                // If B3 was active, latch B3 address and data, otherwise b4
                processing_flag <= 1'b1;
            end
            ACK: begin
                // Free
                processing_flag <= 1'b0;
            end
            default: begin
                processing_flag <= 1'b0;
            end
        endcase
    end
    
endmodule
