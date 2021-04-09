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
localparam S_RECORDING = 1;
localparam S_PAUSE     = 2;
localparam S_FINISHED  = 3;
localparam S_STOP      = 4;

logic [2:0] state_r, state_w;
logic [3:0] data_cnt_r, data_cnt_w;
logic [15:0] audio_data;
logic [19:0] audio_addr_r, audio_addr_w;
logic lrc_r, lrc_w;
logic finished;
// logic start, stop;
logic recording;

assign o_address = audio_addr_r; 
assign o_data = audio_data;
assign o_finished = finished;

always_comb begin
	state_w = state_r;
	lrc_w = lrc_r;
	audio_addr_w = audio_addr_r;
	data_cnt_w = data_cnt_r;

	case (state_r)
		S_IDLE: begin
			audio_data = 16'b0;
			finished = 1'b0;
			recording = 1'b0;

			if (i_start)
				recording = 1'b1;
			if (recording && i_lrc == 0)
				state_w = S_RECORDING;
		end 
		S_RECORDING: begin
			if (i_pause) begin
				state_w = S_PAUSE;
			end
			if (i_stop) begin
				recording = 1'b0;
			end
			if (data_cnt_r == 15) begin
				state_w = S_FINISHED;
			end
			audio_data[0] = i_data;
			audio_data = audio_data << 1;
			data_cnt_w = data_cnt_r + 1'b1;
		end
		S_PAUSE: begin
			if (i_pause) begin
				state_w = S_RECORDING;
			end
		
		end
		S_FINISHED: begin
			audio_addr_w = audio_addr_r + 1'b1;
			data_cnt_w = 3'b0;
			finished = 1'b1;
			if (!recording)
				state_w = S_STOP;
			else
				state_w = S_IDLE;
		end
		S_STOP: begin
			audio_addr_w = 1'b1;
			// stop = 1'b0;
			state_w = S_IDLE;
		end
		// default: 
	endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	// design your control here
    if (!i_rst_n) begin
		state_r <= S_IDLE;
		data_cnt_r <= 3'b0;
		audio_addr_r <= 20'b0;
		lrc_r <= 1'b0;
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
	end
end
endmodule