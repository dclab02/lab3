`timescale 1ns/10ps

module tb;
    // address and rw
    localparam End_Address = 20'd8; // wm8731 address
    // reg and data

	localparam CLK = 10;
	localparam HCLK = CLK/2;

    localparam DACLRCK = 160;
	localparam BIG_HCLK = DACLRCK/2;
    
    logic rst, clk, start, pause, stop, daclrck, fast, slow_0, slow_1;
    logic [2:0] speed;
    logic [15:0] data;
    logic [15:0] out_data;
    logic [15:0] sram_data [0:7];
    logic [19:0] addr;
    logic [19:0] next_addr;
    logic [19:0] end_addr = End_Address;
    
	initial clk = 0;
    initial daclrck = 0;
	always #HCLK clk = ~clk;
    always #BIG_HCLK daclrck = ~daclrck;

    AudDSP dsp0(
        .i_rst_n        (rst),
        .i_clk          (clk),
        .i_start        (start),
        .i_pause        (pause),
        .i_stop         (stop),
        .i_speed        (speed),
        .i_fast         (fast),
        .i_slow_0       (slow_0), // constant interpolation
        .i_slow_1       (slow_1), // linear interpolation
        .i_daclrck      (daclrck),
        .i_sram_data    (data),
        .i_end_addr     (end_addr),
        .o_dac_data     (out_data),
        .o_sram_addr    (next_addr)
    );

	initial begin
        for (int i = 0; i < 8; i = i + 1) begin
            sram_data[i] = i * 4;
        end
    end
    initial begin        
        $fsdbDumpfile("dsp.fsdb");
		$fsdbDumpvars;
        $display("reset dsp ...");
        start = 0;
        pause = 0;
        stop = 0;
        speed = 0;
        fast = 0;
        slow_0 = 0;
        slow_1 = 0;
        rst = 1;
        data = sram_data[0];
		#(2*CLK)
		rst = 0;
        #(CLK)
        rst = 1;
        start = 1;
        #(CLK)
        start = 0;
        for (int i = 0; i < 8; i = i + 1) begin
            data = sram_data[i];
            $display("=========");
			$display("data[%d] = %2d ", i, data);
			$display("=========");
			@(posedge daclrck)
			$display("=========");
			$display("out_data = %2d", out_data);
            $display("next_addr = %2d", next_addr);
			$display("=========");
		end
	end

    initial begin
		#(500000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

endmodule
