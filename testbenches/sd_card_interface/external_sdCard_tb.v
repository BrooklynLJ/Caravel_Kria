`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Benjamin Olenick
// Create Date: 12/14/2025 04:57:24 PM
// Description: This is a tb to simulate a dummy write/read to an external SD card 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module external_sdCard_tb( );

    // Clock and Reset
    reg i_clk       = 0;
    reg i_sd_reset  = 1;
    
    // 10ns period => 100MHz clock
    always #5 i_clk = ~i_clk;
    
    // WB B4 interface
    reg i_wb_cyc            = 0; // "Valid Cycle:" Signal must be high for duration of bus event so slave knows signal is important
    reg i_wb_stb            = 0; // "Strobe:" Master drives this high to indicate start of valid data transfer cycle. Tells slave it needs to repond to the request
    reg i_wb_we             = 0; // "Write Enable:" Tells slave to either read (0)or write (1) the data
    reg [1:0] i_wb_addr     = 0; // Address that SDSPI's has defined. It contains CMD (00), DAT (01), FIFO_A (10), and FIFO_B (11). 
                                 // Command (CMD): Writing to CMD resets the FIFO word pointer (start addressing at beginning)
                                 // Data (DAT): Writing to DAT stores the command in a register (Bits 31:0)
                                 // FIFO_A & B: First in first out port for sd card. CPU can fill FIFO before a write to card, or drain FIFO after a read from card  
    reg [31:0] i_wb_data    = 0; // 32 bit read line 
    reg [3:0] i_wb_sel      = 4'hF; // Part of WB B4. Tells slave if they should do a half byte operation instead (we dont care about this)
    
    wire o_wb_stall; // Signal back to master that slave is not ready for next transaction. Recall WB B4 is pipelined to send rapid amount of data without ack. This tells master to stop.
    wire o_wb_ack; // ack finished transfer
    wire [31:0] o_wb_data; // 32 bit write line 
    
    // SD card SPI pins
    wire o_cs_n; // active low (n) chip select. While low, slave actively listens to clock (sck) and MOSI lines while sending data on MISO line every clk cycle. Essentially an enable.
    wire o_sck; // SPI clk
    wire o_mosi; // Master out slave in
    reg i_miso          = 1'b1; // Master in slave out. SD card returns 1's when idle
    reg i_card_detect   = 1'b0;  // Assume the card is plugged in
    
    // Misc
    wire o_int; // interrupt so CPU knows when SD operation is done
    reg i_bus_grant = 1'b1; // SDSPI core uses this to know when it is allowed to "own" the interal bus.
    wire [31:0] o_debug; // BC SDSPI had it. Don't know what it does. Prob just debug info
    
    // Instantiate SDSPI
    sdspi dut (
        .i_clk        (i_clk), 
        .i_sd_reset   (i_sd_reset),

        .i_wb_cyc     (i_wb_cyc),
        .i_wb_stb     (i_wb_stb),
        .i_wb_we      (i_wb_we),
        .i_wb_addr    (i_wb_addr),
        .i_wb_data    (i_wb_data),
        .i_wb_sel     (i_wb_sel),
        .o_wb_stall   (o_wb_stall),
        .o_wb_ack     (o_wb_ack),
        .o_wb_data    (o_wb_data),

        .o_cs_n       (o_cs_n),
        .o_sck        (o_sck),
        .o_mosi       (o_mosi),
        .i_miso       (i_miso),
        .i_card_detect(i_card_detect),

        .o_int        (o_int),
        .i_bus_grant  (i_bus_grant),
        .o_debug      (o_debug)
    );
    
    ////////////////////////////
    // Wishbone helpers. Note the SD module is WB B4 compatable 
    ////////////////////////////

    // Write to WB
    task wb_write(input [1:0] addr, input [31:0] data);
    begin
        @(posedge i_clk);
        i_wb_addr <= addr;
        i_wb_data <= data;
        i_wb_we   <= 1'b1;
        i_wb_cyc  <= 1'b1;
        i_wb_stb  <= 1'b1;
        i_wb_sel  <= 4'hF;

        // Wait for ack
        @(posedge i_clk);
        while (!o_wb_ack) begin
            @(posedge i_clk);
        end

        // bring signals back low
        i_wb_cyc  <= 1'b0;
        i_wb_stb  <= 1'b0;
        i_wb_we   <= 1'b0;
    end
    endtask
    
    // Read from WB
    task wb_read(input [1:0] addr, output [31:0] data);
    begin
        @(posedge i_clk);
        i_wb_addr <= addr;
        i_wb_we   <= 1'b0;
        i_wb_cyc  <= 1'b1;
        i_wb_stb  <= 1'b1;
        i_wb_sel  <= 4'hF;

        // Wait for ack
        @(posedge i_clk);
        while (!o_wb_ack) begin
            @(posedge i_clk);
        end

        data = o_wb_data;

        // bring signals back low
        i_wb_cyc  <= 1'b0;
        i_wb_stb  <= 1'b0;
    end
    endtask
    
    ////////////////////////////
    // Begin Test
    ////////////////////////////
    initial begin
        
        // Flip and hold reset to set SD card to initial state
        i_sd_reset = 1'b1;
        repeat (5) @(posedge i_clk);
        i_sd_reset = 1'b0;

        // Wait for anything startup clocks
        repeat (10) @(posedge i_clk);

        // Write to CMD to reset pointer
        wb_write(2'b00, 32'h0000_0000);

        // Write to DAT 
        wb_write(2'b01, 32'h0000_1111);

        // Let it run for a while to see SPI activity
        repeat (10) @(posedge i_clk);
        
        // Write a different value
        wb_write(2'b01, 32'h1111_1111);
        repeat (10) @(posedge i_clk);
        
        // Reset FIFO
        wb_write(2'b00, 32'h0000_0000);
        repeat (10) @(posedge i_clk);

        $finish;
    end

    

endmodule