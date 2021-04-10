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

logic [1:0] state_r, state_w;
logic [15:0] aud_data_r, aud_data_w;
logic [3:0] data_cnt_r, data_cnt_w;
logic lrc_r, lrc_w;

assign o_aud_dacdat = aud_data_r[15];

always_comb begin
	state_w = state_r;
	aud_data_w = aud_data_r;
	data_cnt_w = data_cnt_r;
	lrc_w = i_daclrck;

	case (state_r)
		S_IDLE: begin
			if (i_en && (lrc_w != lrc_r)) begin
				aud_data_w = i_dac_data;
				state_w = S_PLAYING;
			end 
		end

		S_PLAYING: begin
			aud_data_w = aud_data_r << 1;
			data_cnt_w = data_cnt_r + 1'b1;
			if (data_cnt_r == 15) begin
				data_cnt_w = 4'b0;
				state_w = S_IDLE;
			end
		end
	endcase
end

always_ff @(negedge i_bclk or negedge i_rst_n) begin
    if (!i_rst_n) begin
		state_r <= S_IDLE;
		data_cnt_r <= 3'b0;
		aud_data_r <= 16'b0;
		lrc_r <= 1'b0;
	end
	else begin
		state_r <= state_w;
		aud_data_r <= aud_data_w;
		data_cnt_r <= data_cnt_w;
		lrc_r <= lrc_w;
	end
end
endmodule