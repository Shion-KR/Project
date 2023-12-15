`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/27 10:59:07
// Design Name: 
// Module Name: traffic_signal_control
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
module oneshot_first(clock, reset, button, button_trig);

parameter WIDTH = 1;
input clock, reset;
input [WIDTH-1:0] button;
reg [WIDTH-1:0] button_reg;
output reg [WIDTH-1:0] button_trig;

always @(negedge reset or posedge clock) begin
    if(!reset) begin
        button_reg <= {WIDTH{1'b0}};
        button_trig <= {WIDTH{1'b0}};
    end
    else begin
        button_reg <= button;
        button_trig <= button & ~button_reg;
    end
end

endmodule // first oneshot trigger for emergency situation


module traffic_signal_control(clock, reset, emergent_control, vehicle_signal, pedestrian_signal, LCD_E, LCD_RS, LCD_RW, LCD_DATA);
    
input clock, reset;
input emergent_control;
wire emergent_control_trigger;

output LCD_E, LCD_RS, LCD_RW;
output[7:0] LCD_DATA;

output reg [15:0] vehicle_signal;
output reg [7:0] pedestrian_signal;

integer cnt; // count
reg [3:0] state; // present situation
reg [3:0] memory; // manage clock
reg [5:0] second; // second
reg [5:0] minute; // minute
reg [4:0] hour; // hour

parameter A     = 4'b0000,
          B     = 4'b0001,
          C     = 4'b0010,
          D     = 4'b0011,
          E     = 4'b0100,
          F     = 4'b0101,
          G     = 4'b0110,
          H     = 4'b0111,
          A1    = 4'b1000,
          A2    = 4'b1001,
          B1    = 4'b1010,
          C1    = 4'b1011,
          E1    = 4'b1100,
          E2    = 4'b1101,
          F1    = 4'b1110,
          G1    = 4'b1111;
// each parameter : assignment's several situations

oneshot_first #(.WIDTH(1)) O1(clock, reset, button, button_trig); // oneshot_first
traffic_signal_text u(reset, clock, LCD_E, LCD_RS, LCD_RW, LCD_DATA, hour, minute, second, state);

always @(negedge reset or posedge clock)
begin
    if(!reset) begin
        hour <= 8;
        minute <= 0;
        second <= 0;
    end
    else begin
        if(cnt % 1000 == 0 && cnt != 0) begin
            second <= second + 1;
            if(second % 60 == 0 && second != 0) begin
                second <= 0;
                minute <= minute + 1;
                if(minute % 60 == 0 && minute != 0) begin
                    minute <= 0;
                    hour <= hour + 1;
                    if(hour >= 24)
                        hour <= 0;
                end
            end     
        end            
    end    
end
// clock setting    

always @(negedge reset or posedge clock)
begin
if(!reset) begin
    state <= A;
    memory <= 0;
    cnt <= 0;
end
else
begin
    if(hour >= 8 && hour < 23) begin
        case(memory)
            4'b0000 : begin
                state <= A;
                if(cnt == 5000) begin // experiment must be set by frequency 100Hz
                    memory <= 4'b0001;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end
            4'b0001 : begin
                state <= A1;
                if(cnt == 500) begin // experiment must be set by frequency 100Hz
                    memory <= 4'b0010;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end      
            4'b0010 : begin
                state <= D;
                if(cnt == 5000) begin // experiment must be set by frequency 100Hz
                    memory <= 4'b0011;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end            
            4'b0011 : begin
                state <= A1;
                if(cnt == 500) begin
                    memory <= 4'b0100;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end             
            4'b0100 : begin
                state <= F;
                if(cnt == 5000) begin
                    memory <= 4'b0101;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end           
            4'b0101 : begin
                state <= F1;
                if(cnt == 500) begin
                    memory <= 4'b0110;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end                 
            4'b0110 : begin
                state <= E;
                if(cnt == 5000) begin
                    memory <= 4'b0111;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end
            4'b0111 : begin
                state <= E1;
                if(cnt == 500) begin
                    memory <= 4'b1000;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end
            4'b1000 : begin
                state <= G;
                if(cnt == 5000) begin
                    memory <= 4'b1001;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end
            4'b1001 : begin
                state <= G1;
                if(cnt == 500) begin
                    memory <= 4'b1010;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end
            4'b1010 : begin
                state <= E;
                if(cnt == 5000) begin
                    memory <= 4'b1011;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end
            4'b1011 : begin
                state <= E2;
                if(cnt == 500) begin
                    memory <= 4'b0000;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end
        endcase
    end    // situation case - DAY
    else begin        
        case(memory)
            4'b0000 : begin
                state <= B;
                if(cnt == 10000) begin // experiment must be set by frequency 100Hz
                    memory <= 4'b0001;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end
            4'b0001 : begin
                state <= B1;
                if(cnt == 1000) begin // experiment must be set by frequency 100Hz
                    memory <= 4'b0010;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end      
            4'b0010 : begin
                state <= A;
                if(cnt == 10000) begin // experiment must be set by frequency 100Hz
                    memory <= 4'b0011;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end            
            4'b0011 : begin
                state <= A2;
                if(cnt == 1000) begin
                    memory <= 4'b0100;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end             
            4'b0100 : begin
                state <= C;
                if(cnt == 10000) begin
                    memory <= 4'b0101;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end           
            4'b0101 : begin
                state <= C1;
                if(cnt == 1000) begin
                    memory <= 4'b0110;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end                 
            4'b0110 : begin
                state <= A;
                if(cnt == 10000) begin
                    memory <= 4'b0111;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end
            4'b0111 : begin
                state <= A1;
                if(cnt == 1000) begin
                    memory <= 4'b1000;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end
            4'b1000 : begin
                state <= E;
                if(cnt == 10000) begin
                    memory <= 4'b1001;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end
            4'b1001 : begin
                state <= E2;
                if(cnt == 1000) begin
                    memory <= 4'b1010;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end
            4'b1010 : begin
                state <= H;
                if(cnt == 10000) begin
                    memory <= 4'b1011;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end
            4'b1011 : begin
                state <= E2;
                if(cnt == 1000) begin
                    memory <= 4'b0000;
                    cnt <= 0;
                end
                else
                    cnt <= cnt + 1;
            end
        endcase
    end
end
end  
// situation case - NIGHT
                  
always @(posedge clock or negedge reset)
begin
    if(!reset)
        {pedestrian_signal, vehicle_signal} = 24'b01011010_1000_1000_0100_0100;
    else begin
        case(state) // S N W E & Green-Red (pedestrian) / S N W E & Green-Red-Yellow-Left (vehicle)
            A : begin
                if(cnt < 2500)         
                {pedestrian_signal, vehicle_signal} = 24'b01011010_1000_1000_0100_0100; // clear
                else if(cnt % 500 == 0) begin
                pedestrian_signal[3] = ~pedestrian_signal[3];
                pedestrian_signal[1] = ~pedestrian_signal[1];
                end
            end
            A1 : 
                {pedestrian_signal, vehicle_signal} = 24'b01010101_0010_0010_0100_0100; // A to D or E & D to F
            A2 :
                {pedestrian_signal, vehicle_signal} = 24'b01011001_1000_0010_0100_0100; // A to C
            B : begin
                if(cnt < 2500)
                {pedestrian_signal, vehicle_signal} = 24'b01010110_0100_1001_0100_0100; // clear
                else if(cnt % 500 == 0)
                pedestrian_signal[1] = ~pedestrian_signal[1];
            end
            B1 :
                {pedestrian_signal, vehicle_signal} = 24'b01010110_0100_0010_0100_0100; // B to A
            C : begin
                if(cnt < 2500)
                {pedestrian_signal, vehicle_signal} = 24'b01011001_1001_0100_0100_0100; // clear
                else if(cnt % 500 == 0)
                pedestrian_signal[3] = ~pedestrian_signal[3];
            end   
            C1 :
                {pedestrian_signal, vehicle_signal} = 24'b01011001_1010_0100_0100_0100; // C to A
            D : 
                {pedestrian_signal, vehicle_signal} = 24'b01010101_0001_0001_0100_0100; // clear
            E : begin
                if(cnt < 2500)
                {pedestrian_signal, vehicle_signal} = 24'b10100101_0100_0100_1000_1000; // clear
                else if(cnt % 500 == 0) begin
                pedestrian_signal[5] = ~pedestrian_signal[5];
                pedestrian_signal[7] = ~pedestrian_signal[7];
                end
            end  
            E1 : 
                {pedestrian_signal, vehicle_signal} = 24'b10010101_0100_0100_0010_1000; // E to G
            E2 : 
                {pedestrian_signal, vehicle_signal} = 24'b01010101_0100_0100_0010_0010; // E to A & E to H & H to B
            F : begin
                if(cnt < 2500)
                {pedestrian_signal, vehicle_signal} = 24'b01100101_0100_0100_1001_0100; // clear
                else if(cnt % 500 == 0)
                pedestrian_signal[5] = ~pedestrian_signal[5];
            end
            F1 :
                {pedestrian_signal, vehicle_signal} = 24'b01100101_0100_0100_1010_0100; // F to E
            G : begin
                if(cnt < 2500)
                {pedestrian_signal, vehicle_signal} = 24'b10010101_0100_0100_0100_1001; // clear
                else if(cnt % 500 == 0)
                pedestrian_signal[7] = ~pedestrian_signal[7];
            end
            G1 : 
                {pedestrian_signal, vehicle_signal} = 24'b10010101_0100_0100_0100_1010; // G to E
            H : 
                {pedestrian_signal, vehicle_signal} = 24'b01010101_0100_0100_0001_0001; // clear    
            default : {pedestrian_signal, vehicle_signal} = 24'b01011010_1000_1000_0100_0100;
        endcase
    end                
end            
   
endmodule