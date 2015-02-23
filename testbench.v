`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Kevin Gilbert
// Senior Design - Team25
// 23 February 2015
// 
// Revision: 1.1
// SevenSegment and UART message testbench
// 
//////////////////////////////////////////////////////////////////////////////////
// Uncomment SIM define below for testbench simulation
//`define SIM

module testbench(CLK, DPSwitch, Switch, LED, SevenSegment, Enable, gpio_P1);
    input CLK; 
    input[8:1] DPSwitch;
    input Switch;
    output[8:1] LED;
    output[7:0] SevenSegment; 
    output[3:1] Enable; 
    output wire[3:0] gpio_P1;
    wire uart_clk;
    wire uart_tx = 1'b0;
	 
    wire[1:0] anOut;
    wire CLK_1Khz;
    wire ready;
    reg send = 1'b1;
    reg uart_nrst = 1'b1;
    reg[255:0] message;
    reg[7:0] uart_data = "C";
    wire uart_clk_115200;
    wire uart_clk_9Hz;
        
    reg[6:0] index = 7'd32;
    
    complexDivider clock1kHz(CLK,CLK_1Khz,12000);
    HextoSevenSeg seven(CLK_1Khz, {1'b0, index}, SevenSegment, anOut); 
    assign Enable = {1'b1, anOut};
	 
    `ifdef SIM
    clock_divider clkuart(CLK, uart_clk_115200, 32'd2);
    `else
    clock_divider clkuart0(CLK, uart_clk_115200, 32'd52); //115200 baudrate
    clock_divider clkuart1(CLK, uart_clk_9Hz, 32'd1200000);
    `endif
    uarttx transmit(uart_clk, uart_nrst, uart_data[7:0], send, ready, gpio_P1[2]);

    wire rst;
	 
    assign rst = Switch ^ DPSwitch[1];
    assign uart_clk = DPSwitch[2] ? uart_clk_115200 : uart_clk_9Hz;   
    assign LED[7:1] = index[6:0];
    assign LED[8] = rst;
    assign gpio_P1[1] = uart_clk_115200;  
    assign gpio_P1[0] = CLK;
    assign gpio_P1[3] = 1'b1;

    always@(posedge uart_clk or posedge rst) begin 
       if(rst) begin
           uart_nrst <= 1'b0;
           index <= 7'd32;
           message <= {"{bits_sent: #", 2'b00, ~DPSwitch[8:3],"#}"};
           uart_data <= 8'h00;
           send <= 1'b0;
       end else begin
           uart_nrst <= 1;
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
	
	`ifdef SIM
		reg sim_clk;
		reg sim_rst;
		parameter RUN_LEN = 3000;
		initial begin
			sim_clk = 0;
			sim_rst = 1;
		end
		
		integer counter = 0;
		assign CLK = sim_clk;
		assign rst = sim_rst;
		
		always@(sim_clk) begin
			sim_clk <= #10 ~sim_clk;
			counter <= counter + 1;
			if(counter > 2) begin
				sim_rst <= 0;
			end
			if(counter > RUN_LEN) begin
				$finish;
			end
		end
	`endif
    
endmodule
