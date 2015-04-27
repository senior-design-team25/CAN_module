`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/15/2015 06:52:04 PM
// Design Name: 
// Module Name: pwm
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


module simple_pwm(clk_in, x_in, PWM_out);   
    parameter MAXBITS = 8;        //maximum number of bits for input value and counter
    
    input clk_in;                 //clock for counter
    input [MAXBITS-1:0] x_in;     //control value that defines pulse width
    output reg PWM_out = 1;       //PWM signal out
    
    reg [MAXBITS-1:0] counter = 0;
    
    always@ (posedge clk_in )begin
          if ( counter < x_in )
                PWM_out <= 1;
          else
                PWM_out <= 0;
          counter <= counter+1;
     end
endmodule


// 
//  Inputs: 50Hz clock and duty cycle from 0-255 (capped at 233)
//  Outputs: PWM signal with duty cycle 3-12% for servo-PWM
//
module servo_pwm(clk_in, duty, PWM_out);
    parameter MAXBITS = 8;
    parameter ENDCYCLE = 5233;  
    parameter STARTOFFSET = 157;
    parameter SCALE = 75;
    
    input clk_in;
    input wire[MAXBITS-1:0] duty;
    output reg PWM_out = 1;
    
    reg [11:0] counter = 0;
    wire [MAXBITS+1:0] scaled_duty;   // 10 bits to allow for unsigned left shift

    assign scaled_duty = (duty > 240) ? 240 : duty;

    always@(posedge clk_in) begin
        if(counter < (((scaled_duty << 1)) + STARTOFFSET))
            PWM_out <= 1;
        else 
            PWM_out <= 0;
        
        if(counter > ENDCYCLE)
            counter <= 0;
        else
            counter <= counter + 1'b1;
    end   
endmodule
