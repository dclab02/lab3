`timescale 1ns/10ps

module tb;
    // address and rw
    localparam Address = 7'b0011010; // wm8731 address
    localparam RW = 1'b0; // i2c writing (0)
    // reg and data
    localparam Reset = 16'b0001111000000000;
    localparam Analogue_Audio_Path_Control = 16'b0000100000010101;
    localparam Digital_Audio_Path_Control = 16'b0000101000000000;
    localparam Power_Down_Control = 16'b0000110000000000;
    localparam Digital_Audio_Interface_Format = 16'b0000111001000010;
    localparam Sampling_Control = 16'b0001000000011001;
    localparam Active_Control = 16'b0001001000000001;

	localparam CLK = 10;
	localparam HCLK = CLK/2;

    logic rst, clk, start, fin, sclk, oen;
    logic rw = RW;
    logic [6:0] addr = Address;
    logic [15:0] reg_data = Analogue_Audio_Path_Control;

    wire sdat;

	initial clk = 0;
	always #HCLK clk = ~clk;


    I2C i2c(
        .i_rst_n(rst),
        .i_clk(clk),      
        .i_start(start),    // control if start
        .i_addr(addr),      // chip address (7 bit)
        .i_rw(rw),          // chip R/W (1'b0 | 1'b1)
        .i_reg_data(reg_data), // chip reg and data (7 + 9 bit)

        .o_finished(fin),
        .o_sclk(sclk),      // s clock for i2c
        .o_sdat(sdat),      // data in / out
        .o_oen(oen)         // you are outputing (you are not outputing only when you are "ack"ing.)
    );

	initial begin
        $fsdbDumpfile("i2c.fsdb");
		$fsdbDumpvars;
        $display("reset i2c ...");
        rst = 1;
		#(2*CLK)
		rst = 0;
		#(2*CLK)
        $display("start i2c ...");
        rst=1;
        start = 1;
        #CLK
        start = 0;
        @(posedge fin)
        $display("finish i2c");
		#(2*CLK)
        $finish;
	end

    initial begin
		#(5000000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

endmodule
