`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2014 12:11:59 AM
// Design Name: 
// Module Name: testbench
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


module testbench(CLK, led0, led1);
    input CLK;
    output wire led0, led1;
    
	reg can_clk = 0;
	reg uart_clk = 0;
	parameter RUN_LEN = 100;	

	initial begin
		can_clk = 0;
	end

    wire can_lo_out, can_hi_out;
	wire can_lo_in, can_hi_in;
	assign can_lo_in = can_lo_out;
	assign can_hi_in = can_hi_out;    

    custom_can_node can0(can_clk, can_clk, 0, can_lo_in, can_lo_out, can_hi_in, can_hi_out, led0, led1);

	integer i=0;
	always@(can_clk) begin
		can_clk <= #10 ~can_clk;
		$write("%d: ",i);
		i = i+1;
		if(i>RUN_LEN) 
			$finish;
	end

	always@(uart_clk) begin
		uart_clk <= #1 ~uart_clk;
	end
endmodule
