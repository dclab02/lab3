`timescale 1ns/10ps

module tb;

	localparam CLK = 10;
	localparam HCLK = CLK/2;

    logic clk, rst;
    logic o_LCD_DATA;
    logic o_LCD_EN;
    logic o_LCD_RS;
    logic o_LCD_RW;
    logic o_LCD_ON;
    logic o_LCD_BLON;

    initial clk = 0;
	always #HCLK clk = ~clk;

    LCD lcd0(
        .i_rst_n(rst),
        .i_clk(clk),

        .i_clr(),
        .i_col(),
        .i_row(),

        .o_DATA(o_LCD_DATA),
        .o_EN(o_LCD_EN),
        .o_RS(o_LCD_RS),
        .o_RW(o_LCD_RW),
        .o_ON(o_LCD_ON),
        .o_BLON(o_LCD_BLON)
    );


    initial begin
        $fsdbDumpfile("LCD.fsdb");
		$fsdbDumpvars;
        $display("reset...");
        rst = 1;
		#(2*CLK)
		rst = 0;
		#(2*CLK)
        rst=1;
        #(50*CLK)

        $finish;

    end

    initial begin
		#(5000000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

endmodule
