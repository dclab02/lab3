module LCD (
    input i_rst_n,
    input i_clk,

    input i_clr,
    input [3:0] i_col, // column : 0~15
    input [1:0] i_row, // row : 0~1
    input [7:0] i_char,

    output [7:0] o_DATA,
    output       o_EN,
    output       o_RS,
    output       o_RW,
    output       o_ON,
    output       o_BLON
);

// Symbol
parameter CGRAM_BLANK  = 8'h20;
parameter CGRAM_COLON  = 8'h3A;
parameter CGRAM_SLASH  = 8'h2F;

// Number
parameter CGRAM_0      = 8'h30;
parameter CGRAM_1      = 8'h31;
parameter CGRAM_2      = 8'h32;
parameter CGRAM_3      = 8'h33;
parameter CGRAM_4      = 8'h34;
parameter CGRAM_5      = 8'h35;
parameter CGRAM_6      = 8'h36;
parameter CGRAM_7      = 8'h37;
parameter CGRAM_8      = 8'h38;
parameter CGRAM_9      = 8'h39;

// Lower case
parameter CGRAM_a      = 8'h61;
parameter CGRAM_b      = 8'h62;
parameter CGRAM_c      = 8'h63;
parameter CGRAM_d      = 8'h64;
parameter CGRAM_e      = 8'h65;
parameter CGRAM_f      = 8'h66;
parameter CGRAM_g      = 8'h67;
parameter CGRAM_h      = 8'h68;
parameter CGRAM_i      = 8'h69;
parameter CGRAM_j      = 8'h6A;
parameter CGRAM_k      = 8'h6B;
parameter CGRAM_l      = 8'h6C;
parameter CGRAM_m      = 8'h6D;
parameter CGRAM_n      = 8'h6E;
parameter CGRAM_o      = 8'h6F;
parameter CGRAM_p      = 8'h70;
parameter CGRAM_q      = 8'h71;
parameter CGRAM_r      = 8'h72;
parameter CGRAM_s      = 8'h73;
parameter CGRAM_t      = 8'h74;
parameter CGRAM_u      = 8'h75;
parameter CGRAM_v      = 8'h76;
parameter CGRAM_w      = 8'h77;
parameter CGRAM_x      = 8'h78;
parameter CGRAM_y      = 8'h79;
parameter CGRAM_z      = 8'h7A;

// Upper case
parameter CGRAM_BIG_P     = 8'h50;
parameter CGRAM_BIG_R     = 8'h52;
parameter CGRAM_BIG_S     = 8'h53;
parameter CGRAM_BIG_X     = 8'h58;

// Commands
parameter DISP_CLEAR      = 8'h01;
parameter FUNC_SET        = 8'h38;
parameter DISP_ON         = 8'h0C;
parameter ENTRY_MODE_SET  = 8'h06;
parameter BACK_TO_ZERO    = 8'h80;
parameter ENTER           = 8'hC0;

localparam S_IDLE      = 0;
localparam S_INIT      = 1;
localparam S_CLEAR     = 2;
localparam S_SEND_CHAR = 3;
localparam S_TEST     = 4;
localparam S_TMP = 5;


// logic LCD_clk;
// logic [19:0] LCD_clk_cnt_r, LCD_clk_cnt_w;
logic [2:0] state_r, state_w;
logic [7:0] data_r, data_w;
logic RS_r, RS_w;
logic enable_r, enable_w, enable;

logic [19:0] cnt_r, cnt_w;

// parameter CLK_LCD_times = 19'd030000;
// logic [22:0]cnt;
// logic CLK_LCD;

// assign clk = CLK_LCD;

assign o_DATA = data_r;
assign o_EN = ~i_clk;
assign o_RS = RS_r;
assign o_RW = 0;
assign o_ON   = 1;
assign o_BLON = 1;

always_comb begin
    state_w = state_r;
    enable_w = enable_r;
    data_w = data_r;
    RS_w = RS_r;
    cnt_w = cnt_r;

    case (state_r)
        S_INIT: begin
            cnt_w = cnt_r + 1'b1;
            case (cnt_r)
                0: data_w = FUNC_SET;
                1: data_w = DISP_ON;
                2: data_w = DISP_CLEAR;
                3: data_w = BACK_TO_ZERO;
                10: data_w = ENTER;

                20: begin
                    data_w = BACK_TO_ZERO;
                    cnt_w = 0;
                    state_w = S_TEST;
                end
            endcase
        end
        S_IDLE: begin
            RS_w = 0;
            data_w = 8'b0;
            if (i_clr) begin
                state_w = S_CLEAR;
            end
        end
        S_CLEAR: begin
            RS_w = 0;
            data_w = DISP_CLEAR;
            state_w = S_IDLE;
        end
        S_SEND_CHAR: begin
            
        end
        S_TEST: begin
            RS_w = 1;
            data_w  = CGRAM_0;
            state_w = S_IDLE;
        end
        S_TMP: begin
            
        end
        // default: 
    endcase
end

always_ff @( posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= S_INIT;
        enable_r <= 1'b0;
        data_r <= 8'b0;
        RS_r <= 1'b0;
        cnt_r <= 20'b0;
    end
    else begin
        state_r <= state_w;
        enable_r <= enable_w;
        data_r <= data_w;
        RS_r <= RS_w;
        cnt_r <= cnt_w;
    end
end

endmodule