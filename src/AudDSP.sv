// TODO:
// 1. ensure if i need to send finish playing...
// 
module AudDSP (
	input   i_rst_n,
	input   i_clk,
	input   i_start,
	input   i_pause,
	input   i_stop,
	input   [2:0] i_speed,
	input   i_fast,
	input   i_slow_0, // constant interpolation
	input   i_slow_1, // linear interpolation
	input   i_daclrck,
	input   [15:0] i_sram_data,
	input	[15:0] i_end_addr, // end address
	output  [15:0] o_dac_data,
	output  [19:0] o_sram_addr
);

localparam S_IDLE 	= 0;
localparam S_RUN 	= 1;
localparam S_WAIT_0 = 2;
localparam S_WAIT_1 = 3;
localparam S_PAUSE	= 4;

logic state_r, state_w;
logic [2:0] interpolation_counter_r, interpolation_counter_w;
logic signed [15:0] out_dac_data;
logic signed [15:0] pre_dac_data_r, pre_dac_data_w;
logic signed [15:0] dac_data_r, dac_data_w;
logic [19:0] addr_counter_r, addr_counter_w;
logic interpolation_finish_r, interpolation_finish_w;

assign o_sram_addr = addr_counter_r;
assign o_dac_data = out_dac_data;

always_comb begin
	// design your control here
	addr_counter_w			= addr_counter_r;
	interpolation_counter_w = interpolation_counter_r;
	dac_data_w				= dac_data_r;
	pre_dac_data_w			= pre_dac_data_r;
	out_dac_data			= 16'b0;

	case (state_r)
		S_IDLE: begin
			addr_counter_w = 20'b0;
			interpolation_counter_w = 3'b0;
			out_dac_data = 16'b0;
			if (i_slow_0 | i_slow_1) begin
				interpolation_finish_w = 1'b0;
			end
			else begin
				interpolation_finish_w = 1'b1;
			end
			if (i_start) begin
				state_w = S_RUN;
				addr_counter_w =  addr_counter_r + {17'b0, i_speed};
				dac_data_w = i_sram_data;
			end
		end
		S_RUN: begin
			out_dac_data = dac_data_r;
			dac_data_w = i_sram_data;
			pre_dac_data_w = dac_data_r;
			addr_counter_w = addr_counter_r + {17'b0, i_speed};
			if (addr_counter_r == i_end_addr) begin
				state_w = S_IDLE;
			end
			else if (i_pause) begin
				state_w = S_PAUSE;
			end
			else if (i_stop) begin
				state_w = S_IDLE;
			end
			else begin
				if (i_slow_0) begin
					state_w = S_WAIT_0;
					interpolation_finish_w = 1'b0;
				end
				else if (i_slow_1) begin
					state_w = S_WAIT_1;
					interpolation_finish_w = 1'b0;
				end	
			end
		end
		S_WAIT_0: begin
			interpolation_counter_w = interpolation_counter_r + 3'd1;
			out_dac_data = pre_dac_data_r;
			if (i_stop) begin
				state_w = S_IDLE;
			end
			if (i_pause) begin
				state_w = S_PAUSE;
			end
			else begin
				if (interpolation_counter_r == (i_speed - 3'd1)) begin
					interpolation_counter_w <= 3'b0;
					interpolation_finish_w <= 1'b1;
					state_w = S_RUN;
				end
			end
		end
		S_WAIT_1: begin
			interpolation_counter_w = interpolation_counter_r + 3'd1;
			out_dac_data = (dac_data_r - pre_dac_data_r) * {17'b0, interpolation_counter_r} / ({17'b0, i_speed} + 20'd1);
			if (i_stop) begin
				state_w = S_IDLE;
			end
			if (i_pause) begin
				state_w = S_PAUSE;
			end
			else
				if (interpolation_counter_r == (i_speed - 3'd1)) begin
					interpolation_counter_w <= 3'b0;
					interpolation_finish_w <= 1'b1;
					state_w = S_RUN;
				end
		end
		S_PAUSE: begin
			out_dac_data = 16'b0;
			if (i_stop) begin
				state_w = S_IDLE;
			end
			else if (i_start) begin
				if ((~interpolation_finish_r) & i_slow_0) begin
					state_w = S_WAIT_0;
				end
				else if ((~interpolation_finish_r) & i_slow_1) begin
					state_w = S_WAIT_1;
				end
				else begin
					state_w = S_RUN;
				end
			end
		end
	endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	// design your control here
    if (!i_rst_n) begin
		dac_data_r <= 16'b0;
		state_r <= S_IDLE;
	end
	else begin
		dac_data_r <= dac_data_w;
		state_r <= state_w;
	end
end

always_ff @(negedge i_daclrck or negedge i_rst_n) begin
	if (!i_rst_n) begin
		interpolation_counter_r <= 3'b0;
		pre_dac_data_r <= 16'b0;
		addr_counter_r <= 20'b0;
	end
	else begin
		interpolation_counter_r <= interpolation_counter_w;
		pre_dac_data_r <= pre_dac_data_w;
		addr_counter_r <= addr_counter_w;
	end
end

endmodule