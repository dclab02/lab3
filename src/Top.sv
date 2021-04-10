module Top (
	input i_rst_n,
	input i_clk,
	input i_key_0,  // Record/Pause
	input i_key_1,  // Play/Pause
	input i_key_2,  // Stop
	// input [3:0] i_speed, // design how user can decide mode on your own
	
	// AudDSP and SRAM
	output [19:0] o_SRAM_ADDR,
	inout  [15:0] io_SRAM_DQ,
	output        o_SRAM_WE_N,
	output        o_SRAM_CE_N,
	output        o_SRAM_OE_N,
	output        o_SRAM_LB_N,
	output        o_SRAM_UB_N,
	
	// I2C
	input  i_clk_100k,
	output o_I2C_SCLK,
	inout  io_I2C_SDAT,
	
	// AudPlayer
	input  i_AUD_ADCDAT,
	inout  i_AUD_ADCLRCK,
	inout  i_AUD_BCLK,
	inout  i_AUD_DACLRCK,
	output o_AUD_DACDAT,

	// SEVENDECODER (optional display)
	output [5:0] o_record_time,
	output [5:0] o_play_time,
	output [5:0] o_state,
	
	// functional select switch
	input i_switch_0, // slow_0
	input i_switch_1, // slow_1
	input i_switch_2, // fast
	input i_switch_3, // bit[0]
	input i_switch_4, // bit[1]
	input i_switch_5, // bit[2]

	// LCD (optional display)
	input        i_clk_800k,
	inout  [7:0] o_LCD_DATA,
	output       o_LCD_EN,
	output       o_LCD_RS,
	output       o_LCD_RW,
	output       o_LCD_ON,
	output       o_LCD_BLON

	// LED
	// output  [7:0] o_ledg
	// output [17:0] o_ledr
);

// design the FSM and states as you like
localparam S_I2C_INIT   = 0;
localparam S_IDLE       = 1;
localparam S_RECD       = 2;
localparam S_RECD_PAUSE = 3;
localparam S_PLAY       = 4;
localparam S_PLAY_PAUSE = 5;

logic [2:0] state_r, state_w;
logic i2c_oen;
wire i2c_sdat;
logic [19:0] addr_record, play_addr;
logic [15:0] data_record, play_data, dac_data;

logic i2c_init, i2c_init_stat;
logic recd_start, recd_pause, recd_stop;

//relate to DSP module
logic play_fast, play_slow_0, play_slow_1, play_pause, play_start, play_stop;
logic [2:0] play_speed;
logic [19:0] end_addr_r, end_addr_w;
logic playing;

assign io_I2C_SDAT = (i2c_oen) ? i2c_sdat : 1'bz;

assign o_SRAM_ADDR = (state_r == S_RECD) ? addr_record : play_addr;
assign io_SRAM_DQ  = (state_r == S_RECD) ? data_record : 16'dz; // sram_dq as output
assign play_data   = (state_r != S_RECD) ? io_SRAM_DQ : 16'd0; // sram_dq as input

// assign o_ledg = dac_data[7:0]; // [DEBUG] This is for testing

assign o_SRAM_WE_N = (state_r == S_RECD) ? 1'b0 : 1'b1;
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;

// relate to DSP module
assign play_slow_0 	= i_switch_0;
assign play_slow_1 	= i_switch_1;
assign play_fast	= i_switch_2;
assign play_speed 	= {i_switch_5, i_switch_4, i_switch_3};

assign playing     = (state_r == S_PLAY) ? 1'b1 : 1'b0;
assign recd_pause  = (state_r == S_RECD_PAUSE) ? 1'b1 : 1'b0;
assign recd_stop   = (state_r == S_IDLE) ? 1'b1 : 1'b0;
assign play_pause  = (state_r == S_PLAY_PAUSE) ? 1'b1 : 1'b0;
assign play_stop   = (state_r == S_IDLE) ? 1'b1 : 1'b0;

// hex display
// timer
logic [5:0] recd_sec_r, recd_sec_w;
logic [23:0] recd_counter_r, recd_counter_w;
assign o_record_time = recd_sec_r;
assign o_play_time =  { 1'b0, play_addr[19:15] }; // to adjust with quick and slow play, so set by play_addr
// state
assign o_state = state_r;


// === I2cInitializer ===
// sequentially sent out settings to initialize WM8731 with I2C protocal

logic [1:0] i2c_state;
I2CInitializer init0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk_100k),
	.i_start(i2c_init),
	.o_finished(i2c_init_stat),
	.o_sclk(o_I2C_SCLK),
	.o_sdat(i2c_sdat),
	.o_oen(i2c_oen),// you are outputing (you are not outputing only when you are "ack"ing.)
	.o_state(i2c_state)
);

// === AudDSP ===
// responsible for DSP operations including fast play and slow play at different speed
// in other words, determine which data addr to be fetch for player 
AudDSP dsp0(
	.i_rst_n(i_rst_n),
	.i_clk(i_AUD_BCLK),
	.i_start(play_start),
	.i_pause(play_pause),
	.i_stop(play_stop),
	.i_speed(play_speed),
	.i_fast(play_fast),
	.i_slow_0(play_slow_0), // constant interpolation
	.i_slow_1(play_slow_1), // linear interpolation
	.i_daclrck(i_AUD_DACLRCK),
	.i_sram_data(play_data),
	.i_end_addr(end_addr_w),
	.o_dac_data(dac_data),
	.o_sram_addr(play_addr)
);

// [DEBUG]
// logic [15:0] dac_data_tmp;
// assign dac_data_tmp = {play_addr[16],15'b0};

// === AudPlayer ===
// receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
AudPlayer player0(
	.i_rst_n(i_rst_n),
	.i_bclk(i_AUD_BCLK),
	.i_daclrck(i_AUD_DACLRCK),
	.i_en(playing), // enable AudPlayer only when playing audio, work with AudDSP
	.i_dac_data(dac_data), //dac_data
	.o_aud_dacdat(o_AUD_DACDAT)
);

// === AudRecorder ===
// receive data from WM8731 with I2S protocal and save to SRAM
AudRecorder recorder0(
	.i_rst_n(i_rst_n), 
	.i_clk(i_AUD_BCLK),
	.i_lrc(i_AUD_ADCLRCK),
	.i_start(recd_start),
	.i_pause(recd_pause),
	.i_stop(recd_stop),
	.i_data(i_AUD_ADCDAT),
	.o_address(addr_record),
	.o_data(data_record)
);

// === AudLCD ===
// LCD display
AudLCD disp0(
	.i_rst_n(i_rst_n),
    .i_clk(i_clk_800k),
    .i_state(state_r),
    .i_speed(play_speed),
    .i_fast(),
	.i_interpolation(),

    .o_LCD_DATA(o_LCD_DATA),
    .o_LCD_EN(o_LCD_EN),
    .o_LCD_RS(o_LCD_RS),
    .o_LCD_RW(o_LCD_RW),
    .o_LCD_ON(o_LCD_ON),
    .o_LCD_BLON(o_LCD_BLON)
);

always_comb begin
	state_w = state_r;
	end_addr_w = end_addr_r;
	recd_counter_w = recd_counter_r;
	recd_sec_w = recd_sec_r;
	recd_start = 0;
	play_start = 0;
	i2c_init = 0;

	case (state_r)
		S_I2C_INIT: begin
			i2c_init = 1'b1;
			if (i2c_init_stat) begin // init done
				i2c_init = 1'b0;
				state_w = S_IDLE;
			end
		end
		S_IDLE: begin		
			recd_sec_w = 6'b0;
			if (i_key_0) begin // start recording
				recd_start = 1;
				state_w = S_RECD;
			end
			if (i_key_1) begin // start playing
				play_start = 1;
				state_w = S_PLAY;
			end
		end
		S_RECD: begin
			recd_counter_w = recd_counter_r + 24'b1;
			if (recd_counter_r == 24'd12000000) begin
				recd_counter_w = 24'b0;
				recd_sec_w = recd_sec_r + 6'b1;
			end

			if (i_key_0) begin
				state_w = S_RECD_PAUSE;
			end
			else if (i_key_2 || addr_record == 20'b11111111111111111111) begin
				state_w = S_IDLE;
				end_addr_w = addr_record;
			end
		end
		S_RECD_PAUSE: begin
			if (i_key_0) begin
				state_w = S_RECD;
				recd_start = 1;
			end
			else if (i_key_2) begin
				end_addr_w = addr_record;
				state_w = S_IDLE;
			end
		end
		S_PLAY: begin
			if (i_key_1) begin
				state_w = S_PLAY_PAUSE;
			end
			else if (i_key_2) begin
				state_w = S_IDLE;
			end
			else if(play_addr >= end_addr_r) begin
				state_w = S_IDLE;
			end
		end
		S_PLAY_PAUSE: begin
			if (i_key_1) begin
				state_w = S_PLAY;
				play_start = 1;
			end
			else if (i_key_2) begin
				state_w = S_IDLE; 
			end
		end

		default: 
		state_w = state_r;
	endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
        state_r <= S_I2C_INIT;
		end_addr_r <= 0;
		recd_sec_r <= 0;
		recd_counter_r <= 0;
	end
	else begin
        state_r <= state_w;
		end_addr_r <= end_addr_w;
		recd_sec_r <= recd_sec_w;
		recd_counter_r <= recd_counter_w;
	end
end

endmodule