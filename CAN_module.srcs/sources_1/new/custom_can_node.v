///*************************************************************************
//*   CLK Source
//**************************************************************************/  
//    wire db_clk;
//    wire clk_50kHz, clk_1Hz;
//    wire clk;
    
//    parameter SRC_RAW_BTN = 2'b00;
//    parameter SRC_DB_BTN = 2'b01;
//    parameter SRC_CLK_50kHz = 2'b10;
//    parameter SRC_CLK_1Hz = 2'b11;
    
//    //debounce db0(sys_clk, 0, can_clk, db_clk);
//    clock_divider clk500(sys_clk, clk_50kHz,5000000);
//    clock_divider clk1(sys_clk, clk_1Hz, 100000000);
//    /* I'm so sorry... */
//    assign clk = ((clk_src0) ? ((clk_src1) ? clk_1Hz : can_clk) : (clk_src1) ? clk_50kHz : can_clk);                                             
    
//    assign led2 = clk;
 
// /*************************************************************************
// *   UART Instantiation
// **************************************************************************/   
//    reg[7:0] uart_data;
//    reg[7:0] uart_msg_buffer[127:0];
//    wire[7:0] msg_segments[15:0]; // 128 total bits split into single byte segments = 16 segments
    
//    reg[7:0] put_pt = 0;
//    reg[7:0] get_pt = 0;
//    reg uart_nrst = 0;
    
//    generate
//        genvar n;
//        for(n=0; n<16; n=n+1) begin
//            // Assign byte segments of message into indexable array for UART transmission
//            assign msg_segments[n] = message[(n*8)+:8];
//        end
//    endgenerate
//    reg send = 0;
    
//    wire ready, tx, uart_clk;
//    assign UART_TX = tx;
    
//    clock_divider clkuart(sys_clk, uart_clk, 868); //115200 baudrate
//    uarttx transmit(can_clk, uart_nrst, uart_data, send, ready, tx);
       
//    always@(ready, put_pt) begin
//       uart_nrst <= 1;
//       if(ready) begin
//           if(get_pt != put_pt) begin
//                uart_data <= uart_msg_buffer[get_pt];
//                send = 1;
//                get_pt = get_pt + 1;
//                if(get_pt > 127)
//                    get_pt = 0;
//                end
//            end else begin
//               send = 0;
//            end   
//    end


//                // UART transmit message
//                //for(i=0; i < (msg_length / 8)+1; i=i+1) begin
//                for(i=0; i<17; i=i+1) begin
//                    // while statement would not synthesize (would not converge after 2000 iterations
//                    if(i<16) 
//                        uart_msg_buffer[put_pt] <= msg_segments[15-i]; 
//                    else
//                        uart_msg_buffer[put_pt] <= 8'h0A; // Newline
//                    put_pt = put_pt + 1;
//                end
//       
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
        node_num,
        bits_sent
    );
    input can_clk, sys_clk, reset, can_lo_in, can_hi_in;
    input wire[3:0] node_num;
    output reg can_lo_out, can_hi_out, led0, led1;
    output wire[5:0] bits_sent;

    assign bits_sent[5:0] = bits_transmitted[5:0];
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
    reg toggle;
    reg id_transmit_flag;
    reg lower_priority;
    //reg[31:0] bits_transmitted;
    reg[31:0] bits_transmitted;
    reg[31:0] bits_transmitted_next;
    reg[31:0] bits_received;
    reg[31:0] bits_received_next;
    reg[127:0] message; 
    
    reg[127:0] received_msg;
    reg[127:0] scrubbed_msg_in = 0;
    reg receive_rst;
    
    reg[10:0] message_id;
    reg[3:0] data_length = 4'b0001;
    reg[7:0] data[7:0];
    reg[14:0] CRC = 15'h0023;
    
    parameter EOF = 7'h7F;
    // Extended format versus standard format base length
    parameter msg_length_base = (44 + 4);  // Added security bits
    `ifdef EXTENDEDFORMAT
        parameter msg_length_base += 18; 
    `endif
    reg[3:0] src = 0;
    reg[7:0] msg_length = 0;
    reg[11:0] msg_id = 0;
    integer i = 0;
    integer index = 0;
   
    reg[4:0] bit_stuff_check = 5'b00001;
    reg flush_bitStuffCheck = 0; 
    reg[7:0] added_bits = 0;
    reg[3:0] msg_src = 0;

/*************************************************************************
*   CAN security components
**************************************************************************/
    reg[26:0] id_table [15:0];
    /*  |___ID___|______SRC______| --> 27 bits */
    integer ii = 0;
    parameter id_table_len = 16;

    initial begin
        for(ii=0;ii<15; ii=ii+1) begin
            id_table[ii] <= 27'hx;
        end        
    end

    always@(node_num, state) begin
        case(node_num)
            0: begin
                id_table[0] <= (11'h7FF << 16) | 16'h1;
                id_table[1] <= (11'h123 << 16) | 16'h2;
            end
            1: begin
                id_table[0] <= (11'h7F8 << 16) | 16'h0;
                id_table[1] <= (11'h123 << 16) | 16'h2;
                id_table[2] <= (11'h456 << 16) | 16'h3;
            end
            2: begin
                id_table[0] <= (11'h456 << 16) | 16'h3;
            end
            3: begin
                id_table[0] <= (11'h123 << 16) | 16'h2;
            end
        endcase    
    end    
/*************************************************************************
*   CAN state machine implementation
**************************************************************************/

    always@(state, toggle) begin
        case(state)
            IDLE: begin    // IDLE
                /*
                *   Generate message if want to transmit. If no message to send, listen to bus. Else transmit
                */
                //bits_transmitted <= 0;
                bits_transmitted_next <= 0;
               // bits_received <= 0;
                scrubbed_msg_in <= 0;
                receive_rst <= 1;
                can_hi_out <= 0;
                can_lo_out <= 1;
                
                case(node_num)
                    0: begin
                        message_id = 11'h7F8;
                        src = 4'h0;
                    end
                    1: begin
                        message_id = 11'h7FF;
                        src = 4'h1;
                    end
                    2: begin
                        message_id = 11'h123;
                        src = 4'h2;
                    end
                    3: begin
                        message_id = 11'h456;
                        src = 4'h3;
                    end
                endcase
                message = {1'b0,{message_id},2'b00,{data_length}}; 
                msg_length = msg_length_base;
                data[0] = 8'h89;        // Test with random data transmission
                for(i=0; i < data_length; i = i+1) begin
                    message = {message,{data[i]}};
                    msg_length = msg_length + 8;     
                end
                message = {message, {CRC},3'b101,{src},EOF};
                
                $display("NODE: %d, (Message: %x (len: %d))",node_num, message, msg_length);                
                $display("NODE: %d, SM: %b", node_num, message);
                // For now always transmit
                next_state <= 1; 
            end

            SENDING: begin    // SENDING
                receive_rst <= 0;
                /* Check transmitted bit with bus
                 * If not equal, lower priority. Kick off bus 
                 * Takes cycle to latch output bit, so check next cycle
                 */
                if( lower_priority ) begin
                     bits_transmitted_next = 32'h7FFFFFFE;
                end else begin
                    /* Dominant = Logic 0 = High voltage
                     * Recessive = Logic 1 = Low voltage
                     * Bit stuffing. Should not bit stuff during CRC and EoF transmission
                     */
                    if(bits_transmitted < (msg_length - 25)) begin
                        if( ((bit_stuff_check == 5'b0) && message[(msg_length-1)-bits_transmitted]) ||
                            ((bit_stuff_check == 5'h1F) && !message[(msg_length-1)-bits_transmitted])
                        ) begin
                            can_hi_out = !bit_stuff_check[0];
                            can_lo_out = !can_hi_out;
                            // Flush bit_stuff_check
                            flush_bitStuffCheck = 1;
                        end else begin
                            can_hi_out = !message[(msg_length-1) - bits_transmitted];    
                            can_lo_out = !can_hi_out;
                            flush_bitStuffCheck = 0;
                        end
                    end else begin
                        can_hi_out = !message[(msg_length-1) - bits_transmitted];    
                        can_lo_out = !can_hi_out;
                    end
                 
                    bit_stuff_check = {bit_stuff_check, can_hi_out};
                end
               
                if(flush_bitStuffCheck)
                    bit_stuff_check <= 5'b00001;
                else
                    bits_transmitted_next = bits_transmitted + 32'b1;
        
                // While sending id/start bit, set id_transmit flag hi    
                if(bits_transmitted < 13) 
                    id_transmit_flag <= 1;
                else
                    id_transmit_flag <= 0;

                if(bits_transmitted < msg_length) begin
                    next_state <= SENDING;
                end else begin 
                    if(bits_transmitted == 32'h7FFFFFFF) 
                        // lower priority, kicked off bus
                        next_state <= WAIT;
                    else
                        // this node was bus master and finished transmission. 
                        next_state <= PROCESS;
                end
            end

            WAIT: begin    // WAIT RX 
                can_hi_out <= 0;
                can_lo_out <= 1;
                // Check for end of frame
                if( (received_msg[6:0] != 7'h7F) || (bits_received < msg_length_base) ) begin
                    next_state <= WAIT;
                end else begin
                    next_state <= PROCESS;
                end
            end    

            PROCESS: begin    // PROCESS
                bit_stuff_check = 5'b00001;
                added_bits = 0;
                for(i=127; i>=0; i=i-1) begin
                    if(i<=25 || i > bits_received) begin
                        scrubbed_msg_in = {scrubbed_msg_in, received_msg[i]};
                    end else begin  
                        if( ((bit_stuff_check == 5'b00) ) ||
                            ((bit_stuff_check == 5'h1F) )
                        ) begin
                            flush_bitStuffCheck = 1;
                            added_bits = added_bits + 1;
                            scrubbed_msg_in = {1'b0, scrubbed_msg_in};
                        end else begin
                            scrubbed_msg_in = {scrubbed_msg_in, received_msg[i]};
                            flush_bitStuffCheck = 0;
                        end

                        if(flush_bitStuffCheck) 
                            bit_stuff_check = 5'b00001;
                        else
                            bit_stuff_check = {bit_stuff_check, received_msg[i]};
                    end
                end

                $display("NODE: %d, Received message: %x",node_num, scrubbed_msg_in);
                $display("NODE: %d, RM: %b", node_num, received_msg);
                $display("NODE: %d, RM: %b", node_num, scrubbed_msg_in);

                /* Process */
                for(i=0; i<id_table_len; i=i+1) begin
                    //msg_id = received_msg[((bits_received - added_bits))-:11];
                    msg_id = received_msg >> ((bits_received - added_bits) - 11);
                    msg_id = msg_id & 12'h7FF;
                    msg_src = received_msg >> 8;
                    $display("NODE: %d, msg_id in: %x, id_table[%d] slice: %x, src: %d",node_num, msg_id, i, id_table[i][26-:11],msg_src);
                    if(msg_id == id_table[i][26-:11])  begin
                        if(msg_src == (id_table[i] & 27'h000FFFF)) begin 
                            //i = id_table_len;
                            $display("NODE: %d, valid id! %x, src: %d",node_num,msg_id,msg_src);
                        end
                    end
                end            
    
                next_state <= 0;
            end
            
            default: 
                next_state <= 0;
        endcase   
        led0 = state[0];
        led1 = state[1];
    end
 
    // Check to see if message id lower priority 
    // and fill receive buffer
    always@(negedge can_clk) begin
        if(can_hi_out !== can_hi_in && id_transmit_flag) begin
            lower_priority <= 1; 
        end else begin
            lower_priority <= 0;
        end

        if(receive_rst) begin
            received_msg = 128'b0;
            bits_received_next = 0;
        end else begin
            received_msg = {received_msg, can_lo_in};
            bits_received_next = bits_received + 32'b1;
        end
        $display("NODE: %d, State: %d, CANout: (%d, %d), CANin: (%d, %d), RM: %b (BR: %d)",
                    node_num, state, can_hi_out, can_lo_out, can_hi_in, can_lo_in, received_msg[61:0],bits_received);
    end
 
    always@(posedge can_clk) begin
        if (reset) 
            state <= 0;
        else
            state <= next_state;
        toggle <= ~toggle;
        bits_transmitted <= bits_transmitted_next;
        bits_received <= bits_received_next;
    end
endmodule


