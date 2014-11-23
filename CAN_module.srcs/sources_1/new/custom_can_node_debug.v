//`timescale 1ns / 1ps
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
        reset,
        can_lo_in,
        can_lo_out,
        can_hi_in,
        can_hi_out, 
        led0, 
        led1
    );
    input can_clk, reset, can_lo_in, can_hi_in;
    output reg can_lo_out, can_hi_out, led0, led1;

    /* 4 states for CAN node:
    *   1. Idle  
    *   2. Sending
    *   3. Wait Rx
    *   4. Process
    */
    reg[1:0] state, next_state = 0;
    reg[31:0] bits_transmitted = 0;
    reg[127:0] message = 0; 
    
    reg[10:0] message_id = 11'h123;
    reg[3:0] data_length = 0;
    reg[7:0] data[7:0];
    reg[14:0] CRC = 0;
    
    parameter EOF = 7'h7F;
    // Extended format versus standard format base length
     parameter msg_length_base = 44;  
    `ifdef EXTENDEDFORMAT
        parameter msg_length_base += 18; 
    `endif
    reg[7:0] msg_length = 0;
    integer i = 0;
	reg toggle = 0;
    
    always@(state, toggle) begin
		$display("state: %d, CH %d, CL: %d",state, can_hi_out, can_lo_out);
        case(state)
            0: begin    // IDLE
                /*
                *   Generate message if want to transmit. If no message to send, listen to bus. Else transmit
                */
                bits_transmitted <= 0;
                message = {1'b0,message_id,2'b00,data_length}; 
                msg_length = msg_length_base;
                for(i=0; i < data_length; i = i+1) begin
                    message = {message,{data[i]}};
                    msg_length = msg_length + 8;
                end
                message = {message, {CRC},3'b101,EOF};
                // For now always transmit
				$display("message: %x",message);
                next_state <= 1; 
            end
            1: begin    // SENDING
                // Check transmitted bit with bus
                // If not equal, lower priority. Kick off bus
                // Takes cycle to latch output bit, so check next cycle
                if( (can_hi_out != can_hi_in) || (can_lo_out != can_lo_in) ) begin
                     bits_transmitted = msg_length - 1;
                end else begin
                    // Dominant = Logic 0 = High voltage
                    // Recessive = Logic 1 = Low voltage
                    can_hi_out = !message[msg_length - bits_transmitted];    
                    can_lo_out = message[msg_length - bits_transmitted];
                end
                
                bits_transmitted = bits_transmitted + 1;
                if(bits_transmitted < msg_length) begin
                    next_state <= 1;
                end else begin
                    next_state <= 2;
                end 
            end
            2: begin    // WAIT RX
                next_state <= 3;
            end
            3: begin    // PROCESS
                next_state <= 0;
            end
        endcase   
        led0 = state[0];
        led1 = state[1];
    end
    
    always@(posedge can_clk) begin
        if (reset) 
            state <= 0;
        else
            state <= next_state;
		toggle <= ~toggle;
    end
endmodule
