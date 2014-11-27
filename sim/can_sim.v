`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/12/2014 02:15:27 PM
// Design Name: 
// Module Name: custom_can_node
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


module custom_can_node(
        can_clk,
        sys_clk,
        reset,
        can_lo_in,
        can_lo_out,
        can_hi_in,
        can_hi_out, 
        led0, 
        led1
    );
    input can_clk, sys_clk, reset, can_lo_in, can_hi_in;
    input wire clk_src0, clk_src1;
    output reg can_lo_out, can_hi_out, led0, led1;
    output led2, led3;

/*************************************************************************
*   CLK Source
**************************************************************************/  
 
/*************************************************************************
*   UART Instantiation
**************************************************************************/   
    reg[7:0] uart_data;
    reg[7:0] uart_msg_buffer[127:0];
    wire[7:0] msg_segments[15:0]; // 128 total bits split into single byte segments = 16 segments
    
    reg[7:0] put_pt = 0;
    reg[7:0] get_pt = 0;
	reg uart_nrst = 0;
    
    generate
        genvar n;
        for(n=0; n<16; n=n+1) begin
            // Assign byte segments of message into indexable array for UART transmission
            assign msg_segments[n] = message[(n*8)+:8];
        end
    endgenerate
    reg send = 0;
    
    wire ready, tx, uart_clk;
    
    clock_divider clkuart(sys_clk, uart_clk, 868); //115200 baudrate
    uarttx transmit(can_clk, uart_nrst, uart_data, send, ready, tx);
    
    always@(ready, put_pt) begin
		if(uart_nrst == 0) begin
			$display("(%x %x) --> (%x %x)",msg_segments[1],msg_segments[0], uart_msg_buffer[1], uart_msg_buffer[0]);
		end
		uart_nrst <= 1;
        if(ready) begin
            if(get_pt != put_pt) begin
                uart_data <= uart_msg_buffer[get_pt];
                send = 1;
                get_pt = get_pt + 1;
                if(get_pt > 127)
                    get_pt = 0;
            end
         end else begin
            send = 0;
         end  
		$display("UART--> get_pt: %d, put_pt: %d. UART Data: %x(rdy: %d)",get_pt, put_pt, uart_data,ready);

    end

/*************************************************************************
*   State machine constants
**************************************************************************/
    /* 4 states for CAN node:
    *   1. Idle  
    *   2. Sending
    *   3. Wait Rx
    *   4. Process
    */
    parameter IDLE = 2'b00;
    parameter SENDING = 2'b01;
    parameter WAIT = 2'b10;
    parameter PROCESS = 2'b11;
    
/*************************************************************************
*   CAN frame components
**************************************************************************/
    reg[1:0] state, next_state;
    reg toggle = 0;
    reg[31:0] bits_transmitted;
    reg[31:0] bits_received;
    reg[127:0] message; 
    
    reg[127:0] received_msg;
    
    reg[10:0] message_id = 11'h123;
    reg[3:0] data_length = 4'b0001;
    reg[7:0] data[7:0];
    reg[14:0] CRC = 15'h0000;
    
    reg[10:0] received_id;
    
    parameter EOF = 7'h7F;
    // Extended format versus standard format base length
     parameter msg_length_base = 44;  
    `ifdef EXTENDEDFORMAT
        parameter msg_length_base += 18; 
    `endif
    reg[7:0] msg_length = 0;
    integer i = 0;
    integer index = 0;
    
    always@(state, toggle) begin
        $display("State: %d, CANout: (%d, %d)",state, can_hi_out, can_lo_out);
        case(state)
            IDLE: begin    // IDLE
                /*
                *   Generate message if want to transmit. If no message to send, listen to bus. Else transmit
                */
                bits_transmitted <= 0;
                bits_received <= 0;
                message = {1'b0,{message_id},2'b00,{data_length}}; 
                msg_length = msg_length_base;
                // Test with random data transmission
                data[0] = 8'h89;
                for(i=0; i < data_length; i = i+1) begin
                    message = {message,{data[i]}};
                    msg_length = msg_length + 8;     
                end
                message = {message, {CRC},3'b101,EOF};
                
                $display("Message: %x (len: %d)",message, msg_length);                
                $display("%b",message);
                // UART transmit message
                //for(i=0; i < (msg_length / 8)+1; i=i+1) begin
                for(i=0; i<17; i=i+1) begin
                    // while statement would not synthesize (would not converge after 2000 iterations
                    if(i<16) 
                        uart_msg_buffer[put_pt] <= msg_segments[15-i]; 
                    else
                        uart_msg_buffer[put_pt] <= 8'h0A; // Newline
                    put_pt = put_pt + 1;
                end
                received_id = 0;
                
                can_hi_out = can_hi_in;
                can_lo_out = can_lo_in;
                // For now always transmit
                next_state <= 1; 
            end
            SENDING: begin    // SENDING
                // Check transmitted bit with bus
                // If not equal, lower priority. Kick off bus
                // Takes cycle to latch output bit, so check next cycle
                if( (can_hi_out != can_hi_in) || (can_lo_out != can_lo_in) ) begin
                     bits_transmitted = msg_length - 1;
                     received_msg = {received_msg, can_lo_in};
                end else begin
                    // Dominant = Logic 0 = High voltage
                    // Recessive = Logic 1 = Low voltage
                    can_hi_out = !message[(msg_length-1) - bits_transmitted];    
                    can_lo_out = message[(msg_length-1) - bits_transmitted];
                    received_msg = {received_msg, can_lo_out};
                end
                
                bits_transmitted = bits_transmitted + 1;
                bits_received = bits_received + 1;
                if(bits_transmitted < msg_length) begin
                    next_state <= SENDING;
                end else begin
                    next_state <= WAIT;
                end 
            end
            WAIT: begin    // WAIT RX 
                // Currently not checking for bit stuffing since it's not yet implemented 
                // Check for end of frame
                bits_received = bits_received + 1;
                if( (received_msg[6:0] != 7'h7F)  && bits_received >= msg_length_base) begin
                    received_msg = {received_msg, can_lo_in};
                    next_state <= WAIT;
                end else begin
                    next_state <= PROCESS;
                end
            end
            PROCESS: begin    // PROCESS
                next_state <= 0;
            end
        endcase   
        led0 = state[1];
        led1 = state[0];
    end
    
    always@(posedge clk) begin
        if (reset) 
            state <= 0;
        else
            state <= next_state;
        toggle <= ~toggle;
    end
endmodule
