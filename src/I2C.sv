// send / receive I2C data
module I2C(
    input	i_rst_n,
    input	i_clk,      // s_clk
    input	i_start,    // control if start
    input   i_addr,     // chip address (7 bit)
    input   i_rw,       // chip R/W (1'b0 | 1'b1)
    input   i_reg_data, // chip reg and data (7 + 9 bit)

    output	o_finished,
    output	o_sclk, 
    inout	o_sdat,     // data in / out
    output	o_oen       // you are outputing (you are not outputing only when you are "ack"ing.)
);

parameter S_IDLE     = 0;
parameter S_ADDR     = 1;       // sending slave addr
parameter S_RW       = 2;       // sending R/W
parameter S_REG_DATA_UPPER = 3; // sending register and data bits
parameter S_REG_DATA_LOWER = 4; // sending register and data bits
parameter S_ACK      = 5;       // ack state
parameter S_STOP     = 6;


logic [2:0] state_r, state_w;
logic [2:0] prev_state_r, prev_state_w; // previous state for S_ACK to determine where to go next
logic data_r, data_w; // data on i2c
logic oen_r, oen_w; // open enable
logic [2:0] counter_r, counter_w; // counter, every 8 bits will jump to ack state and back

assign o_sclk = (state_r == S_IDLE || state_r == S_STOP) ? 1'b1 : i_clk; // if not idle, it's the clock, otherwise, should be 1
assign o_oen = oen_r;
assign o_sdat = data_r;

always_comb begin
    state_w = state_r;
    prev_state_w = prev_state_r;
    data_w = data_r;
    oen_w = oen_r;
    counter_w = counter_r;
    case (state_r)
        // idle, not sending or reading from i2c
        S_IDLE: begin
            if (i_start) begin // pull down o_sdat, pull up oen_r
                state_w = S_ADDR;
                oen_w = 1;
                counter_w = 0;
                data_w = 0;
            end
        end

        // sending address (only 7 bit)
        S_ADDR: begin
            if (counter_r < 7) beginx
                data_w = i_addr[counter_r];
                counter_w = counter_r + 1'b1;
            end
            else begin
                state_w = S_RW;
            end
        end

        // sending R/W (only 1 bit) to i2c, will jump to ack
        S_RW: begin
            data_w = i_rw;
            if (counter_r == 7) begin // will always be 7 in this case (S_ADDR send 7 bits)
                state_w = S_ACK;
                prev_state_w = S_RW;
                oen_w = 0; // for ack, output enable is false
            end
        end

        S_REG_DATA_UPPER: begin
            data_w = i_reg_data[counter_r];
            counter_w = counter_r + 1'b1;
            if (counter_r == 7) begin // go to ack
                state_w = S_ACK;
                prev_state_w = S_REG_DATA_UPPER;
                oen_w = 0;
            end
        end

        S_REG_DATA_LOWER: begin
            data_w = i_reg_data[counter_r + 8];
            counter_w = counter_r + 1'b1;
            if (counter_r == 7) begin
                state_w = S_ACK;
                prev_state_w = S_REG_DATA_LOWER;
                oen_w = 0;
            end
        end

        S_STOP: begin
            data_w = 1;
            state_w = S_IDLE;
            o_finished = 1;
        end

        S_ACK: begin
            // TODO: check ACK

            counter_w = 0;
            if (prev_state_r == S_RW) begin
                state_w = S_REG;
                oen_w = 1; // go back to output 
            end
            else if (prev_state_r == S_REG_DATA_UPPER) begin
                state_w = S_REG_DATA_LOWER;
                oen_w = 1;
            end
            else if (prev_state_r == S_REG_DATA_LOWER) begin
                // TODO: Stop, return to IDLE
                state_w = S_STOP;
                data_w = 0;
                oen_w = 1;
            end
        end
end

always_ff @(posedge i_clk or posedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= S_IDLE;
        prev_state_r <= S_IDLE;
        data_r <= 0;
        oen_r <= 1;
        counter_r <= 0;
    end
   
    else begin
        state_r <= state_w;
        prev_state_r <= prev_state_w;
        data_r <= data_w;
        oen_r <= oen_w;
        counter_r <= counter_w;
    end
end


endmodule