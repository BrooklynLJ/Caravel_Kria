`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Team 8
// Engineer: Josh Schrock
// 
// Create Date: 11/04/2024 05:57:36 PM
// Module Name: Memory_Unit
// Description: Stores 32 values
//
// 
//////////////////////////////////////////////////////////////////////////////////


module Memory_Unit #(parameter DataWidth=32, MemorySize=32, AddressWidth=5)
(input wire reset, clock, write,
input wire [AddressWidth-1:0] address,
input wire [DataWidth-1:0] din,
output wire [DataWidth-1:0] dout);

reg[DataWidth-1:0] memory [MemorySize-1:0]; 

always@(posedge clock)
	if(reset==1) begin
	memory[0]<= 1;
	memory[1]<= 1;
	memory[2]<= 1;
	memory[3]<= 1;
	memory[4]<= 1;
	memory[5]<= 1;
	memory[6]<= 1;
	memory[7]<= 1;
	memory[8]<= 1;
	memory[9]<= 1;
	memory[10]<= 1;
	memory[11]<= 1;
	memory[12]<= 1;
	memory[13]<= 1;
	memory[14]<= 1;
	memory[15]<= 1;
	memory[16]<= 1;
	memory[17]<= 1;
	memory[18]<= 1;
	memory[19]<= 1;
	memory[20]<= 1;
	memory[21]<= 1;
	memory[22]<= 1;
	memory[23]<= 1;
	memory[24]<= 1;
    memory[25]<= 1;
	memory[26]<= 1;
	memory[27]<= 1;
	memory[28]<= 1;
	memory[29]<= 1;
	memory[30]<= 1;
	memory[31]<= 1;
	end 
	else
		if (write==1) memory[address] <= din; 
		else  memory[address]<= memory[address];
		
assign dout = memory[address];
endmodule