`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:44:08 02/20/2015 
// Design Name: 
// Module Name:    top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module top(
    output [6:1] LED,
    input [6:1] Switch
    );

 
	 genvar i;
	 generate
		for(i=1; i<7; i=i+1) begin:m
			assign LED[i] = Switch[i];
		end
	 endgenerate

	//assign LED[1] = Switch[1];

endmodule
