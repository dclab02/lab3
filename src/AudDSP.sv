module AudDSP (
	input   i_rst_n,
	input   i_clk,
	input   i_start,
	input   i_pause,
	input   i_stop,
	input   i_speed,
	input   i_fast,
	input   i_slow_0, // constant interpolation
	input   i_slow_1, // linear interpolation
	input   i_daclrck,
	input   i_sram_data,
	output  o_dac_data,
	output  o_sram_addr
);

always_comb begin
	// design your control here
end

always_ff @(posedge i_clk or posedge i_rst_n) begin
	// design your control here
    if (!i_rst_n) begin
		
	end
	else begin
		
	end
end
endmodule