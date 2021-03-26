module AudRecorder (
	input   i_rst_n, 
	input   i_clk,
	input   i_lrc,
	input   i_start,
	input   i_pause,
	input   i_stop,
	input   i_data,
	output  o_address,
	output  o_data
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