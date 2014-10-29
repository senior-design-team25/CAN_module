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
//`define SINGLE_NODE

module testbench(CLK, led0, led1, led2, led3);
    input CLK;
    output wire led0, led1, led2, led3;
    
    reg can_clk = 0;
    reg uart_clk = 0;
    parameter RUN_LEN = 120;    

    initial begin
        can_clk = 0;
    end

    wire can_lo_out_0, can_hi_out_0;
    wire can_lo_in_0, can_hi_in_0;
    wire can_lo_out_1, can_hi_out_1;
    wire can_lo_in_1, can_hi_in_1;

    wire can_hi, can_lo;

`ifndef SINGLE_NODE
    assign can_hi = can_hi_out_0 | can_hi_out_1;
    assign can_lo = ~can_hi;
`else
    assign can_lo_in_0 = can_lo_out_0;
    assign can_hi_in_0 = can_hi_out_0;
`endif
    custom_can_node can0(   can_clk, 
                            can_clk, 
                            1'b0, 
                            can_lo, 
                            can_lo_out_0, 
                            can_hi, 
                            can_hi_out_0, 
                            led0, 
                            led1, 
                            4'h0 
                        );
`ifndef SINGLE_NODE
    custom_can_node can1(   can_clk, 
                            can_clk, 
                            1'b0, 
                            can_lo, 
                            can_lo_out_1, 
                            can_hi, 
                            can_hi_out_1, 
                            led2, 
                            led3, 
                            4'h1
                        );
`endif

    integer i=0;
    always@(can_clk) begin
        can_clk <= #10 ~can_clk;
        i = i+1;
        if(i>RUN_LEN) 
            $finish;
    end
endmodule
