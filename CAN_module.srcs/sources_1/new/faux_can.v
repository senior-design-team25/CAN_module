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
//(╯°□°）╯︵ ┻�?┻

module faux_can(
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
        bits_sent,
        state_out,
        message_out,
        cmd_in,
        cmd_in_ready,
        cmd_awk,
        pwm_out
    );
    input can_clk, sys_clk, reset, can_lo_in, can_hi_in, cmd_in_ready;
    input wire[3:0] node_num;
    input wire[31:0] cmd_in;
    output reg can_lo_out, can_hi_out;
    output wire[5:0] bits_sent;
    output wire led0, led1;
    output reg cmd_awk;
    output wire[2:0] state_out;
    output reg[127:0] message_out;
    output wire pwm_out;

    assign bits_sent[5:0] = bits_received[5:0];
    assign state_out = state;
    reg[7:0] test = 8'h00;
    assign led0 = (test == 8'h67);
    assign led1 = receive_rst;
    
    reg[7:0] duty;
    servo_pwm pwm(sys_clk, duty, pwm_out);
/*************************************************************************
*   State machine constants
**************************************************************************/
    /* 4 states for CAN node:
    *   1. Idle  
    *   2. Sending
    *   3. Wait Rx
    *   4. Process
    */
    parameter IDLE = 3'b000;
    parameter SENDING = 3'b001;
    parameter WAIT = 3'b010;
    parameter PROCESS = 3'b011;

/*************************************************************************
*   CMD paramters
**************************************************************************/
    wire[7:0] CMD_CAR;
    wire[7:0] CMD_DEVICE;
    wire[7:0] CMD_DATA;
    wire[7:0] CMD_CHECKSUM;
    parameter DEVICE_OFFSET = 8;
    parameter DATA_OFFSET = 16;
    parameter CHECKSUM_OFFSET = 24;
    assign CMD_DEVICE = cmd_in[(31-(DEVICE_OFFSET)) -: 8];
    assign CMD_DATA = cmd_in[(31-(DATA_OFFSET)) -: 8];
    assign CMD_CHECKSUM = cmd_in[(31-(CHECKSUM_OFFSET)) -: 8];

    //
    //  Command Formats
    //
    parameter CLOSE_BRAKE = "c";
    parameter OPEN_BRAKE = "o";
    parameter SET_MOTOR = "s"; 

/*************************************************************************
*   CMD to node ID lookup table
**************************************************************************/
    parameter BRAKES = "b";     // 0x62
    parameter MOTORS = "m";     // 0x6D  ┌∩�?(◣_◢)┌∩�?)
    parameter CAN_BRAKES_ID = 11'h008;
    parameter CAN_MOTOR_ID = 11'h070;

/*************************************************************************
*   CAN frame components
**************************************************************************/
    reg[2:0] state, next_state = 3'b0;
    reg toggle = 0;
    reg [10:0] node_id;
    reg id_transmit_flag = 0;
    reg lower_priority = 0;
    reg[31:0] bits_transmitted = 32'd0;
    reg[31:0] bits_transmitted_next = 32'd0;
    reg[31:0] bits_received = 32'd0;
    reg[31:0] bits_received_next =32'd 0;
    reg[127:0] message = 128'd0; 
    reg[63:0] header = 64'd0;
    
    reg[127:0] received_msg = 128'd0;
    reg[127:0] scrubbed_msg_in = 128'd0;
    reg receive_rst = 1'b0;
    
    reg[10:0] message_id = 11'd0;
    reg[3:0] data_length = 4'b0001;
    reg[7:0] data[7:0];
    reg[14:0] CRC = 15'h4444;
    
    parameter EOF = 7'h7F;
    // Extended format versus standard format base length
    parameter msg_length_base = (43);  
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
    reg slave = 0;
    reg[7:0] added_bits = 0;
    reg[3:0] msg_src = 0;
    
    reg[10:0] id_in = 11'h000;
    reg[3:0] data_len_in = 4'h0;
    reg[2:0] data_in_count = 3'h0;
    reg[3:0] data_bits_in = 4'h0;
    reg[7:0] data_in[7:0];
    reg[2:0] run_iteration = 3'h0;

/*************************************************************************
*   CAN security components
**************************************************************************/
//    reg[26:0] id_table [15:0];
//    /*  |___ID___|______SRC______| --> 27 bits */
//    integer ii = 0;
//    parameter id_table_len = 16;

//    initial begin
//        for(ii=0;ii<15; ii=ii+1) begin
//            id_table[ii] <= 27'hx;
//        end        
//    end

//    always@(node_num, state) begin
//        case(node_num)
//            0: begin
//                id_table[0] <= (11'h7FF << 16) | 16'h1;
//                id_table[1] <= (11'h123 << 16) | 16'h2;
//            end
//            1: begin
//                id_table[0] <= (11'h7F8 << 16) | 16'h0;
//                id_table[1] <= (11'h123 << 16) | 16'h2;
//                id_table[2] <= (11'h456 << 16) | 16'h3;
//            end
//            2: begin
//                id_table[0] <= (11'h456 << 16) | 16'h3;
//            end
//            3: begin
//                id_table[0] <= (11'h123 << 16) | 16'h2;
//            end
//        endcase    
//    end    
/*************************************************************************
*   CAN state machine implementation
**************************************************************************/

    always@(state, toggle) begin
        case(state)
            IDLE: begin    // IDLE
                //
                //  Generate message if want to transmit. If no message to send, listen to bus. Else transmit
                //
                bits_transmitted_next = 0;
                scrubbed_msg_in = 0;
                receive_rst <= 1;
                can_hi_out = 0;
                can_lo_out = 1;
                message = 128'd0;
                cmd_awk <= 0;
                slave <= 0;
                if(reset) begin
                    case(node_num)
                        0: begin
                            duty <= 0;
                        end
                        1: begin
                            duty <= 8'h255;
                        end
                        2: begin
                            duty <= 8'h0;
                        end
                    endcase
                end
                 
                //
                //  Perform tablelookup for CMD level device ID to bus ID.
                //  This translation is done for security purposes (embedded node does not 
                //      generate bus ID on its own in case of compromise).
                //  
                node_id <= 0;
                case(node_num)
                    0: begin
                        if(cmd_in_ready) begin
                            data_length <= 1;      
                            data[0] <= CMD_DATA;                         
                                    
                            case(CMD_DEVICE)
                                BRAKES: begin
                                    message_id <= CAN_BRAKES_ID;
                                end
                                MOTORS: begin
                                    message_id <= CAN_MOTOR_ID;
                                end
                                default: begin
                                    message_id <= 11'h7FF;
                                end
                            endcase
                        end else begin
                            message_id <= 11'h7FF;
                            data_length <= 4'd0;
                            data[0] <= 8'h00;
                        end
                    end

                    default: begin
                        case(node_num)
                            1: begin
                                data_length <= 1;
                                data[0] <= 8'h12;
                                message_id <= 11'h100;
                            end
                            2: begin                            
                                data_length <= 1;
                                data[0] <= 8'h34;
                                message_id <= 11'h101;
                            end
                        endcase
                    end
                endcase

//                if(run_iteration > 3'h3) begin
//                    message_id <= 11'h7FF;
//                    message = {1'b0,11'h7FF,2'b00,data_length};
//                    run_iteration <= 3'h0;
//                end else begin
//                    message = {1'b0,message_id,2'b00,data_length};
//                end
                message = {1'b0, message_id,2'b00,data_length};
                msg_length = msg_length_base;
                for(i=0; i < 8; i = i+1) begin
                    if(i < data_length) begin
                        message = {message[119:0],{data[i]}};
                        msg_length = msg_length + 8;    
                    end else begin
                        message = message;
                    end
                end
                message = {message[95:0], CRC, 3'b101, EOF};
                
                $display("NODE: %d, (Message: %x (len: %d))",node_num, message, msg_length);                
                $display("NODE: %d, SM: %b", node_num, message);

                next_state <= SENDING;
            end

            SENDING: begin    // SENDING
                receive_rst <= 0;    
                /* Check transmitted bit with bus
                 * If not equal, lower priority. Kick off bus 
                 * Takes cycle to latch output bit, so check next cycle
                 */
                if( lower_priority ) begin
                     bits_transmitted_next = 32'h7FFFFFFE;
                     next_state <= WAIT;
                     run_iteration <= 3'h0;
                     slave <= 1'b1;
                end else begin
                    /* Dominant = Logic 0 = High voltage
                     * Recessive = Logic 1 = Low voltage
                     * Bit stuffing. Should not bit stuff during CRC and EoF transmission
                     */
                    slave <= 1'b0;
                    can_hi_out = !message[(msg_length-1) - bits_transmitted];    
                    can_lo_out = !can_hi_out; 
               
                    bits_transmitted_next = bits_transmitted + 32'd1;
            
                    // While sending id/start bit, set id_transmit flag hi    
                    if(bits_transmitted < 13) 
                        id_transmit_flag <= 1;
                    else
                        id_transmit_flag <= 0;

                    if(bits_transmitted < msg_length-1) begin
                        next_state <= SENDING;
                    end else begin
                        // this node was bus master and finished transmission. 
                        next_state <= PROCESS;
                        run_iteration <= run_iteration + 1'b1;
                    end
                end
            end

            WAIT: begin    // WAIT RX 
                can_hi_out = 0;
                can_lo_out = 1;
                receive_rst = 0;
                cmd_awk <= 1'b0;
                // Check for end of frame
                if( (received_msg[6:0] != 7'h7F) || (bits_received < msg_length_base) ) begin
                    next_state <= WAIT;
                end else begin
                    next_state <= PROCESS;
                end
            end    
            
            PROCESS: begin
                //
                //  Change to id_in when parsing fully working
                //
                case(node_num)
                    0: begin
                        if(((message_id) == CAN_BRAKES_ID) || ((message_id) == CAN_MOTOR_ID)) 
                            cmd_awk <= 1'b1;
                        else
                            cmd_awk <= 1'b0;
                    end
                    1: begin
                        if(((id_in) == CAN_BRAKES_ID)) 
                            duty <= (data_in[0]);
                        else
                            duty <= duty;
                    end             
                    2: begin
                        if(((id_in) == CAN_MOTOR_ID))
                            duty <= (data_in[0]);
                        else
                            duty <= duty;
                    end
                endcase
                    
                can_hi_out = 0;
                can_lo_out = 1;
                receive_rst = 0;
                next_state <= IDLE;
                message_out = {8'h99,bits_received[7:0],8'h00,5'h00, id_in, 8'h00, 4'h0, data_len_in, 8'h00, data_in[0],40'h12345678FF};
            end
            
            default: 
                next_state <= 0;
        endcase   
    end
 
    // Check to see if message id lower priority 
    // and fill receive buffer
    always@(negedge can_clk) begin
        if((can_hi_out != can_hi_in) && id_transmit_flag) begin
            lower_priority <= 1; 
        end else begin
            lower_priority <= 0;
        end

        //
        //  Parse message
        //
        if(receive_rst) begin
            received_msg = 128'b0;
            bits_received_next = 0;
            data_bits_in = 4'd0;
            data_in_count = 3'd0;
            for(i=0; i<8; i=i+1) 
                data_in[i] = 8'h00;
        end else begin
            received_msg = {received_msg[126:0], can_lo_in};
            if(bits_received > (1-slave) && bits_received < (13-slave)) 
                id_in = {id_in[9:0], can_lo_in};
            // skip two bits between ID and data length
            else if(bits_received > (14-slave) && bits_received < (19-slave))
                data_len_in = {data_len_in[2:0], can_lo_in};
            else if(bits_received > (18-slave) && (bits_received < (19-slave)+(data_len_in * 8))) begin
                data_in[data_in_count] = {data_in[data_in_count][6:0], can_lo_in};
                data_bits_in = data_bits_in + 1;
                if(data_bits_in == 4'h8) begin
                    data_bits_in = 0; 
                    data_in_count = data_in_count + 1;
                end
            end    
                
            bits_received_next = bits_received + 32'b1;
        end 
        $display("NODE: %d, State: %d, CANout: (%d, %d), CANin: (%d, %d), RM: %b (BR: %d)",
                    node_num, state, can_hi_out, can_lo_out, can_hi_in, can_lo_in, received_msg[61:0],bits_received);
    end
 
    always@(posedge can_clk or posedge reset) begin
        if (reset) 
            state <= 0;
        else
            state <= next_state;
        toggle <= ~toggle;
        bits_transmitted <= bits_transmitted_next;
        bits_received <= bits_received_next;
        test = data_in[0];
    end
endmodule
