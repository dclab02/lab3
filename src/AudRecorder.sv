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
localparam S_WAITING   = 1;
localparam S_RECORDING = 2;
localparam S_FINISHED  = 3;

logic [1:0] state_r, state_w;
logic [3:0] data_cnt_r, data_cnt_w;
logic [15:0] aud_data_r, aud_data_w;
logic [19:0] audio_addr_r, audio_addr_w;
logic lrc_r, lrc_w;
logic finish_r, finish_w;

assign o_address = audio_addr_r; 
assign o_data = aud_data_r;
assign o_finished = finish_r;

always_comb begin
	state_w = state_r;
	lrc_w = i_lrc;
	audio_addr_w = audio_addr_r;
	data_cnt_w = data_cnt_r;
	aud_data_w = aud_data_r;
	finish_w = finish_r;

	case (state_r)
		S_IDLE: begin
			finish_w = 1'b0;
			if (i_stop) begin
				audio_addr_w = 1'b0;
			end

			// once pause or stop, require "start" to restart
			if (i_start) begin
				state_w = S_WAITING;
			end
		end

		S_WAITING: begin
			finish_w = 1'b0;
			if (lrc_r && !lrc_w) begin
				aud_data_w = 16'b0;
				state_w = S_RECORDING;
			end
		end

		S_RECORDING: begin
			aud_data_w = aud_data_r << 1;
			aud_data_w[0] = i_data;
			// aud_data_w[0] = data_cnt_r[0]; // [DEBUG] This is for testing
			data_cnt_w = data_cnt_r + 1'b1;
			if (data_cnt_r == 15) begin
				state_w = S_FINISHED;
			end
		end		
		S_FINISHED: begin
			audio_addr_w = audio_addr_r + 1'b1;
			data_cnt_w = 4'b0;
			// aud_data_w = 16'b0; // reset audio data
			finish_w = 1'b1;
			state_w = S_WAITING;

			if (i_pause) begin
				state_w = S_IDLE;
			end
			if (i_stop) begin
				audio_addr_w = 1'b0;
				state_w = S_IDLE;
			end
		end
	endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
		state_r <= S_IDLE;
		data_cnt_r <= 3'b0;
		audio_addr_r <= 20'b0;
		aud_data_r <= 16'b0;
		lrc_r <= 1'b0;
		finish_r <= 1'b0;
	end
	else begin
		state_r <= state_w;
		data_cnt_r = data_cnt_w;
		lrc_r <= lrc_w;
		audio_addr_r <= audio_addr_w;
		aud_data_r <= aud_data_w;
		finish_r <= finish_w;
	end
end
endmodule