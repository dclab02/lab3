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
	input	[19:0] i_end_addr, // end address
	output  [15:0] o_dac_data,
	output  [19:0] o_sram_addr,
	output [2:0]   o_state  // [debug]
);


localparam S_IDLE 	= 3'd0;
localparam S_RUN 	= 3'd1;
localparam S_WAIT_0 = 3'd2;
localparam S_WAIT_1 = 3'd3;
localparam S_PAUSE	= 3'd4;
localparam S_WAIT_NEGEDGE = 3'd5;


logic [2:0] state_r, state_w;
logic [3:0] interpolation_counter_r, interpolation_counter_w;
logic signed [15:0] out_dac_data;
logic signed [15:0] pre_dac_data_r, pre_dac_data_w, pre_dac_data_tmp;
logic signed [15:0] dac_data_r, dac_data_w;
logic [19:0] addr_counter_r, addr_counter_w, addr_counter_out;
logic interpolation_finish_r, interpolation_finish_w;
logic daclrck_negedge, daclrck_dly;

assign o_sram_addr = addr_counter_out;
assign o_dac_data = out_dac_data;
assign daclrck_negedge = ~i_daclrck & daclrck_dly;

// [debug]
assign o_state = state_r;

always_comb begin
	// design your control here
	state_w					= state_r;
	addr_counter_w			= addr_counter_r;
	interpolation_counter_w = interpolation_counter_r;
	dac_data_w				= dac_data_r;
	pre_dac_data_w			= pre_dac_data_r;
	out_dac_data			= 16'b0;
	interpolation_finish_w = interpolation_finish_r;

	case (state_r)
		S_IDLE: begin
			addr_counter_w = 20'b0;
			interpolation_counter_w = 4'b0;
			out_dac_data = 16'b0;
			pre_dac_data_w = 16'b0;
			dac_data_w = 16'b0;
			interpolation_counter_w = 4'b0;

			if (i_slow_0 | i_slow_1) begin
				interpolation_finish_w = 1'b0;
			end
			else begin
				interpolation_finish_w = 1'b1;
			end
			if (i_start) begin
				state_w = S_WAIT_NEGEDGE;
				dac_data_w = i_sram_data;
			end
		end
		S_RUN: begin
			if (i_stop) begin
				state_w = S_IDLE;
			end
			else if (i_pause) begin
				state_w = S_PAUSE;
			end
			else begin
				out_dac_data = dac_data_r;
				dac_data_w = i_sram_data;
				pre_dac_data_w = dac_data_r;
				addr_counter_w = i_fast ? addr_counter_r + {16'b0, ({1'b0, i_speed} + 4'd1)} : addr_counter_r + 20'd1;
				if (addr_counter_out >= i_end_addr) begin
					state_w = S_IDLE;
				end
				else if (i_pause) begin
					state_w = S_PAUSE;
				end
				else begin
					state_w = S_WAIT_NEGEDGE;
					interpolation_counter_w = 4'd0;
					interpolation_finish_w = 1'b0;
				end
			end
		end
		S_WAIT_0: begin
			if (i_stop) begin
				state_w = S_IDLE;
			end
			else if (i_pause) begin
				state_w = S_PAUSE;
			end
			else begin
				interpolation_counter_w = interpolation_counter_r + 4'd1;
				out_dac_data = pre_dac_data_r;
				if (interpolation_counter_r >= {1'b0, i_speed}) begin
					interpolation_counter_w = 4'b0;
					interpolation_finish_w = 1'b1;
					state_w = S_RUN;
				end
			end
		end
		S_WAIT_1: begin
			if (i_stop) begin
				state_w = S_IDLE;
			end
			else if (i_pause) begin
				state_w = S_PAUSE;
			end
			else
				interpolation_counter_w = interpolation_counter_r + 4'd1;
				out_dac_data = $signed( ($signed(dac_data_r - pre_dac_data_r) / $signed({13'b0, i_speed} + 16'd1)) * $signed({12'b0, interpolation_counter_r}) ) + pre_dac_data_r;
				if (interpolation_counter_r >= {1'b0, i_speed}) begin
					interpolation_counter_w = 4'd0;
					interpolation_finish_w = 1'b1;
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
		S_WAIT_NEGEDGE: begin
			addr_counter_w = addr_counter_out;
			pre_dac_data_w = pre_dac_data_tmp;
			out_dac_data = pre_dac_data_tmp;
			interpolation_counter_w = 4'd0;
			if (daclrck_negedge) begin
				if (i_slow_0) begin
					state_w = S_WAIT_0;
					interpolation_finish_w = 1'b0;
					interpolation_counter_w = 4'b0;
				end
				else if (i_slow_1) begin
					state_w = S_WAIT_1;
					interpolation_finish_w = 1'b0;
					interpolation_counter_w = 4'b0;
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
		dac_data_r 					<= 16'b0;
		state_r 					<= S_IDLE;
		addr_counter_out 			<= 20'b0;
		pre_dac_data_tmp			<= 16'b0;
		interpolation_finish_r 		<= 1'b0;
		daclrck_dly 				<= i_daclrck;
	end
	else begin
		dac_data_r 					<= dac_data_w;
		state_r 					<= state_w;
		addr_counter_out 			<= addr_counter_w;
		interpolation_finish_r 		<= interpolation_finish_w;
		pre_dac_data_tmp			<= pre_dac_data_w;
		daclrck_dly 				<= i_daclrck;
	end
end

always_ff @(negedge i_daclrck or negedge i_rst_n) begin
	if (!i_rst_n) begin
		interpolation_counter_r <= 4'b0;
		pre_dac_data_r 			<= 16'b0;
		addr_counter_r 			<= 20'b0;
	end
	else begin
		interpolation_counter_r <= interpolation_counter_w;
		pre_dac_data_r			<= pre_dac_data_w;
		addr_counter_r 			<= addr_counter_w;
	end
end

endmodule