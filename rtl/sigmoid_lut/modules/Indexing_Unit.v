`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Team 8
// Engineer: Josh Schrock
// 
// Create Date: 11/04/2024 05:57:36 PM
// Module Name: Parallel_Memory_Unit
// Description: Takes in a value and compares against 32 other values to produce an index
// 
//////////////////////////////////////////////////////////////////////////////////


module Indexing_Unit(
    input wire [31:0] Vm, // Input 32-bit Vm value from the Wishbone Controller
    input wire [(32*32)-1:0] V, //32x32 entire V table from the V unit
    output reg Invalid,
    output reg [4:0]I // I unit output (single 5 bit value (fed to Address unit)
    );

//floating compare boolean result for A >= B
wire D[31:0];
// XOR comparison results
wire [30:0]XCOMP;


//The above statement basically does the following.
// returns A >= B via the output register
FloatingCompare f1 (Vm, V[31:0], D[0]);
FloatingCompare f2 (Vm, V[63:32], D[1]);
FloatingCompare f3 (Vm, V[95:64], D[2]);
FloatingCompare f4 (Vm, V[127:96], D[3]);
FloatingCompare f5 (Vm, V[159:128], D[4]);
FloatingCompare f6 (Vm, V[191:160], D[5]);
FloatingCompare f7 (Vm, V[223:192], D[6]);
FloatingCompare f8 (Vm, V[255:224], D[7]);
FloatingCompare f9 (Vm, V[287:256], D[8]);
FloatingCompare f10 (Vm, V[319:288], D[9]);
FloatingCompare f11 (Vm, V[351:320], D[10]);
FloatingCompare f12 (Vm, V[383:352], D[11]);
FloatingCompare f13 (Vm, V[415:384], D[12]);
FloatingCompare f14 (Vm, V[447:416], D[13]);
FloatingCompare f15 (Vm, V[479:448], D[14]);
FloatingCompare f16 (Vm, V[511:480], D[15]);
FloatingCompare f17 (Vm, V[543:512], D[16]);
FloatingCompare f18 (Vm, V[575:544], D[17]);
FloatingCompare f19 (Vm, V[607:576], D[18]);
FloatingCompare f20 (Vm, V[639:608], D[19]);
FloatingCompare f21 (Vm, V[671:640], D[20]);
FloatingCompare f22 (Vm, V[703:672], D[21]);
FloatingCompare f23 (Vm, V[735:704], D[22]);
FloatingCompare f24 (Vm, V[767:736], D[23]);
FloatingCompare f25 (Vm, V[799:768], D[24]);
FloatingCompare f26 (Vm, V[831:800], D[25]);
FloatingCompare f27 (Vm, V[863:832], D[26]);
FloatingCompare f28 (Vm, V[895:864], D[27]);
FloatingCompare f29 (Vm, V[927:896], D[28]);
FloatingCompare f30 (Vm, V[959:928], D[29]);
FloatingCompare f31 (Vm, V[991:960], D[30]);
FloatingCompare f32 (Vm, V[1023:992], D[31]);

// Find "sign bit"
assign XCOMP[0] = D[0] ^ D[1];
assign XCOMP[1] = D[1] ^ D[2];
assign XCOMP[2] = D[2] ^ D[3];
assign XCOMP[3] = D[3] ^ D[4];
assign XCOMP[4] = D[4] ^ D[5];
assign XCOMP[5] = D[5] ^ D[6];
assign XCOMP[6] = D[6] ^ D[7];
assign XCOMP[7] = D[7] ^ D[8];
assign XCOMP[8] = D[8] ^ D[9];
assign XCOMP[9] = D[9] ^ D[10];
assign XCOMP[10] = D[10] ^ D[11];
assign XCOMP[11] = D[11] ^ D[12];
assign XCOMP[12] = D[12] ^ D[13];
assign XCOMP[13] = D[13] ^ D[14];
assign XCOMP[14] = D[14] ^ D[15];
assign XCOMP[15] = D[15] ^ D[16];
assign XCOMP[16] = D[16] ^ D[17];
assign XCOMP[17] = D[17] ^ D[18];
assign XCOMP[18] = D[18] ^ D[19];
assign XCOMP[19] = D[19] ^ D[20];
assign XCOMP[20] = D[20] ^ D[21];
assign XCOMP[21] = D[21] ^ D[22];
assign XCOMP[22] = D[22] ^ D[23];
assign XCOMP[23] = D[23] ^ D[24];
assign XCOMP[24] = D[24] ^ D[25];
assign XCOMP[25] = D[25] ^ D[26];
assign XCOMP[26] = D[26] ^ D[27];
assign XCOMP[27] = D[27] ^ D[28];
assign XCOMP[28] = D[28] ^ D[29];
assign XCOMP[29] = D[29] ^ D[30];
assign XCOMP[30] = D[30] ^ D[31];

wire ALL = D[31] == 1;

//find index
always @(*) begin
    case(XCOMP) 
        32'd0: begin // less than or greater than the range represented by XCOMP
               if(ALL) begin 
                    I<=32'd31; Invalid<=1; 
               end else begin 
                    I<=0; Invalid<=1; end
               end
        32'd1: begin I<=0; Invalid<=0; end
        32'd2: begin I<=1; Invalid<=0; end
        32'd4: begin I<=2; Invalid<=0; end
        32'd8: begin I<=3; Invalid<=0; end
        32'd16: begin I<=4; Invalid<=0; end
        32'd32: begin I<=5; Invalid<=0; end
        32'd64: begin I<=6; Invalid<=0; end
        32'd128: begin I<=7; Invalid<=0; end
        32'd256: begin I<=8; Invalid<=0; end
        32'd512: begin I<=9; Invalid<=0; end
        32'd1024: begin I<=10; Invalid<=0; end
        32'd2048: begin I<=11; Invalid<=0; end
        32'd4096: begin I<=12; Invalid<=0; end
        32'd8192: begin I<=13; Invalid<=0; end
        32'd16384: begin I<=14; Invalid<=0; end
        32'd32768: begin I<=15; Invalid<=0; end
        32'd65536: begin I<=16; Invalid<=0; end
        32'd131072: begin I<=17;  Invalid<=0; end
        32'd262144: begin I<=18; Invalid<=0; end
        32'd524288: begin I<=19; Invalid<=0; end
        32'd1048576: begin I<=20; Invalid<=0; end
        32'd2097152: begin I<=21;  Invalid<=0; end
        32'd4194304: begin I<=22; Invalid<=0; end
        32'd8388608: begin I<=23; Invalid<=0; end
        32'd16777216: begin I<=24; Invalid<=0; end
        32'd33554432: begin I<=25; Invalid<=0; end
        32'd67108864: begin I<=26; Invalid<=0; end
        32'd134217728: begin I<=27;  Invalid<=0; end
        32'd268435456: begin I<=28; Invalid<=0; end
        32'd536870912: begin I<=29; Invalid<=0; end
        32'd1073741824: begin I<=30; Invalid<=0; end
        default:begin I<=0;  Invalid<=1; end
   endcase
end

endmodule
