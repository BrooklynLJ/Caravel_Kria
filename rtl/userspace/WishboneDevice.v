`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: RHIT 24-25 Team
// Engineer: Ben McDaniel
// 
// Create Date: 12/08/2024
// Design Name: WishboneDevice
// Module Name: WishboneDevice
// Project Name: NPU
// Description: Default handler for B4 wb communication, to be used with all
//              modules in userspace. Currently the device must understand what
//              is being requested and handle much of the data itself, as this
//              only handles the protocol.
//////////////////////////////////////////////////////////////////////////////////




// use the following to instantiate this module
// WishboneDevice #(.PERIPHERAL_ADDR_START(start), .PERIPHERAL_ADDR_END(end) NAME (i/o definitions)
module WishboneDevice #(
    parameter PERIPHERAL_ADDR_START = 0,
    parameter PERIPHERAL_ADDR_END = 1
)(

    input wb_clk_i,
    input wb_rst_i, 
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,           
    input [3:0] wbs_sel_i,    
    input [31:0] wbs_dat_i,   
    input [31:0] wbs_adr_i,   
    output reg wbs_ack_o,     
    output reg [31:0] wbs_dat_o,
    
    
    
    //for perheripal 
    output reg [31:0] per_adr_i,
    output reg [31:0] per_dat_i,
    input [31:0] per_dat_o,
    input per_ready //set high when perheriphal has either completed read or has correct data in per_dat_o
    
);

    // Internal registers for read and write operations
    reg [31:0] read_data_reg;   // Register for read data
    reg [31:0] write_data_reg;  // Register for write data
    reg req_reg;                // Registered version of the request signal
    reg ack_reg;                // Registered version of the acknowledgment signal
    reg ready_reg;              // Peripheral ready signal for waiting
    
    
    wire is_peripheral = (wbs_adr_i >= PERIPHERAL_ADDR_START && wbs_adr_i <= PERIPHERAL_ADDR_END);

    
    // WB protocol
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            // Reset all registers
            req_reg <= 0;
            ack_reg <= 0;
            read_data_reg <= 32'b0;
            write_data_reg <= 32'b0;
            ready_reg <= 1'b0; // Set ready to 0 after reset (assumes peripheral is NOT ready)
        end else begin
            // Request
            ready_reg <= per_ready;
            if (wbs_stb_i && wbs_cyc_i && is_peripheral) begin  // Valid cycle and strobe from the master
                //pass address to perhiperal
                per_adr_i <= wbs_adr_i;
                case (wbs_we_i)  // Write enabl
                    1'b1: begin  // Write operation
                        per_dat_i <= wbs_dat_i; // Interface outputs data to perheripal
                        // Wait for perheripal to tell interface it has completed the write
                        if (ready_reg) begin
                            ack_reg <= 1'b1;  // Acknowledge the write operation
                        end else begin
                            ack_reg <= 1'b0;  // Do not acknowledge until the peripheral is ready
                        end
                    end
                    
                    1'b0: begin  // Read operation
                        if (ready_reg) begin
                            read_data_reg <= per_dat_o;
                            ack_reg <= 1'b1;  // Acknowledge the read operation
                        end else begin
                            ack_reg <= 1'b0;  // Do not acknowledge until the peripheral is ready
                        end
                    end
                    
                    default: begin // May need more strict def of default
                        ack_reg <= 1'b0;  
                    end
                endcase
                
            end else begin
                ack_reg <= 1'b0;  // No valid request, no acknowledgment
                per_adr_i <= 32'b0; // Should be 0 if not currently being requested from
            end
        end
    end

    // Output assignments
    always @(posedge wb_clk_i) begin
        wbs_ack_o <= ack_reg;
        wbs_dat_o <= read_data_reg;
    end

endmodule
