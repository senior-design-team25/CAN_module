// DeBounce_v.v


//////////////////////// Button Debounceer ///////////////////////////////////////
//***********************************************************************
// FileName: DeBounce_v.v
// FPGA: MachXO2 7000HE
// IDE: Diamond 2.0.1 
//
// HDL IS PROVIDED "AS IS." DIGI-KEY EXPRESSLY DISCLAIMS ANY
// WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
// BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
// DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
// PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
// BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
// ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
// DIGI-KEY ALSO DISCLAIMS ANY LIABILITY FOR PATENT OR COPYRIGHT
// INFRINGEMENT.
//
// Version History
// Version 1.0 04/11/2013 Tony Storey
// Initial Public Release
// Small Footprint Button Debouncer

//`timescale 1 ns / 100 ps

module debounce(clk, reset, sig_in, db_out);
    input clk, reset, sig_in;
    output reg db_out;
    
    // 100Mhz crystal 
    reg[26:0] counter = 0;  // 2^27 = ~133,000,000
    reg running = 0;
    reg orig_input;
    
    parameter delay = 1000000;

    always@(sig_in) begin
        if(!running) begin
            //running = 1'b1;
            counter = 0;
            orig_input = sig_in;
        end
    end
    
    always@(posedge clk) begin
		if(running)
        	counter = counter + 1;
        if(counter == 0) 
            running = 1'b1;
        if(counter == delay) begin
            running = 1'b0;
            db_out = sig_in;
        end
		//$display("sig_in: %d (latchd: %d), running: %d. Counter: %d",sig_in, orig_input, running, counter);
    end
endmodule
