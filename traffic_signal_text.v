`timescale 1ms / 1us
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/04 11:34:41
// Design Name: 
// Module Name: traffic_signal_text
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module bin2bcd(clk, rst, bin, bcd_out);

input clk, rst;
input [7:0] bin;
reg [11:0] bcd;
output reg [11:0] bcd_out;

reg [2:0] i;

always @(posedge rst or posedge clk) begin
    if(rst) begin
        bcd <= {4'd0, 4'd0, 4'd0};
        i <= 0;
    end
    else begin
        if(i == 0) begin
            bcd[11:1] <= 11'b0000_0000_000;
            bcd[0] <= bin[7];
        end
        else begin
            bcd[11:9] <= (bcd[11:8] >= 3'd5) ? bcd[11:8] + 2'd3 : bcd[11:8];
            bcd[8:5] <= (bcd[7:4] >= 3'd5) ? bcd[7:4] + 2'd3 : bcd[7:4];
            bcd[4:1] <= (bcd[3:0] >= 3'd5) ? bcd[3:0] + 2'd3 : bcd[3:0];
            bcd[0] <= bin[7-i];
        end
        i <= i + 1;
    end
end

always @(posedge rst or posedge clk) begin
    if(rst) bcd_out <= {4'd0, 4'd0, 4'd0};
    else if(i == 0) bcd_out <= bcd;
end
endmodule


module traffic_signal_text(rst, clk, LCD_E, LCD_RS, LCD_RW, LCD_DATA, hour, minute, second, situation); // situation is main module's state

input rst, clk;
input [5:0] second;
input [5:0] minute;
input [4:0] hour;
input [3:0] situation;

output LCD_E, LCD_RS, LCD_RW;
output reg [7:0] LCD_DATA;

wire LCD_E;
reg LCD_RS, LCD_RW;
reg [5:0] second_reg;

reg [2:0] state;
wire [11:0] hour_bcd;
wire [11:0] minute_bcd;
wire [11:0] second_bcd;
parameter DELAY        = 3'b000,
          FUNCTION_SET = 3'b001,
          ENTRY_MODE   = 3'b010,
          DISP_ONOFF   = 3'b011,
          LINE1        = 3'b100,
          LINE2        = 3'b101,
          DELAY_T      = 3'b110,
          CLEAR_DISP   = 3'b111;
          
integer cnt;

bin2bcd n1(clk, rst, {3'b000, hour}, hour_bcd);
bin2bcd n2(clk, rst, {2'b00, minute}, minute_bcd);
bin2bcd n3(clk, rst, {2'b00, second}, second_bcd);

always @(posedge clk or negedge rst)
begin
    if(!rst)
        second_reg <= 0;
    else begin
        second_reg <= second;
    end
end

always @(posedge clk or negedge rst)
begin
    if(!rst)
        state <= DELAY;
    else
    begin
        case(state)
            DELAY : begin
                if(cnt == 10) state <= FUNCTION_SET;
            end
            FUNCTION_SET : begin
                if(cnt == 5) state <= DISP_ONOFF;
            end
            DISP_ONOFF : begin
                if(cnt == 5) state <= ENTRY_MODE;
            end
            ENTRY_MODE : begin
                if(cnt == 5) state <= LINE1;
            end
            LINE1 : begin
                if(cnt == 20) state <= LINE2;
            end
            LINE2 : begin
                if(cnt == 20) state <= DELAY_T;
            end
            DELAY_T : begin
                if(second_reg != second) state <= CLEAR_DISP;
            end
            CLEAR_DISP : begin
                if(cnt == 5) state <= LINE1;
            end
            default : state <=  DELAY;
        endcase
    end
end

always @(posedge clk or negedge rst)
begin
    if(!rst)
        cnt <= 0;
    else begin
        case(state)
            DELAY :
                if(cnt >= 10) cnt <= 0;
                else cnt <= cnt + 1;
            FUNCTION_SET :
                if(cnt >= 5) cnt <= 0;
                else cnt <= cnt + 1;
            DISP_ONOFF :
                if(cnt >= 5) cnt <= 0;
                else cnt <= cnt + 1;
            ENTRY_MODE :
                if(cnt >= 5) cnt <= 0;
                else cnt <= cnt + 1;
            LINE1 :
                if(cnt >= 20) cnt <= 0;
                else cnt <= cnt + 1;
            LINE2 : 
                if(cnt >= 20) cnt <= 0;
                else cnt <= cnt + 1;
            DELAY_T :
                if(second_reg != second) cnt <= 0;
            CLEAR_DISP :
                if(cnt >= 5) cnt <= 0;
                else cnt <= cnt + 1;
            default : state <= DELAY;
        endcase
    end
end        

always @(posedge clk or negedge rst)
begin
    if(!rst)
        {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_1_00000000;
    else begin
        case(state)
            FUNCTION_SET :
                {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_0011_1000;
            DISP_ONOFF :
                {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_0000_1100;
            ENTRY_MODE :
                {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_0000_0110;
            LINE1 :
                begin
                    case(cnt)
                        00 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_1000_0000;
                        01 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0101_0100; // T
                        02 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_1001; // i
                        03 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_1101; // m
                        04 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_0101; // e
                        05 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1100; // :
                        06 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; //
                        07 : {LCD_RS, LCD_RW, LCD_DATA} <= {1'b1, 1'b0, 4'b0011, hour_bcd [7:4]}; // ho
                        08 : {LCD_RS, LCD_RW, LCD_DATA} <= {1'b1, 1'b0, 4'b0011, hour_bcd [3:0]}; // ur
                        09 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1100; // :
                        10 : {LCD_RS, LCD_RW, LCD_DATA} <= {1'b1, 1'b0, 4'b0011, minute_bcd [7:4]}; // min
                        11 : {LCD_RS, LCD_RW, LCD_DATA} <= {1'b1, 1'b0, 4'b0011, minute_bcd [3:0]}; // ute
                        12 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1100; // :
                        13 : {LCD_RS, LCD_RW, LCD_DATA} <= {1'b1, 1'b0, 4'b0011, second_bcd [7:4]}; // sec
                        14 : {LCD_RS, LCD_RW, LCD_DATA} <= {1'b1, 1'b0, 4'b0011, second_bcd [3:0]}; // ond
                        default : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000;
                endcase
            end    
            LINE2 :
                begin
                if(hour >= 8 && hour < 23) begin
                    case(cnt)
                        00 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_1100_0000;
                        01 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_0101_0011; // S
                        02 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0111_0100; // t
                        03 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_0001; // a
                        04 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0111_0100; // t
                        05 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_0101; // e
                        06 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1100; // :
                        07 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; // 
                        08 : {LCD_RS, LCD_RW, LCD_DATA} <= {1'b1, 1'b0, 4'b0100, situation [3:0]}; // A ~ H
                        09 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; // 
                        10 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_0100; // D
                        11 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_0001; // A
                        12 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0101_1001; // Y
                        default : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; // 
                    endcase
                end
                else begin
                    case(cnt)
                        00 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_1100_0000;
                        01 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_0101_0011; // S
                        02 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0111_0100; // t
                        03 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_0001; // a
                        04 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0111_0100; // t
                        05 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_0101; // e
                        06 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1100; // :
                        07 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; // 
                        08 : {LCD_RS, LCD_RW, LCD_DATA} <= {1'b1, 1'b0, 4'b0100, situation [3:0]}; // A ~ H
                        09 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; // 
                        10 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_1110; // N
                        11 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_1001; // I
                        12 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_0111; // G
                        13 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_1000; // H
                        14 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0101_0100; // T
                        default : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; // 
                    endcase
                end
            end
            DELAY_T :
                {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_0000_0010;
            CLEAR_DISP :
                {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_0000_0001;
            default :
                {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_1_0000_0000;
        endcase
    end
end

assign LCD_E = clk;

endmodule
