`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/22/2014 08:20:01 PM
// Design Name: 
// Module Name: clock_divider
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

module clock_divider(clk100Mhz, slowClk, divider); 
input clk100Mhz; //fast clock 
input[31:0] divider;  //rate of new clock
output slowClk; //slow clock 
reg[26:0] counter; 

initial begin 
  counter = 0; 
  slowClk = 0;
end 

reg slowClk;

always @ (posedge clk100Mhz) begin 
	  if(counter == divider) begin 
		 counter <= 1; 
		 slowClk <= ~slowClk;
	  end else begin 
		 counter <= counter + 1;
	  end
	end
endmodule