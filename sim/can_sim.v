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
        led1,
		node_num
    );
    input can_clk, sys_clk, reset, can_lo_in, can_hi_in;
    input wire clk_src0, clk_src1;
	input wire[3:0] node_num;
    output reg can_lo_out, can_hi_out, led0, led1;
    output led2, led3;

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
    reg[1:0] state = 2'b00, next_state = 2'b00;
    reg toggle = 0;
	reg can_hi, can_lo;
	reg id_transmit_flag;
	reg lower_priority = 0;
    reg[31:0] bits_transmitted;
    reg[31:0] bits_received;
    reg[127:0] message = 0; 
    
    reg[127:0] received_msg;
    
    reg[10:0] message_id = 11'h123;
    reg[3:0] data_length = 4'b0001;
    reg[7:0] data[7:0];
    reg[14:0] CRC = 15'h0000;
    
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
        case(state)
            IDLE: begin    // IDLE
                /*
                *   Generate message if want to transmit. If no message to send, listen to bus. Else transmit
                */
                bits_transmitted <= 0;
                bits_received <= 0;
				can_hi_out <= 0;
				can_lo_out <= 1;
                message = {1'b0,{message_id},2'b00,{data_length}}; 
                msg_length = msg_length_base;
                // Test with random data transmission
                data[0] = 8'h89;
                for(i=0; i < data_length; i = i+1) begin
                    message = {message,{data[i]}};
                    msg_length = msg_length + 8;     
                end
                message = {message, {CRC},3'b101,EOF};
                
                $display("NODE: %d => (Message: %x (len: %d))",node_num, message, msg_length);                
                // For now always transmit
                next_state <= 1; 
            end
            SENDING: begin    // SENDING
                // Check transmitted bit with bus
                // If not equal, lower priority. Kick off bus
                // Takes cycle to latch output bit, so check next cycle
                if( lower_priority ) begin
                     bits_transmitted = msg_length - 1;
                     received_msg = {received_msg, can_lo_in};
                end else begin
                    // Dominant = Logic 0 = High voltage
                    // Recessive = Logic 1 = Low voltage
                    can_hi_out = can_hi_in | !message[(msg_length-1) - bits_transmitted];    
					can_lo_out = !can_hi_out;
                    received_msg = {received_msg, can_lo_out};
                end
                
                bits_transmitted = bits_transmitted + 1;
                bits_received = bits_received + 1;
		
				// While sending id/start bit, set id_transmit flag hi	
				if(bits_transmitted < 13) 
					id_transmit_flag <= 1;
				else
					id_transmit_flag <= 0;

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
				can_hi_out <= 0;
				can_lo_out <= 1;
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
  
	// Check to see if message id lower priority 
	always@(negedge can_clk) begin
		if(can_hi_out != can_hi_in && id_transmit_flag) begin
			lower_priority <= 1; 
		end else begin
			lower_priority <= 0;
		end
        $display("NODE: %d => State: %d, CANout: (%d, %d), CANin: (%d, %d)",node_num, state, can_hi_out, can_lo_out, can_hi_in, can_lo_in);
		can_hi_out = 0;
		can_lo_out = 1;
	end
 
    always@(posedge can_clk) begin
        if (reset) 
            state <= 0;
        else
            state <= next_state;
        toggle <= ~toggle;
    end
endmodule
