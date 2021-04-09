module AudPlayer (
	input   i_rst_n,
	input   i_bclk,
	input   i_daclrck,
	input   i_en, // enable AudPlayer only when playing audio, work with AudDSP
	input   [15:0] i_dac_data, //dac_data
	output  o_aud_dacdat
);

localparam S_IDLE      = 0;
localparam S_PLAYING   = 1;
localparam S_FINISHED  = 2;

logic [1:0] state_r, state_w;
logic [15:0] aud_data_r, aud_data_w;
logic [2:0] data_cnt_r, data_cnt_w;
// logic playing;
logic lrc_r, lrc_w;

assign o_aud_dacdat = aud_data_r[15];

always_comb begin
	state_w = state_r;
	aud_data_w = aud_data_r;
	data_cnt_w = data_cnt_r;
	// aud_data_r = 16'b0;
	case (state_r)
		S_IDLE: begin
			if (i_en && !i_daclrck) begin
				// playing = 1'b1;
				aud_data_w = i_dac_data;
				state_w = S_PLAYING;
			end 
		end
		S_PLAYING: begin
			if (data_cnt_r == 15) begin
				data_cnt_w = 3'b0;
				// playing = 1'b0;
				state_w = S_IDLE;
			end
			else begin
				aud_data_w = aud_data_r << 1;
				data_cnt_w = data_cnt_r + 1'b1;
			end
		end
		// default: 
	endcase
end

always_ff @(posedge i_bclk or negedge i_rst_n) begin
	// design your control here
    if (!i_rst_n) begin
		state_r <= S_IDLE;
		data_cnt_r <= 3'b0;
		aud_data_r <= 16'b0;
		// audio_data <= 16'b0;
	end
	else begin
		state_r <= state_w;
		aud_data_r <= aud_data_w;
		data_cnt_r <= data_cnt_w;
	end
end
endmodule