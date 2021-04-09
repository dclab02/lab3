`timescale 1ns/10ps

module tb;
    // address and rw
    localparam audio_dat = 16'b1010101010101010; // test data
    // reg and data


	localparam CLK = 10;
	localparam HCLK = CLK/2;

    logic rst, clk, start, pause, stop, fin;
    logic i_AUD_ADCLRCK = 1'b1;
    logic i_AUD_ADCDAT;
    logic [19:0] addr;
    logic [15:0] data_record;

	initial clk = 0;
	always #HCLK clk = ~clk;

    AudRecorder recorder0(
        .i_rst_n(rst), 
        .i_clk(clk),
        .i_lrc(i_AUD_ADCLRCK),
        .i_start(start),
        .i_pause(pause),
        .i_stop(stop),
        .i_data(i_AUD_ADCDAT),
        .o_finished(fin),
        .o_address(addr),
        .o_data(data_record)
    );

	initial begin
        $fsdbDumpfile("audRec.fsdb");
		$fsdbDumpvars;
        $display("reset...");
        rst = 1;
		#(2*CLK)
		rst = 0;
		#(2*CLK)
        rst=1;

        $display("start...");
        start = 1;
        #(5*CLK)
        i_AUD_ADCLRCK = 1'b1;
        #(5*CLK)
        for (int i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            i_AUD_ADCDAT = audio_dat[i];
        end
        #(5*CLK)
        i_AUD_ADCLRCK = 1'b0;

        @(posedge fin)
        $display("finish");
        $finish;
	end

    initial begin
		#(5000000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

endmodule
