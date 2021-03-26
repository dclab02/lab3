module AudPlayer (
	input   i_rst_n,
	input   i_bclk,
	input   i_daclrck,
	input   i_en, // enable AudPlayer only when playing audio, work with AudDSP
	input   i_dac_data, //dac_data
	output  o_aud_dacdat
);


always_comb begin
	// design your control here
end

always_ff @(posedge i_bclk or posedge i_rst_n) begin
	// design your control here
    if (!i_rst_n) begin
		
	end
	else begin
		
	end
end
endmodule