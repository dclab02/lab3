module AudLCD (
    input i_rst_n,
    input i_clk,
    input [2:0] i_state,
    input i_fast,
    input [2:0] i_speed,

	inout  [7:0] o_LCD_DATA,
	output       o_LCD_EN,
	output       o_LCD_RS,
	output       o_LCD_RW,
	output       o_LCD_ON,
	output       o_LCD_BLON
);

LCD lcd0(
    .i_rst_n(i_rst_n),
    .i_clk(i_clk),

    .i_clr(),
    .i_col(),
    .i_row(),
    .i_char(),

    .o_DATA(o_LCD_DATA),
    .o_EN(o_LCD_EN),
    .o_RS(o_LCD_RS),
    .o_RW(o_LCD_RW),
    .o_ON(o_LCD_ON),
    .o_BLON(o_LCD_BLON)
);

localparam S_IDLE = 0;
localparam S_RECD = 1;
localparam S_PLAY = 2;

logic [2:0] state_r, state_w;

assign state_w = i_state;

always_comb begin
    state_w = state_r;
    case (state_r)
        S_IDLE: begin
            
        end 
        S_RECD: begin
            
        end
        S_PLAY: begin
            
        end
        // default: 
    endcase
end

always_ff @( posedge i_clk or negedge i_rst_n ) begin
    if (!i_rst_n) begin
        state_r <= 3'b0;
    end
    else begin
        state_r <= state_w;
    end
end
    
endmodule
