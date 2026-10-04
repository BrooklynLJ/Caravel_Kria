`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Team 08 - Neuroprocessor
// Engineer: Josh Schrock and Simarjit Dhillon
// 
// Create Date: 11/22/2024 01:19:36 PM
// Module Name: LUT_Module
// Description: Toplevel module for lookup table accelerator.
// This module contains a WB3 interface, a WB4 interface, and a 
// internal arbiter that combines the WB3 and WB4 buses to create a 
// single internal bus that drives LUT logic. 
// 
// The Address map model for this module:
// 0x10xx: is the input/result
// 0x11xx: is the V bank
// 0x12xx: is the M bank
// 0x13xx: is the B bank
//
// The Modules:
// V: stored "v" values used by the indexing logic to decide which 
// appoximated equation to use for a given input. The selected line
// then decided the M and B values. V memory units are parellel as all
// 32 values must be simultaneously accessible for comparison during indexing.
// If not, we must sequentially search through each V value to find our 
// best fit approximation, which is to slow.
//
// M: stored "m" coefficients (in y = mx + b). M and B values are sequentially searched
// as once we find the correct V value, we can directly grab the associated
// M and B values. 
//
// B: stored "b" values
//////////////////////////////////////////////////////////////////////////////////


module LUT_Module #(parameter 
AddressWidth=32, 
DataWidth=32, 
MemBits=8,
ControlWidth=16,
MemWidth=5,

//offsets
F1Offset=16'h1000,
F2Offset=16'h2000,
F3Offset=16'h3000,
VOffset=16'h0100,
MOffset=16'h0200,
BOffset=16'h0300)(
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
output wire wb4_ack_o, wb4_stall_o, wb4_err_o,

//Error Diagnostic Wires
output wire Exception, Invalid, Overflow, Underflow

 );
 
    // Input wires from arbiter for address and data
    wire [AddressWidth-1:0] address;
    wire [DataWidth-1:0] dataIn;
    wire write;
    // wire to let Arbiter know to stall
    reg process;
     
    //V unit data
    reg V1write, V2write, V3write;  //v data individual write signals
    wire [DataWidth-1:0] V1outSingle, V2outSingle, V3outSingle;   //v data from individual memory blocks
    wire [DataWidth*DataWidth-1:0] V1out, V2out, V3out;   //v data from individual memory blocks
    reg [DataWidth*DataWidth-1:0] Vout;   //V data for indexing
    
    //Index unit data
    wire [MemWidth-1:0] Index;
    reg [MemWidth-1:0] MemAddress;
    
    //M unit data
    reg M1write, M2write, M3write;  //m data individual write signals
    wire [DataWidth-1:0] M1out, M2out, M3out;   //m data from individual memory blocks
    reg [DataWidth-1:0] Mout;   //m data for caluclation
    
    //B unit data
    reg B1write, B2write, B3write;  //b data individual write signals
    wire [DataWidth-1:0] B1out, B2out, B3out;   //b data from individual memory blocks
    reg [DataWidth-1:0] Bout;   //b data for calculation
    
    //MAC unit data
    wire [DataWidth-1:0] MACresult; //result from MAC block
    
    //Output data
    reg [DataWidth-1:0] dataOut; //final exiting data


always @(*)
    case(address[ControlWidth-1:MemBits])
        F1Offset[ControlWidth-1:MemBits]: begin //1000 
            dataOut <= MACresult;
            MemAddress <= Index;
            Vout <= V1out;
            Mout <= M1out;
            Bout <= B1out;
            V1write <= 0; V2write <= 0; V3write <= 0;
            M1write <= 0; M2write <= 0; M3write <= 0;
            B1write <= 0; B2write <= 0; B3write <= 0;
            process <= write;
            end 
        F1Offset[ControlWidth-1:MemBits] + 
        VOffset[ControlWidth-1:MemBits]: begin //1100
            dataOut <= V1outSingle;
            MemAddress <= address[MemBits-2:2];
            Vout <= 0;
            Mout <= 0;
            Bout <= 0;
            V1write <= write; V2write <= 0; V3write <= 0;
            M1write <= 0; M2write <= 0; M3write <= 0;
            B1write <= 0; B2write <= 0; B3write <= 0;
            process <= 0;
            end
        F1Offset[ControlWidth-1:MemBits] + 
        MOffset[ControlWidth-1:MemBits]: begin //1200
            dataOut <= M1out;
            MemAddress <= address[MemBits-2:2];
            Vout <= 0;
            Mout <= 0;
            Bout <= 0;
            V1write <= 0; V2write <= 0; V3write <= 0;
            M1write <= write; M2write <= 0; M3write <= 0;
            B1write <= 0; B2write <= 0; B3write <= 0;
            process <= 0;
            end
        F1Offset[ControlWidth-1:MemBits] + 
        BOffset[ControlWidth-1:MemBits]: begin //1300
            dataOut <= B1out;
            MemAddress <= address[MemBits-2:2]; 
            Vout <= 0;
            Mout <= 0;
            Bout <= 0;
            V1write <= 0; V2write <= 0; V3write <= 0;
            M1write <= 0; M2write <= 0; M3write <= 0;
            B1write <= write; B2write <= 0; B3write <= 0;
            process <= 0;
            end
        F2Offset[ControlWidth-1:MemBits]: begin //2000
            dataOut <= MACresult;
            MemAddress <= Index;
            Vout <= V2out;
            Mout <= M2out;
            Bout <= B2out;
            V1write <= 0; V2write <= 0; V3write <= 0;
            M1write <= 0; M2write <= 0; M3write <= 0;
            B1write <= 0; B2write <= 0; B3write <= 0;
            process <= write;
            end
        F2Offset[ControlWidth-1:MemBits] + 
        VOffset[ControlWidth-1:MemBits]: begin //2100
            dataOut <= V2outSingle;
            MemAddress <= address[MemBits-2:2]; 
            Vout <= 0;
            Mout <= 0;
            Bout <= 0;
            V1write <= 0; V2write <= write; V3write <= 0;
            M1write <= 0; M2write <= 0; M3write <= 0;
            B1write <= 0; B2write <= 0; B3write <= 0;
            process <= 0;
            end
        F2Offset[ControlWidth-1:MemBits] + 
        MOffset[ControlWidth-1:MemBits]: begin //2200
            dataOut <= M2out;
            MemAddress <= address[MemBits-2:2]; 
            Vout <= 0;
            Mout <= 0;
            Bout <= 0;
            V1write <= 0; V2write <= 0; V3write <= 0;
            M1write <= 0; M2write <= write; M3write <= 0;
            B1write <= 0; B2write <= 0; B3write <= 0;
            process <= 0;
            end
        F2Offset[ControlWidth-1:MemBits] + 
        BOffset[ControlWidth-1:MemBits]: begin //2300
            dataOut <= B2out;
            MemAddress <= address[MemBits-2:2];
            Vout <= 0;
            Mout <= 0;
            Bout <= 0; 
            V1write <= 0; V2write <= 0; V3write <= 0;
            M1write <= 0; M2write <= 0; M3write <= 0;
            B1write <= 0; B2write <= write; B3write <= 0;
            process <= 0;
            end
        F3Offset[ControlWidth-1:MemBits]: begin //3000
            dataOut <= MACresult;
            MemAddress <= Index;
            Vout <= V3out;
            Mout <= M3out;
            Bout <= B3out;
            V1write <= 0; V2write <= 0; V3write <= 0;
            M1write <= 0; M2write <= 0; M3write <= 0;
            B1write <= 0; B2write <= 0; B3write <= 0;
            process <= write;
            end
        F3Offset[ControlWidth-1:MemBits] + 
        VOffset[ControlWidth-1:MemBits]: begin //3100
            dataOut <= V3outSingle;
            MemAddress <= address[MemBits-2:2];
            Vout <= 0;
            Mout <= 0;
            Bout <= 0; 
            V1write <= 0; V2write <= 0; V3write <= write;
            M1write <= 0; M2write <= 0; M3write <= 0;
            B1write <= 0; B2write <= 0; B3write <= 0;
            process <= 0;
            end
        F3Offset[ControlWidth-1:MemBits] + 
        MOffset[ControlWidth-1:MemBits]: begin //3200
            dataOut <= M3out;
            MemAddress <= address[MemBits-2:2];
            Vout <= 0;
            Mout <= 0;
            Bout <= 0; 
            V1write <= 0; V2write <= 0; V3write <= 0;
            M1write <= 0; M2write <= 0; M3write <= write;
            B1write <= 0; B2write <= 0; B3write <= 0;
            process <= 0;
            end
        F3Offset[ControlWidth-1:MemBits] + 
        BOffset[ControlWidth-1:MemBits]: begin //3300
            dataOut <= B3out;
            MemAddress <= address[MemBits-2:2];
            Vout <= 0;
            Mout <= 0;
            Bout <= 0;
            V1write <= 0; V2write <= 0; V3write <= 0;
            M1write <= 0; M2write <= 0; M3write <= 0;
            B1write <= 0; B2write <= 0; B3write <= write;
            process <= 0;
            end
        default: begin 
            dataOut <= 0;
            MemAddress <= 0;
            Vout <= 0;
            Mout <= 0;
            Bout <= 0; 
            V1write <= 0; V2write <= 0; V3write <= 0;
            M1write <= 0; M2write <= 0; M3write <= 0;
            B1write <= 0; B2write <= 0; B3write <= 0;
            process <= 0;
            end
    endcase

// V units
Parallel_Memory_Unit 
V_Unit_1 (reset, clock, V1write, MemAddress, dataIn, V1out, V1outSingle);

Parallel_Memory_Unit  
V_Unit_2 (reset, clock, V2write, MemAddress, dataIn, V2out, V2outSingle);
 
Parallel_Memory_Unit 
V_Unit_3 (reset, clock, V3write, MemAddress, dataIn, V3out, V3outSingle);

//Indexing Unit
Indexing_Unit indexing_unit (dataIn, Vout, Invalid, Index);

// M units
Memory_Unit 
M_Unit_1 (reset, clock, M1write, MemAddress, dataIn, M1out);

Memory_Unit  
M_Unit_2 (reset, clock, M2write, MemAddress, dataIn, M2out);
 
Memory_Unit 
M_Unit_3 (reset, clock, M3write, MemAddress, dataIn, M3out);


// B units
Memory_Unit  
B_Unit_1 (reset, clock, B1write, MemAddress, dataIn, B1out);

Memory_Unit  
B_Unit_2 (reset, clock, B2write, MemAddress, dataIn, B2out);

Memory_Unit  
B_Unit_3 (reset, clock, B3write, MemAddress, dataIn, B3out);

//MAC unit
LUT_MAC_Module MAC_Unit (Mout, Bout, dataIn, Exception, Overflow, Underflow, MACresult);


// b3 wires
    wire [31:0] b3_adr;
    wire [31:0] b3_dataIn;
    wire b3_write;
    wire b3_active;
    wire b3_busy;
    
    wire [31:0] b3_dataOut;
    
    // b4 wires
    wire [31:0] b4_adr;
    wire [31:0] b4_dataIn;
    wire b4_write;
    wire b4_active;
    wire b4_busy;
    
    wire [31:0] b4_dataOut;

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
        .per4_dat_o(b4_dataOut)
    );
    
    LUT_Arbiter lut_arb (
        .clock(clock),
        .reset(reset),
        
        .b3_active(b3_active),
        .b3_busy(b3_busy),
        .b3_adr(b3_adr),
        .b3_dataIn(b3_dataIn),
        .b3_write(b3_write),
        .b3_dataOut(b3_dataOut),
        
        .b4_active(b4_active),
        .b4_busy(b4_busy),
        .b4_adr(b4_adr),
        .b4_dataIn(b4_dataIn),
        .b4_write(b4_write),
        .b4_dataOut(b4_dataOut),
        
        .address(address),
        .dataIn(dataIn),
        .write(write),
        .process(process),
        .dataOut(dataOut)
    );


endmodule
