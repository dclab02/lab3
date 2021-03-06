module AudLCD (
    input i_rst_n,
    input i_clk,        
    input [2:0] i_state,
    input [3:0] i_speed,
    input i_interpolation,
    
    output [7:0] o_LCD_DATA,
    output      o_LCD_EN,
    output      o_LCD_RS,
    output      o_LCD_RW,
    output      o_LCD_ON,
    output      o_LCD_BLON

);

parameter LCD_INIT           = 3'd0;
parameter LCD_WAIT           = 3'd1;
parameter LCD_IDLE           = 3'd2;
parameter LCD_RECD           = 3'd3;
parameter LCD_RECD_PAUSE     = 3'd4;
parameter LCD_PLAY           = 3'd5;
parameter LCD_PLAY_PAUSE     = 3'd6;
parameter LCD_PLAYSTOP       = 3'd7;

// state definition the same as Top
localparam S_IDLE       = 3'd1; 
localparam S_RECD       = 3'd2;
localparam S_RECD_PAUSE = 3'd3;
localparam S_PLAY       = 3'd4;
localparam S_PLAY_PAUSE = 3'd5;

parameter FUNCTION_SET    = 8'h38;
parameter DISPLAY_ON      = 8'h0C;
parameter DISPLAY_CLEAR   = 8'h01;
parameter ENTRY_MODE_SET  = 8'h06;
parameter BACK_TO_ZERO    = 8'h80;
parameter ENTER           = 8'hC0;

// Number
parameter CGRAM_0 = 8'h30;
parameter CGRAM_1 = 8'h31;
parameter CGRAM_2 = 8'h32;
parameter CGRAM_3 = 8'h33;
parameter CGRAM_4 = 8'h34;
parameter CGRAM_5 = 8'h35;
parameter CGRAM_6 = 8'h36;
parameter CGRAM_7 = 8'h37;
parameter CGRAM_8 = 8'h38;
parameter CGRAM_9 = 8'h39;

// Lower case
parameter CGRAM_a  = 8'h61;
parameter CGRAM_b  = 8'h62;
parameter CGRAM_c  = 8'h63;
parameter CGRAM_d  = 8'h64;
parameter CGRAM_e  = 8'h65;
parameter CGRAM_f  = 8'h66;
parameter CGRAM_g  = 8'h67;
parameter CGRAM_h  = 8'h68;
parameter CGRAM_i  = 8'h69;
parameter CGRAM_j  = 8'h6A;
parameter CGRAM_k  = 8'h6B;
parameter CGRAM_l  = 8'h6C;
parameter CGRAM_m  = 8'h6D;
parameter CGRAM_n  = 8'h6E;
parameter CGRAM_o  = 8'h6F;
parameter CGRAM_p  = 8'h70;
parameter CGRAM_q  = 8'h71;
parameter CGRAM_r  = 8'h72;
parameter CGRAM_s  = 8'h73;
parameter CGRAM_t  = 8'h74;
parameter CGRAM_u  = 8'h75;
parameter CGRAM_v  = 8'h76;
parameter CGRAM_w  = 8'h77;
parameter CGRAM_x  = 8'h78;
parameter CGRAM_y  = 8'h79;
parameter CGRAM_z  = 8'h7A;

// Upper case
parameter CGRAM_BIG_F     = 8'h46;
parameter CGRAM_BIG_M     = 8'h4D;
parameter CGRAM_BIG_N     = 8'h4E;
parameter CGRAM_BIG_P     = 8'h50;
parameter CGRAM_BIG_R     = 8'h52;
parameter CGRAM_BIG_S     = 8'h53;
parameter CGRAM_BIG_X     = 8'h58;

// Symbol
parameter CGRAM_BLANK     = 8'h20;
parameter CGRAM_R_ARROW   = 8'h7E;
parameter CGRAM_L_ARROW   = 8'h7F;
parameter CGRAM_COMMA     = 8'h2C;
parameter CGRAM_SLASH     = 8'h2F;
parameter CGRAM_COLON     = 8'h3A;
parameter CGRAM_QUESTION  = 8'h3F;
parameter CGRAM_DOT       = 8'h2E;

logic        enable;
logic        RSChange;
logic        DataChange;
logic        stateChanged;
logic [2:0]  lcdstate_r, lcdstate_w;
logic [5:0]  counter_r, counter_w;
logic        RS_r, RS_w;
logic        enable_r, enable_w;
logic [7:0]  data_r, data_w;

assign o_LCD_DATA = data_r;
assign o_LCD_EN = enable;
assign o_LCD_RS = RS_r;
assign o_LCD_RW = 0;
assign o_LCD_ON   = 1;
assign o_LCD_BLON = 0;

Controller my_controller(
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .o_enable(enable),
    .o_RS_change(RSChange),
    .o_data_change(DataChange)
);

DetectChangeState my_detect(
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_speed(i_speed),
    .i_state(i_state),
    .i_interpolation(i_interpolation),
    .i_en(enable),
    .o_change(stateChanged)
);

always_comb begin
    lcdstate_w = lcdstate_r;
    counter_w = counter_r;
    RS_w = RS_r;
    enable_w = enable_r;
    data_w = data_r;

    case (lcdstate_r)
        LCD_INIT: begin
            if(RSChange) begin                
                case(counter_r)
                    0, 1, 2, 3, 4, 21, 38 : RS_w = 0;
                    default : RS_w = 1;
                endcase
            end
            else if (DataChange) begin
                counter_w = counter_r + 1;
                case(counter_r)
                    0 : data_w = FUNCTION_SET; 
                    1 : data_w = DISPLAY_ON; 
                    2 : data_w = DISPLAY_CLEAR; 
                    3 : data_w = ENTRY_MODE_SET; 
                    4 : data_w = BACK_TO_ZERO;
                    21: data_w = ENTER;
                    38: begin
                        data_w = BACK_TO_ZERO;
                        lcdstate_w = LCD_IDLE;
                        counter_w = 0;
                    end
                endcase
            end
        end
        LCD_WAIT: begin
            if(stateChanged) begin
                case(i_state)
                    S_IDLE       : lcdstate_w = LCD_IDLE; 
                    S_RECD       : lcdstate_w = LCD_RECD; 
                    S_RECD_PAUSE : lcdstate_w = LCD_RECD_PAUSE; 
                    S_PLAY       : lcdstate_w = LCD_PLAY; 
                    S_PLAY_PAUSE : lcdstate_w = LCD_PLAY_PAUSE;
                    // S_PLAYSTOP   : lcdstate_w = LCD_PLAYSTOP;
                    default : lcdstate_w = LCD_WAIT;
                endcase
            end
            else begin
                lcdstate_w = LCD_WAIT;
            end
        end
        LCD_IDLE: begin //0~15 16 enter 17~32 33 to zero 
            if(RSChange) begin                
                case(counter_r) 
                    0  : RS_w = 0;
                    16 : RS_w = 0;
                    34 : RS_w = 0;
                    default:RS_w = 1;
                endcase
            end
            else if (DataChange) begin
                counter_w = counter_r + 1;
                case (counter_r)
                    0  : data_w = BACK_TO_ZERO;
                    1  : data_w = CGRAM_R_ARROW;
                    2  : data_w = CGRAM_BIG_R;
                    3  : data_w = CGRAM_e;
                    4  : data_w = CGRAM_a;
                    5  : data_w = CGRAM_d;
                    6  : data_w = CGRAM_y;
                    16 : data_w = ENTER;
                    34 : begin
                        data_w = BACK_TO_ZERO;
                        lcdstate_w = LCD_WAIT;
                        counter_w = 0;
                    end
                    default : data_w = CGRAM_BLANK;
                endcase
            end
        end
        LCD_RECD: begin
            if(RSChange) begin                
                case(counter_r) 
                    16 : RS_w = 0;
                    33 : RS_w = 0;
                    default: RS_w = 1;
                endcase
            end
            else if (DataChange) begin
                counter_w = counter_r + 1;
                case(counter_r)
                    0  : data_w = CGRAM_BIG_R;
                    1  : data_w = CGRAM_e;
                    2  : data_w = CGRAM_c;
                    3  : data_w = CGRAM_o;
                    4  : data_w = CGRAM_r;
                    5  : data_w = CGRAM_d;
                    6  : data_w = CGRAM_i;
                    7  : data_w = CGRAM_n;
                    8  : data_w = CGRAM_g;
                    9  : data_w = CGRAM_DOT;
                    10 : data_w = CGRAM_DOT;
                    11 : data_w = CGRAM_DOT;
                    16 : data_w = ENTER;
                    33 : begin
                        data_w = BACK_TO_ZERO;
                        lcdstate_w = LCD_WAIT;
                        counter_w = 0;
                    end
                    default : data_w = CGRAM_BLANK;
                endcase
            end
        end
        LCD_RECD_PAUSE: begin
            if(RSChange) begin                
                case(counter_r) 
                    16 : RS_w = 0;
                    33 : RS_w = 0;
                    default: RS_w = 1;
                endcase
            end
            else if (DataChange) begin
                counter_w = counter_r + 1;
                case (counter_r)
                    0  : data_w = CGRAM_BIG_R;
                    1  : data_w = CGRAM_e;
                    2  : data_w = CGRAM_c;
                    3  : data_w = CGRAM_o;
                    4  : data_w = CGRAM_r;
                    5  : data_w = CGRAM_d;
                    16 : data_w = ENTER;
                    17 : data_w = CGRAM_BLANK;
                    18 : data_w = CGRAM_BIG_P;
                    19 : data_w = CGRAM_a;
                    20 : data_w = CGRAM_u;
                    21 : data_w = CGRAM_s;
                    22 : data_w = CGRAM_e;
                    33 : begin
                        data_w = BACK_TO_ZERO;
                        lcdstate_w = LCD_WAIT;
                        counter_w = 0;
                    end
                    default : data_w = CGRAM_BLANK;
                endcase
            end
        end
        LCD_PLAY: begin
            if(RSChange) begin                
                case(counter_r) 
                    16 : RS_w = 0;
                    33 : RS_w = 0;
                    default: RS_w = 1;
                endcase
            end
            else if (DataChange) begin
                counter_w = counter_r + 1;
                case(counter_r)
                    0  : data_w = CGRAM_BIG_P;
                    1  : data_w = CGRAM_l;
                    2  : data_w = CGRAM_a;
                    3  : data_w = CGRAM_y;
                    4  : data_w = CGRAM_i;
                    5  : data_w = CGRAM_n;
                    6  : data_w = CGRAM_g;
                    7  : data_w = CGRAM_DOT;
                    8  : data_w = CGRAM_DOT;
                    9  : data_w = CGRAM_DOT;
                    16 : data_w = ENTER;
                    17 : data_w = (i_speed == 0 || i_speed == 8)? CGRAM_BIG_N : (i_speed[3]) ? CGRAM_BIG_F : CGRAM_BIG_S;
                    18 : data_w = (i_speed == 0 || i_speed == 8)? CGRAM_o:(i_speed[3])? CGRAM_a : CGRAM_l;
                    19 : data_w = (i_speed == 0 || i_speed == 8)? CGRAM_r:(i_speed[3])? CGRAM_s : CGRAM_o;
                    20 : data_w = (i_speed == 0 || i_speed == 8)? CGRAM_m:(i_speed[3])? CGRAM_t : CGRAM_w;
                    21 : data_w = CGRAM_COLON;
                    22 : begin
                        case(i_speed)
                            1,2,3,4,5,6,7 : data_w = CGRAM_1;
                            default : data_w = CGRAM_BLANK;
                        endcase
                    end                    
                    23 : begin
                        case(i_speed)
                            1,2,3,4,5,6,7 : data_w = CGRAM_SLASH;
                            default : data_w = CGRAM_BLANK;
                        endcase
                    end
                    24 : begin
                        case(i_speed)
                            0,8 : data_w = CGRAM_1;
                            1,9 : data_w = CGRAM_2;
                            2,10 : data_w = CGRAM_3;
                            3,11 : data_w = CGRAM_4;
                            4,12 : data_w = CGRAM_5;
                            5,13 : data_w = CGRAM_6;
                            6,14 : data_w = CGRAM_7;
                            7,15 : data_w = CGRAM_8;
                        endcase
                    end
                    25 : data_w = CGRAM_x;
                    26 : data_w = (i_speed>7 || i_speed == 0)? CGRAM_BLANK: CGRAM_COMMA;
                    27 : data_w = (i_speed>7 || i_speed == 0)? CGRAM_BLANK: CGRAM_BIG_M;
                    28 : data_w = (i_speed>7 || i_speed == 0)? CGRAM_BLANK: CGRAM_o;
                    29 : data_w = (i_speed>7 || i_speed == 0)? CGRAM_BLANK: CGRAM_d;
                    30 : data_w = (i_speed>7 || i_speed == 0)? CGRAM_BLANK: CGRAM_e;
                    31 : data_w = (i_speed>7 || i_speed == 0)? CGRAM_BLANK: CGRAM_COLON;
                    32 : data_w = (i_speed>7 || i_speed == 0)? CGRAM_BLANK:(i_interpolation)? CGRAM_1 : CGRAM_0;
                    33 : begin
                        data_w = BACK_TO_ZERO;
                        lcdstate_w = LCD_WAIT;
                        counter_w = 0;
                    end
                    default : data_w = CGRAM_BLANK;
                endcase
            end
        end
        LCD_PLAY_PAUSE: begin
            if (RSChange) begin                
                case(counter_r) 
                    16 : RS_w = 0;
                    33 : RS_w = 0;
                    default:RS_w = 1;
                endcase
            end
            else if (DataChange) begin
                counter_w = counter_r + 1;
                case (counter_r)
                    0  : data_w = CGRAM_BIG_P;
                    1  : data_w = CGRAM_l;
                    2  : data_w = CGRAM_a;
                    3  : data_w = CGRAM_y;
                    4  : data_w = CGRAM_BIG_P;
                    5  : data_w = CGRAM_a;
                    6  : data_w = CGRAM_u;
                    7  : data_w = CGRAM_s;
                    8  : data_w = CGRAM_e;
                    16 : data_w = ENTER;
                    17 : data_w = (i_speed == 0 || i_speed == 8)? CGRAM_BIG_N : (i_speed[3])? CGRAM_BIG_F : CGRAM_BIG_S;
                    18 : data_w = (i_speed == 0 || i_speed == 8)? CGRAM_o:(i_speed[3])? CGRAM_a : CGRAM_l;
                    19 : data_w = (i_speed == 0 || i_speed == 8)? CGRAM_r:(i_speed[3])? CGRAM_s : CGRAM_o;
                    20 : data_w = (i_speed == 0 || i_speed == 8)? CGRAM_m:(i_speed[3])? CGRAM_t : CGRAM_w;
                    21 : data_w = CGRAM_COLON;
                    22 : begin
                        case(i_speed)
                            1,2,3,4,5,6,7 : data_w = CGRAM_1;
                            default : data_w = CGRAM_BLANK;
                        endcase
                    end                    
                    23 : begin
                        case(i_speed)
                            1,2,3,4,5,6,7 : data_w = CGRAM_SLASH;
                            default : data_w = CGRAM_BLANK;
                        endcase
                    end
                    24 : begin
                        case(i_speed)
                            0,8  : data_w = CGRAM_1;
                            1,9  : data_w = CGRAM_2;
                            2,10 : data_w = CGRAM_3;
                            3,11 : data_w = CGRAM_4;
                            4,12 : data_w = CGRAM_5;
                            5,13 : data_w = CGRAM_6;
                            6,14 : data_w = CGRAM_7;
                            7,15 : data_w = CGRAM_8;
                        endcase
                    end
                    25 : data_w = CGRAM_BIG_X;
                    26 : data_w = (i_speed>7 || i_speed == 0)? CGRAM_BLANK: CGRAM_COMMA;
                    27 : data_w = (i_speed>7 || i_speed == 0)? CGRAM_BLANK: CGRAM_m;
                    28 : data_w = (i_speed>7 || i_speed == 0)? CGRAM_BLANK: CGRAM_o;
                    29 : data_w = (i_speed>7 || i_speed == 0)? CGRAM_BLANK: CGRAM_d;
                    30 : data_w = (i_speed>7 || i_speed == 0)? CGRAM_BLANK: CGRAM_e;
                    31 : data_w = (i_speed>7 || i_speed == 0)? CGRAM_BLANK: CGRAM_COLON;
                    32 : data_w = (i_speed>7 || i_speed == 0)? CGRAM_BLANK:(i_interpolation)? CGRAM_1 : CGRAM_0;
                    33 : begin
                        data_w = BACK_TO_ZERO;
                        lcdstate_w = LCD_WAIT;
                        counter_w = 0;
                    end
                    default : data_w = CGRAM_BLANK;
                endcase
            end
        end
        LCD_PLAYSTOP: begin
            if (RSChange) begin                
                case (counter_r) 
                    16 : RS_w = 0;
                    33 : RS_w = 0;
                    default:RS_w = 1;
                endcase
            end
            else if (DataChange) begin
                counter_w = counter_r + 1;
                case(counter_r)
                    0  : data_w = CGRAM_BIG_P;
                    1  : data_w = CGRAM_l;
                    2  : data_w = CGRAM_a;
                    3  : data_w = CGRAM_y;
                    4  : data_w = CGRAM_BIG_S;
                    5  : data_w = CGRAM_t;
                    6  : data_w = CGRAM_o;
                    7  : data_w = CGRAM_p;
                    16 : data_w = ENTER;
                    17 : data_w = (i_speed == 0 || i_speed == 8)? CGRAM_BIG_N : (i_speed[3])? CGRAM_BIG_F : CGRAM_BIG_S;
                    18 : data_w = (i_speed == 0 || i_speed == 8)? CGRAM_o:(i_speed[3])? CGRAM_a : CGRAM_l;
                    19 : data_w = (i_speed == 0 || i_speed == 8)? CGRAM_r:(i_speed[3])? CGRAM_s : CGRAM_o;
                    20 : data_w = (i_speed == 0 || i_speed == 8)? CGRAM_m:(i_speed[3])? CGRAM_t : CGRAM_w;
                    21 : data_w = CGRAM_COLON;
                    22 : begin
                        case(i_speed)
                            1,2,3,4,5,6,7 : data_w = CGRAM_1;
                            default : data_w = CGRAM_BLANK;
                        endcase
                    end                    
                    23 : begin
                        case(i_speed)
                            1,2,3,4,5,6,7 : data_w = CGRAM_SLASH;
                            default : data_w = CGRAM_BLANK;
                        endcase
                    end
                    24 : begin
                        case(i_speed)
                            0,8 : data_w = CGRAM_1;
                            1,9 : data_w = CGRAM_2;
                            2,10 : data_w = CGRAM_3;
                            3,11 : data_w = CGRAM_4;
                            4,12 : data_w = CGRAM_5;
                            5,13 : data_w = CGRAM_6;
                            6,14 : data_w = CGRAM_7;
                            7,15 : data_w = CGRAM_8;
                        endcase
                    end
                    25 : data_w = CGRAM_BIG_X;
                    26 : data_w = (i_speed > 7 || i_speed == 0)? CGRAM_BLANK: CGRAM_COMMA;
                    27 : data_w = (i_speed > 7 || i_speed == 0)? CGRAM_BLANK: CGRAM_BIG_M;
                    28 : data_w = (i_speed > 7 || i_speed == 0)? CGRAM_BLANK: CGRAM_o;
                    29 : data_w = (i_speed > 7 || i_speed == 0)? CGRAM_BLANK: CGRAM_d;
                    30 : data_w = (i_speed > 7 || i_speed == 0)? CGRAM_BLANK: CGRAM_e;
                    31 : data_w = (i_speed > 7 || i_speed == 0)? CGRAM_BLANK: CGRAM_COLON;
                    32 : data_w = (i_speed > 7 || i_speed == 0)? CGRAM_BLANK:(i_interpolation)? CGRAM_1 : CGRAM_0;
                    33 : begin
                        data_w = BACK_TO_ZERO;
                        lcdstate_w = LCD_WAIT;
                        counter_w = 0;
                    end
                    default : data_w = CGRAM_BLANK;
                endcase
            end
        end        
    endcase    
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        lcdstate_r      <= LCD_INIT;
        counter_r       <= 0;
        RS_r            <= 0;
        enable_r        <= 0;
        data_r          <= 8'd0;
    end
    else begin
        lcdstate_r      <= lcdstate_w;
        counter_r       <= counter_w;
        RS_r            <= RS_w;
        enable_r        <= enable_w;
        data_r          <= data_w;
    end
end

endmodule

module  DetectChangeState(
    input  i_clk,
    input  i_rst_n,
    input [3:0] i_speed,
    input [2:0]  i_state,
    input i_interpolation,
    input  i_en,
    output o_change
);

logic [2:0]  i_state_r,  i_state_w;
logic [3:0]  speed_r,  speed_w;
logic state_r, state_w;
logic interpolation_r, interpolation_w;
logic en_r, en_w;
logic change_r, change_w;

parameter IDLE = 1'd0;
parameter WAIT_EN = 1'd1;

assign o_change = change_r;

always_comb begin
    i_state_w = i_state;
    speed_w = i_speed;
    state_w = state_r;
    interpolation_w = i_interpolation;
    en_w = i_en;
    change_w = change_r;
    if(state_r == IDLE) begin
        if(i_state_r != i_state || speed_r != i_speed || interpolation_r != i_interpolation) begin
            state_w = WAIT_EN;
            change_w = 0;
        end
        else begin
            state_w = IDLE;
            change_w = 0;
        end
    end
    else begin
        if(en_r == 1 && i_en == 0) begin //negedge
            state_w = IDLE;
            change_w = 1;
        end
        else begin
            state_w = WAIT_EN;
            change_w = 0;
        end
    end
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        i_state_r  <= 0;
        speed_r    <= 0;
        state_r    <= 0;
        en_r       <= 0;
        change_r   <= 0;
        interpolation_r <= 0;
    end
    else begin
        i_state_r  <= i_state_w;
        speed_r    <= speed_w;
        state_r    <= state_w;
        en_r       <= en_w;
        change_r   <= change_w;
        interpolation_r <= interpolation_w;
    end
end
endmodule

module  Controller(
    input  i_clk,
    input  i_rst_n,
    output o_enable,
    output o_RS_change,
    output o_data_change
);

parameter IDLE = 2'd0;
parameter ENHIGH = 2'd1;
parameter ENLOW  = 2'd2;
    
logic [1:0] state_r,         state_w;
logic [4:0] counter_r,       counter_w;
logic [17:0] wait_r,         wait_w;
logic       enable_r,        enable_w;
logic       RS_change_r,     RS_change_w;
logic       data_change_r,   data_change_w;

assign o_enable      = enable_r;
assign o_RS_change   = RS_change_r;
assign o_data_change = data_change_r;

always_comb begin
    state_w = state_r;
    counter_w = counter_r;
    enable_w = enable_r;
    RS_change_w = RS_change_r;
    data_change_w = data_change_r;
    wait_w = wait_r;
    if(state_r == IDLE) begin
        if(wait_r != 0) begin
            wait_w = wait_r - 1;
        end
        else begin
            counter_w = counter_r + 1;
            if(counter_r == 2) begin
                RS_change_w = 1;
            end
            else if(counter_r == 10) begin
                enable_w = 1;
                state_w = ENHIGH;
                counter_w = 0;
            end
            else begin
                RS_change_w = 0;
            end
        end
    end
    else if (state_r == ENLOW) begin
        counter_w = counter_r + 1;
        if(counter_r == 10) begin
            RS_change_w = 1;
        end
        else if(counter_r == 20) begin
            enable_w = 1;
            state_w = ENHIGH;
            counter_w = 0;
        end
        else begin
            RS_change_w = 0;
        end
    end
    else begin
        counter_w = counter_r + 1;
        if(counter_r == 10) begin
            data_change_w = 1;
        end
        else if(counter_r == 20) begin
            enable_w = 0;
            state_w = ENLOW;
            counter_w = 0;
        end
        else begin
            data_change_w = 0;
        end
    end    
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        state_r          <= IDLE;
        counter_r        <= 0;
        wait_r           <= 11'd1;
        enable_r         <= 0;
        RS_change_r      <= 0;
        data_change_r    <= 0;        
    end
    else begin
        state_r          <= state_w;
        counter_r        <= counter_w;
        wait_r           <= wait_w;
        enable_r         <= enable_w;
        RS_change_r      <= RS_change_w;
        data_change_r    <= data_change_w;
    end
end
endmodule
