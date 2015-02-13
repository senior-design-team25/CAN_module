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
`define SINGLE_NODE

module testbench(CLK, rst, swts, led0, led1, leds, can_hi_out, can_lo_out, can_clk_out, uart_tx, state);
    input CLK;
    input rst;
    input wire[2:0] swts;
    output wire led0, led1, can_hi_out, can_lo_out;
    output wire can_clk_out, uart_tx;
    output wire[1:0] state;
    output wire[5:0] leds;
    
    wire led4, led5, led6, led7;

    wire can_clk;
    parameter RUN_LEN = 120;    

    wire can_lo_out_0, can_hi_out_0;
    wire can_lo_in_0, can_hi_in_0;
    wire can_lo_out_1, can_hi_out_1;
    wire can_lo_in_1, can_hi_in_1;
    wire can_lo_out_2, can_hi_out_2;
    wire can_lo_in_2, can_hi_in_2;
    wire can_lo_out_3, can_hi_out_3;
    wire can_lo_in_3, can_hi_in_3;

    wire can_hi, can_lo;

`ifndef SINGLE_NODE
    assign can_hi = can_hi_out_0 | can_hi_out_1 | can_hi_out_2 | can_hi_out_3;
    assign can_lo = ~can_hi;
`else
    //assign can_lo_in_0 = can_lo_out_0;
    //assign can_hi_in_0 = can_hi_out_0;
    assign can_hi = can_hi_out_0;
    assign can_lo = can_lo_out_0;
`endif
    
    assign can_hi_out = can_hi;
    assign can_lo_out = can_lo;
    assign can_clk_out = can_clk;
    assign CLK_out = CLK;
    assign state[0] = led0;
    assign state[1] = led1;
    
    wire[5:0] bits_sent;
    wire can_clk_50kHz;
    wire can_clk2Hz;
    wire can_clk2sec;
    wire uart_clk;
    
    wire ready;
    reg send;
    reg uart_nrst;
    reg[127:0] message;
    reg[7:0] uart_data;
    
    clock_divider clkuart(CLK, uart_clk, 32'd434); //115200 baudrate
    uarttx transmit(uart_clk, uart_nrst, uart_data, 1'b1, ready, uart_tx);
    
    integer index;
    always@(posedge ready or posedge rst) begin
        if(rst) begin
            uart_nrst <= 0;
            send <= 0;
        end else begin
            uart_nrst <= 1;
            send <= 1;
        end
    end

//    always@(ready, rst) begin 
//        if(rst) begin
//            uart_nrst <= 0;
//            index <= 16;
//            message = "{bits_sent: #";
//            message = {message, bits_sent[5:0]};
//            message = {message, "#}"};
//            uart_data = message[127-:8];
//            send <= 1;
//        end else begin
//            uart_nrst <= 1;
//            if(index > -1) begin
//                uart_data <= message[(index*8)-:8];
//                index <= (index - 1);
//                send <= 1;
//            end else begin
//                uart_data <= 8'h00;
//                index <= 16;
//                send <= 1;
//            end
//        end
//    end
    
    clock_divider can_clk0(CLK, can_clk50kHz, 32'd1000); 
    clock_divider can_clk1(CLK, can_clk2Hz, 32'd25000000); 
    clock_divider can_clk2(CLK, can_clk2sec,32'd100000000);
                     
    assign can_clk = (swts[0] && swts[1]) ? swts[2] 
                     : swts[1] ? can_clk2sec
                     : swts[0] ? can_clk2Hz
                     : can_clk50kHz; 
     
    assign leds[5:0] = bits_sent[5:0];

    custom_can_node can0(   can_clk, 
                            can_clk, 
                            rst, 
                            can_lo, 
                            can_lo_out_0, 
                            can_hi, 
                            can_hi_out_0, 
                            led0, 
                            led1, 
                            4'h0,
                            bits_sent 
                        );
`ifndef SINGLE_NODE
    custom_can_node can1(   can_clk, 
                            can_clk, 
                            rst, 
                            can_lo, 
                            can_lo_out_1, 
                            can_hi, 
                            can_hi_out_1, 
                            led2, 
                            led3, 
                            4'h1
                        );

    custom_can_node can2(   can_clk, 
                            can_clk, 
                            rst, 
                            can_lo, 
                            can_lo_out_2, 
                            can_hi, 
                            can_hi_out_2, 
                            led4, 
                            led5, 
                            4'h2
                        );

    custom_can_node can3(   can_clk, 
                            can_clk, 
                            rst, 
                            can_lo, 
                            can_lo_out_3, 
                            can_hi, 
                            can_hi_out_3, 
                            led6, 
                            led7, 
                            4'h3
                        );

`endif

//    integer i=0;
//    always@(can_clk) begin
//        can_clk <= #10 ~can_clk;
//        i = i+1;
//        if(i>RUN_LEN) 
//            $finish;
//    end
endmodule
