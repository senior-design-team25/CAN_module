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

module testbench(CLK, rst, swts, led0, led1, leds, can_hi_out, can_lo_out, can_clk_out, uart_tx, uart_rx, test_pass, receive_rst);
    input CLK;
    input rst, uart_rx;
    input wire[3:0] swts;
    output wire led0, led1, can_lo_out;
    output wire can_hi_out;
    output wire can_clk_out, uart_tx;
    output wire[5:0] leds;
    output wire test_pass, receive_rst;
    
    wire led4, led5, led6, led7;

    wire can_clk;
    parameter RUN_LEN = 120;    

    wire[5:0] bits_sent;
    wire can_clk_50kHz;
    wire can_clk100Hz;
    wire can_clk2sec;
    wire uart_clk;
    wire uart_clk_rx;
    
    wire ready;
    wire recv;
    wire[7:0] uart_data_in;
    wire[2:0] state;
    reg send = 1'b0;
    reg uart_nrst = 1'b0;
    reg[255:0] message = 256'd0;
    reg[7:0] uart_data;
    wire uart_clk_115200;
    reg[3:0] cmd_index = 0;
    
    
    clock_divider clkuarttx(CLK, uart_clk_115200, 32'd434); //115200 baudrate
    clock_divider clkuartrx(CLK, uart_clk_rx, 32'd108);     //460800baudrate
//    uarttx transmit(uart_clk_115200, rst, uart_data, recv, ready, uart_tx);
    uartrx receive(uart_clk_rx, rst, uart_data, recv, uart_rx);

    uarttx transmit(uart_clk_115200, uart_nrst, uart_data, send, ready, uart_tx);
    
    reg[6:0] index = 7'h00;
    reg[6:0] index_next = 7'h00;
    reg[63:0] cmd = 74'd0;

    assign CLK_out = CLK;
    assign can_clk = (swts[0]) ? can_clk50kHz : 
                     (swts[1]) ? can_clk100Hz :
                      swts[2];
      
    assign leds[5] = uart_tx;
    assign leds[4] = uart_rx;
    assign uart_clk = uart_clk_115200;
    assign can_clk_out = can_clk;    
    assign test_pass = led0;
    assign receive_rst = led1;

    always@(posedge uart_clk_115200) begin
        if(rst) begin
            cmd <= 0;
            cmd_index <= 0;
        end 
        if(recv && !cmd_rdy) begin
            cmd <= {cmd[63:8], uart_data_in[7:0]};
            cmd_index <= cmd_index + 1'b1;
        end
        if(cmd_index == 7)
            cmd_rdy <= 1;
        else begin
            cmd_rdy <= 0;
        end
        if(node_ack) begin
            cmd_rdy <= 0;
            cmd_index <= 0;
        end
    end
    
    always@(posedge uart_clk or posedge rst) begin 
       if(rst) begin
           uart_nrst <= 1'b0;
           index <= 7'd32;
           message <= {"{message: #", message_in, "#}"};
           uart_data <= 8'h00;
           send <= 1'b0;
       end else begin
           uart_nrst <= 1;
           if(index == 7'd32) 
               message <= {"{message: #", message_in, "#}"};
           else
               message <= message;
           if(ready) begin
               if(index > 6'd0) begin
                   uart_data <= message[(((index)*8)-1'd1)-:8];
                   index <= (index - 6'd1);
                   send <= 1'b1;
               end else begin
                   uart_data <= 8'h00;
                   index <= 7'd32;
                   send <= 1'b1;
               end
           end
       end
    end
    
    clock_divider can_clk0(CLK, can_clk50kHz, 32'd1000); 
    clock_divider can_clk1(CLK, can_clk100Hz, 32'd500000); //115200 baudrate

    wire can0_hi, can0_lo, can1_hi, can1_lo;
    wire[5:0]  bits_sent1;
    wire[2:0] state1;
    wire[1:0] tmp;
    wire [127:0] message_in, message_in1;
    assign can_hi_out = can0_hi | can1_hi;
    assign can_lo_out = !can_hi_out;
    
    faux_can can0(         can_clk, 
                           CLK, 
                           rst, 
                           can_lo_out, 
                           can0_lo, 
                           can_hi_out, 
                           can0_hi, 
                           led0, 
                           led1, 
                           4'h0,
                           bits_sent,
                           state,
                           message_in 
                       );
                       

    faux_can can1(         can_clk, 
                           CLK, 
                           rst, 
                           can_lo_out, 
                           can1_lo, 
                           can_hi_out, 
                           can1_hi, 
                           tmp[0], 
                           tmp[1], 
                           4'h1,
                           bits_sent1,
                           state1,
                           message_in1
                        );
endmodule
