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

module testbench(CLK, rst, swts, led0, led1, leds, can_hi_out, can_lo_out,
                    can_clk_out, uart_tx, uart_rx, test_pass, receive_rst, recv_out, brakes_out, motor_out);
    input CLK;
    input rst, uart_rx;
    input wire[3:0] swts;
    output wire led0, led1, can_lo_out;
    output wire can_hi_out;
    output wire can_clk_out, uart_tx;
    output wire[5:0] leds;
    output wire test_pass, receive_rst, recv_out, brakes_out, motor_out;
    
    wire led4, led5, led6, led7;

    wire can_clk;
    parameter RUN_LEN = 120;    

    wire[5:0] bits_sent;
    wire can_clk50kHz;
    wire can_clk100Hz;
    wire can_clk2sec;
    wire uart_clk;
    wire uart_clk_rx;
    wire pwm_clk_50Hz;
    
    wire ready;
    wire recv;
    wire[7:0] uart_data_in;
    wire[2:0] state;
    reg send = 1'b0;
    reg uart_nrst = 1'b0;
    reg[255:0] message = 256'd0;
    reg[7:0] uart_data;
    wire uart_clk_115200, uart_clk_tx_fast;
    reg[3:0] cmd_index = 0;
    
    clock_divider clkuarttx(CLK, uart_clk_115200, 32'd434); //115200 baudrate
    clock_divider clk_uarttx_debug(CLK, uart_clk_tx_fast, 32'd43);
    clock_divider clkuartrx(CLK, uart_clk_rx, 32'd108);     //460800baudrate
    clock_divider pwm_clk0(CLK, pwm_clk_50Hz, 32'd200);     //50Hz PWM Signal          
//    uarttx transmit(uart_clk_115200, rst, uart_data, recv, ready, uart_tx);
    uartrx receive(uart_clk_rx, !rst, uart_data_in, recv, uart_rx);

    uarttx transmit(uart_clk_tx_fast, uart_nrst, uart_data, send, ready, uart_tx);       // sped up for debugging
    reg uart_rx_nrst = 0;
    reg[6:0] index = 7'h00;
    reg[6:0] index_next = 7'h00;
    reg[31:0] cmd = 32'd0;

    assign CLK_out = CLK;
//    assign can_clk = (swts[0]) ? can_clk50kHz : 
//                     (swts[1]) ? can_clk100Hz :
//                      swts[2];
    assign can_clk = can_clk50kHz;
      
    assign leds[5] = uart_tx;
    assign leds[4] = uart_rx;
    assign leds[3] = (state[1] == state1[1]);
    assign uart_clk = uart_clk_115200;
    assign can_clk_out = can_clk;    
    assign test_pass = cmd_rdy;
    assign receive_rst = node_ack;
    assign recv_out = recv;

    reg cmd_rdy = 0;
    reg[3:0] counter = 0;

    always@(posedge uart_clk_115200) begin
        if(rst) begin
            cmd <= 0;
            cmd_index <= 0;
            uart_rx_nrst <= 0;
        end else begin
            uart_rx_nrst <= 1;
        end
        
        if(!cmd_rdy && recv) begin
            cmd <= {cmd[23:0], uart_data_in[7:0]};
            cmd_index <= cmd_index + 1'b1;
        end
        if(cmd[31:24] == "=")
            cmd_rdy <= 1;
        else begin
            cmd_rdy <= 0;
            counter <= 0;
        end
        if(node_ack || ((counter > 32'd16) & cmd_rdy)) begin
            cmd_rdy <= 0;
            cmd_index <= 0;
            cmd <= 32'd0;
            counter <= 0;
        end
        counter <= counter + 1'b1;
    end
    
    wire[127:0] brake_msg_out, controller_msg_out, motor_msg_out;
    assign message_in = (swts[0]) ? controller_msg_out : 
                        (swts[1]) ? motor_msg_out   :
                         brake_msg_out;
    //assign message_in = brake_msg_out;
    
    always@(posedge uart_clk_tx_fast or posedge rst) begin 
       if(rst) begin
           uart_nrst <= 1'b0;
           index <= 7'd16;
           message <= {message_in};
           uart_data <= 8'h00;
           send <= 1'b0;
       end else begin
           uart_nrst <= 1;
           if(index == 7'd16) 
               message <= {message_in};
           else
               message <= message;
           if(ready) begin
               if(index > 6'd0) begin
                   uart_data <= message[(((index)*8)-1'd1)-:8];
                   index <= (index - 6'd1);
                   send <= 1'b1;
               end else begin
                   uart_data <= 8'h00;
                   index <= 7'd16;
                   send <= 1'b1;
               end
           end
       end
    end
    
    clock_divider can_clk0(CLK, can_clk50kHz, 32'd1000); 
    clock_divider can_clk1(CLK, can_clk100Hz, 32'd500000); //115200 baudrate

    wire can0_hi, can0_lo, can1_hi, can1_lo, can2_hi, can2_lo;
    wire[5:0]  bits_sent1;
    wire[2:0] state1;
    wire[1:0] tmp;
    wire [127:0] message_in;
    assign can_hi_out = can0_hi | can1_hi;
    assign can_lo_out = !can_hi_out;
    
    
    faux_can control_node(  .can_clk(can_clk), 
                            .sys_clk(CLK), 
                            .reset(rst), 
                            .can_lo_in(can_lo_out), 
                            .can_lo_out(can0_lo), 
                            .can_hi_in(can_hi_out), 
                            .can_hi_out(can0_hi), 
                            .led0(led0),
                            .led1(led1),  
                            .node_num(4'h0),
                            .bits_sent(bits_sent),
                            .state_out(state),
                            .message_out(controller_msg_out),
                            .cmd_in(cmd),
                            .cmd_in_ready(cmd_rdy),
                            .cmd_awk(node_ack),
                            .pwm_out() 
                       );
                       

    faux_can brakes(       .can_clk(can_clk), 
                           .sys_clk(pwm_clk_50Hz), 
                           .reset(rst), 
                           .can_lo_in(can_lo_out), 
                           .can_lo_out(can1_lo), 
                           .can_hi_in(can_hi_out), 
                           .can_hi_out(can1_hi), 
                           .led0(),
                           .led1(),  
                           .node_num(4'h1),
                           .bits_sent(),
                           .state_out(state1),
                           .message_out(brake_msg_out),
                           .cmd_in(),
                           .cmd_in_ready(),
                           .cmd_awk(),
                           .pwm_out(brakes_out)
                        );
                        
    faux_can motors(       .can_clk(can_clk), 
                           .sys_clk(pwm_clk_50Hz), 
                           .reset(rst), 
                           .can_lo_in(can_lo_out), 
                           .can_lo_out(can2_lo), 
                           .can_hi_in(can_hi_out), 
                           .can_hi_out(can2_hi), 
                           .led0(),
                           .led1(),  
                           .node_num(4'h2),
                           .bits_sent(),
                           .state_out(),
                           .message_out(motor_msg_out),
                           .cmd_in(),
                           .cmd_in_ready(),
                           .cmd_awk(),
                           .pwm_out(motor_out)
                        );
endmodule
