`timescale 1ms / 1us
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/04 10:57:18
// Design Name: 
// Module Name: traffic_signal_tb
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


module traffic_signal_tb();

reg clock, reset;
reg emergent_control;
wire [7:0] LCD_DATA;
wire [15:0] vehicle_signal;
wire [7:0] pedestrian_signal;

traffic_signal_control u(clock, reset, emergent_control, vehicle_signal, pedestrian_signal, LCD_E, LCD_RS, LCD_RW, LCD_DATA);

initial begin
         reset = 0; clock = 0;
    #0.1 reset = 1;
end

always
        #0.5 clock = ~clock;
    

endmodule
