`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Simarjit Dhillon
// 
// Create Date: 02/09/2025 06:18:56 PM
// Design Name: 
// Module Name: memory_intf
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


module memory_intf #(parameter
    AddressWidth=32, 
    DataWidth=32,
    MemWidth=10
)(
//universal
input wire clock, reset,

////wishbone B3 peripheral - processor
//input wire wb3_clk_i, wb3_rst_i,
input wire wb3_cyc_i, wb3_stb_i, wb3_we_i,
input wire [AddressWidth-1:0] wb3_adr_i,
input wire [(DataWidth/8)-1:0] wb3_sel_i,
input wire [DataWidth-1:0] wb3_dat_i,
output wire [DataWidth-1:0] wb3_dat_o,
output wire wb3_ack_o,

//wishbone B4 peripheral - DMA
//input wire wb4_clk_i, wb4_rst_i,
input wire wb4_cyc_i, wb4_stb_i, wb4_we_i,
input wire [AddressWidth-1:0] wb4_adr_i,
input wire [(DataWidth/8)-1:0] wb4_sel_i,
input wire [DataWidth-1:0] wb4_dat_i,
output wire [DataWidth-1:0] wb4_dat_o,
output wire wb4_ack_o, wb4_stall_o, wb4_err_o
);



    // b3 wires
    wire [31:0] b3_adr;
    wire [31:0] b3_dataIn;
    wire b3_write;
    wire [3:0] b3_select;
    wire b3_active;
    wire b3_busy;
    
    wire [31:0] b3_dataOut;
    
    // b4 wires
    wire [31:0] b4_adr;
    wire [31:0] b4_dataIn;
    wire b4_write;
    wire [3:0] b4_select;
    wire b4_active;
    wire b4_busy;
    
    wire [31:0] b4_dataOut;
    
    wire sel_wb = b3_active | !(b4_active);
    
    wire [DataWidth-1:0] dataOut; //final exiting data
    
    wire [31:0] address;
    wire [DataWidth-1:0] dataIn;
    wire write;
    wire [3:0] select;
    
    wire process = !write;
    wire mem_en = b3_active | b4_active;
    
    bram bram_wb(
        .clka(clock),
        .addra(address[MemWidth+1:2]),
        .dina(dataIn),
        .douta(dataOut),
        .wea(select & {write, write, write, write}),  //bitwise and select and write bits
        .ena(mem_en)
    );
    
    
  // Instantiate WB3_Interface
    WB3_Interface wb3_intf (
        .wb3_clk_i(clock),
        .wb3_rst_i(reset),
        .wbs3_stb_i(wb3_stb_i),
        .wbs3_cyc_i(wb3_cyc_i),
        .wbs3_we_i(wb3_we_i),
        .wbs3_sel_i(wb3_sel_i),
        .wbs3_dat_i(wb3_dat_i),
        .wbs3_adr_i(wb3_adr_i),
        .wbs3_ack_o(wb3_ack_o),
        .wbs3_dat_o(wb3_dat_o),
        
        .b3_active(b3_active),
        .b3_busy(b3_busy),
        .b3_int_address(b3_adr),
        .b3_int_dataIn(b3_dataIn),
        .b3_int_write(b3_write),
        .b3_int_select(b3_select),
        .per3_dat_o(b3_dataOut)
    );

    // Instantiate WB4_Interface
    WB4_Interface wb4_intf (
        .wb4_clk_i(clock),
        .wb4_rst_i(reset),
        .wbs4_stb_i(wb4_stb_i),
        .wbs4_cyc_i(wb4_cyc_i),
        .wbs4_we_i(wb4_we_i),
        .wbs4_sel_i(wb4_sel_i),
        .wbs4_dat_i(wb4_dat_i),
        .wbs4_adr_i(wb4_adr_i),
        .wbs4_ack_o(wb4_ack_o),
        .wbs4_stall_o(wb4_stall_o),
        .wbs4_dat_o(wb4_dat_o),
        
        .b4_active(b4_active),
        .b4_busy(b4_busy),
        .b4_int_address(b4_adr),
        .b4_int_dataIn(b4_dataIn),
        .b4_int_write(b4_write),
        .b4_int_select(b4_select),
        .per4_dat_o(b4_dataOut)
    );
    
    Memory_Arbiter #(
    .WAIT_TIME(0)
    ) mem_arb (
        .clock(clock),
        .reset(reset),
        
        .b3_active(b3_active),
        .b3_busy(b3_busy),
        .b3_adr(b3_adr),
        .b3_dataIn(b3_dataIn),
        .b3_write(b3_write),
        .b3_select(b3_select),
        .b3_dataOut(b3_dataOut),
        
        .b4_active(b4_active),
        .b4_busy(b4_busy),
        .b4_adr(b4_adr),
        .b4_dataIn(b4_dataIn),
        .b4_write(b4_write),
        .b4_select(b4_select),
        .b4_dataOut(b4_dataOut),
        
        .address(address),
        .dataIn(dataIn),
        .write(write),
        .select(select),
        .process(process),
        .dataOut(dataOut)
    );

endmodule
