`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Team 08 - Neuroprocessor
// Engineer: Josh Schrock
// 
// Create Date: 2/24/2025 12:54:30 AM
// Module Name: LUT_Arbiter
// Description: Arbitration module between Wishbone interfaces.
// 
//////////////////////////////////////////////////////////////////////////////////


module LUT_Arbiter #(parameter 
    WAIT_TIME = 1, 
    AddressWidth=32, 
    DataWidth=32
    )(
    input wire clock, reset,
    
    // b3 I/O wires
    input wire b3_active,
    input wire [AddressWidth-1:0] b3_adr,
    input wire [DataWidth-1:0] b3_dataIn,
    input wire b3_write,
    output wire b3_busy,
    output wire [DataWidth-1:0] b3_dataOut,
    
    // b4 I/O wires
    input wire b4_active,
    input wire [AddressWidth-1:0] b4_adr,
    input wire [DataWidth-1:0] b4_dataIn,
    input wire b4_write,
    output wire b4_busy,
    output wire [DataWidth-1:0] b4_dataOut,
    
    // LUT wires
    input wire process,
    input wire [DataWidth-1:0] dataOut,
    output wire [AddressWidth-1:0] address,
    output wire [DataWidth-1:0] dataIn,
    output wire write
    );
    
    // State definitions
    localparam [1:0] FREE = 2'd0, PROCESSING = 2'd1, WAIT_READ = 2'd2, READ = 2'd3;
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
    reg [DataWidth-1:0] wait_reg;
    reg [DataWidth-1:0] dataOut_reg;
    
    //set outputs to passthrough or register
    reg processing_flag;
    reg wait_flag;
    reg read_flag;
    wire [31:0] address_in = sel_wb ? b3_adr : b4_adr;
    wire [31:0] data_in = sel_wb ? b3_dataIn : b4_dataIn;
    wire write_in = sel_wb ? b3_write : b4_write;
    
    wire hold_txn = processing_flag | wait_flag | read_flag; // Hold the latched value through WAIT_READ and READ (so the LUT datapath can't be fed different values during the wait and read phase)
    assign address = hold_txn ? address_reg : address_in;
    assign dataIn  = hold_txn ? dataIn_reg  : data_in;
    assign write   = hold_txn ? write_reg   : write_in;
    
    assign b3_busy = processing_flag ? 1 : (sel_wb ? 0 : 1);
    assign b4_busy = processing_flag ? 1 : (sel_wb ? 1 : 0);
    assign b3_dataOut = read_flag ? dataOut_reg : dataOut;
    assign b4_dataOut = read_flag ? dataOut_reg : dataOut;
    
    always @ (posedge clock)
        if (reset) begin
            address_reg <= 32'b0;
            dataIn_reg <= 32'b0;
            write_reg <= 1'b0;
        end else if (!processing_flag) begin
            address_reg <= address_in;
            dataIn_reg <= data_in;
            write_reg <= write_in;
        end
        
    always @ (posedge clock)
        if (reset) begin
            wait_reg <= 32'b0;
        end else if (!wait_flag) begin
            wait_reg <= dataOut;
        end
        
    always @ (posedge clock)
        if (reset) begin
            dataOut_reg <= 32'b0;
        end else if (!read_flag) begin
            dataOut_reg <= processing_flag ? dataOut : wait_reg;
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
                    if (~write_in & strobe)
                        next_state <= READ;
                    else
                        next_state <= WAIT_READ;
                else
                    next_state <= PROCESSING;
                end
            WAIT_READ: begin
                if (~write_in & strobe)
                    next_state <= READ;
                else
                    next_state <= WAIT_READ;
                end
            READ: begin
                if (process == 1 & strobe)
                    next_state <= PROCESSING;
                else
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
                wait_flag <= 1'b0;
                read_flag <= 1'b0;
            end
            PROCESSING:begin
                // If B3 was active, latch B3 address and data, otherwise b4
                processing_flag <= 1'b1;
                wait_flag <= 1'b0;
                read_flag <= 1'b0;
            end
            WAIT_READ:begin
                processing_flag <= 1'b0;
                wait_flag <= 1'b1;
                read_flag <= 1'b0;
            end
            READ:begin
                processing_flag <= 1'b0;
                wait_flag <= 1'b0;
                read_flag <= 1'b1;
            end
            default: begin
                processing_flag <= 1'b0;
                wait_flag <= 1'b0;
                read_flag <= 1'b0;
            end
        endcase
    end
    
endmodule
