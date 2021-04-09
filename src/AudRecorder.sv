module AudRecorder (
	input   i_rst_n, 
	input   i_clk, // BCLK of WM8731
	input   i_lrc,

	input   i_start,
	input   i_pause,
	input   i_stop,

	input   i_data,
	output  o_finished,
	output  [19:0] o_address,
	output  [15:0] o_data
);

localparam S_IDLE      = 0;
localparam S_START     = 1;
localparam S_RECORDING = 2;
localparam S_FINISHED  = 3;
// localparam S_PAUSE     = 3;
// localparam S_STOP      = 5;

logic [1:0] state_r, state_w;
logic [3:0] data_cnt_r, data_cnt_w;
logic [15:0] aud_data_r, aud_data_w;
logic [19:0] audio_addr_r, audio_addr_w;
logic lrc_r, lrc_w;
logic finish_r, finish_w;
// logic recording_r, recording_w;
logic pause_flag, stop_flag, recording;

assign o_address = audio_addr_r; 
assign o_data = aud_data_r;
assign o_finished = finish_r;

always_comb begin
	state_w = state_r;
	lrc_w = lrc_r;
	audio_addr_w = audio_addr_r;
	data_cnt_w = data_cnt_r;
	aud_data_w = aud_data_r;
	finish_w = finish_r;
	pause_flag = 0;
	stop_flag = 0;
	recording = 0;

	case (state_r)
		S_IDLE: begin
			finish_w = 1'b0;
			pause_flag = 1'b0;
			stop_flag = 1'b0;

			lrc_w = i_lrc;

			if (i_pause) begin
				recording = 1'b0;
			end
			if (i_stop) begin
				audio_addr_w = 1'b0;
				recording = 1'b0;
			end

			// once pause or stop, require "start" to restart
			if (i_start) begin
				recording = 1'b1;
				// state_w = S_START;
			end
			// if (recording && i_lrc == 0) begin
			if (recording && lrc_r && !lrc_w) begin
				aud_data_w = 16'b0;
				state_w = S_RECORDING;
				// aud_data_w[0] = i_data;
			end
		end
		S_RECORDING: begin
			if (i_pause) begin
				pause_flag = 1'b1;
			end
			if (i_stop) begin
				stop_flag = 1'b1;
			end
			if (data_cnt_r == 15) begin
				state_w = S_FINISHED;
				// recording_w = 1'b0;
			end
			else begin
				aud_data_w = aud_data_r << 1;
				aud_data_w[0] = i_data;
				data_cnt_w = data_cnt_r + 1'b1;
			end
		end		
		S_FINISHED: begin
			audio_addr_w = audio_addr_r + 1'b1;
			data_cnt_w = 4'b0;
			// aud_data_w = 16'b0; // reset audio data
			finish_w = 1'b1;
			state_w = S_IDLE;

			if (pause_flag) begin
				recording = 1'b0;
			end
			if (stop_flag) begin
				audio_addr_w = 1'b0;
				recording = 1'b0;
			end
			// if (!recording_r)
			// 	state_w = S_STOP;
			// else
			// 	state_w = S_START;
		end
	endcase
end

// always_ff @( negedge i_lrc) begin
	
// end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	// design your control here
    if (!i_rst_n) begin
		state_r <= S_IDLE;
		data_cnt_r <= 3'b0;
		audio_addr_r <= 20'b0;
		aud_data_r <= 16'b0;
		lrc_r <= 1'b0;
		// recording_r <= 1'b0;
		finish_r <= 1'b0;
		// audio_data <= 16'b0;
		// finished <= 1'b0;
		// start <= 1'b0;
		// stop <= 1'b0;
		// recording <= 1'b0;
	end
	else begin
		state_r <= state_w;
		data_cnt_r = data_cnt_w;
		lrc_r <= lrc_w;
		audio_addr_r <= audio_addr_w;
		aud_data_r <= aud_data_w;
		// recording_r <= recording_w;
		finish_r <= finish_w;
	end
end
endmodule