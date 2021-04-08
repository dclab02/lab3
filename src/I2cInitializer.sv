// Implement I2C to intialize wm8731
module I2cInitializer(
input	i_rst_n,
input	i_clk,
input 	i_start,
output	o_finished,
output	o_sclk,
inout	o_sdat,
output	o_oen  // you are outputing (you are not outputing only when you are "ack"ing.)
);

// state
parameter S_IDLE 	= 0; // idle, initial state
parameter S_START 	= 1; // start setting
parameter S_SETTING = 2; // setting state, which will send data through i2c to wm8731
parameter S_FINISH 	= 3; // finish setup
// address and rw
parameter Address = 7'b0011010; // wm8731 address
parameter RW = 1'b0; // i2c writing (0)
// reg and data
parameter Reset 						 = 16'b0001111000000000;
parameter Analogue_Audio_Path_Control 	 = 16'b0000100000010101;
parameter Digital_Audio_Path_Control 	 = 16'b0000101000000000;
parameter Power_Down_Control 			 = 16'b0000110000000000;
parameter Digital_Audio_Interface_Format = 16'b0000111001000010;
parameter Sampling_Control 				 = 16'b0001000000011001;
parameter Active_Control 				 = 16'b0001001000000001;

logic [1:0] state_r, state_w; // state
logic [15:0] reg_data_r, reg_data_w; // reg and data
logic [2:0] counter_r, counter_w; // counter from 0 to 6, which is to send reg and data
logic start_r, start_w; // tell i2c module to start
logic fin_r, fin_w;     // tell upper this initialize finished
logic [6:0] addr = Address; // chip Address
logic rw = RW; // chip RW
logic i2c_fin; // get i2c finish or not

assign o_finished = fin_r;

I2C i2c(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk),
	.i_start(start_r),
	.i_addr(addr),
	.i_rw(rw),
	.i_reg_data(reg_data_r),
	.o_finished(i2c_fin),
	.o_sclk(o_sclk),
	.o_sdat(o_sdat),
	.o_oen(o_oen),
);

always_comb begin
	state_w = state_r;
	reg_data_w = reg_data_r;
	counter_w = counter_r;
	start_w = start_r;
	fin_w = fin_r;
	case (state_r)

		S_IDLE: begin
			start_w = 0;
			fin_w = 0;
			counter_w = 0;
			if (i_start): begin
				state_w = S_START;
			end
		end

		S_START: begin
			if (counter_r <= 6) 
				start_w = 1;
				state_w = S_SETTING;
				case (counter_r): begin
					0: begin reg_data_w = Reset; end
					1: begin reg_data_w = Analogue_Audio_Path_Control; end
					2: begin reg_data_w = Digital_Audio_Path_Control; end
					3: begin reg_data_w = Power_Down_Control; end
					4: begin reg_data_w = Digital_Audio_Interface_Format; end
					5: begin reg_data_w = Sampling_Control; end
					6: begin reg_data_w = Active_Control; end
				end
			end
			else begin
				state_w = S_FINISH;
			end
		end

		S_SETTING: begin
			start_w = 0; // pull down start for i2c module to work correctly
			if (i2c_fin) begin // i2c will pull this up when finished, then pull this down
				state_w = S_START;
				counter_w = counter_r + 1;
			end
		end
		
		S_FINISH: begin
			fin_w = 1;
			// state_w = S_IDLE; maybe don't need to jump back to idle
		end
	endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	// design your control here
    if (!i_rst_n) begin
		state_r <= S_IDLE;
		reg_data_r <= 0;
		counter_r <= 0;
		start_r <= 0;
		fin_r <= 0;
	end
	else begin
		state_r <= state_w;
		reg_data_r <= reg_data_w;
		counter_r <= counter_w;
		start_r <= start_w;
		fin_r <= fin_w;
	end
end
endmodule