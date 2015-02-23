module HextoSevenSeg(CLK, BCD, sevenOut, Anode);
input CLK;
input[7:0] BCD;
output[7:0] sevenOut;
output[1:0] Anode;

reg[7:0] display[1:0];

reg[1:0] Anode = 2'b10;
reg[7:0] sevenOut;

  always@(posedge CLK) begin    
    Anode = {Anode[0],Anode[1]};
    case(Anode)
      2'b10: sevenOut = ~display[0];
      2'b01: sevenOut = ~display[1];
		default: sevenOut = 8'b01111111;
    endcase   
  end

/*
    For the Elbert v2 Board --> 
    Bit represents bit in byte:
    [MSB]76543210[LSB]. 
    8'b01100000 = '1'
    Positive logic, 1=on (remove bitnot in always block for negative logic)
    __4__
   |     |
  2|     |5
   |__3__|
   |     |
  1|     |6
   |__0__|  .7   
*/
	always@(BCD) begin
        
		case(BCD[7:4])
          	4'h0: display[1] = 8'b01110111;
			4'h1: display[1] = 8'b01100000;
			4'h2: display[1] = 8'b00111011;
			4'h3: display[1] = 8'b01111001;
			4'h4: display[1] = 8'b01101100;
			4'h5: display[1] = 8'b01011101;
			4'h6: display[1] = 8'b01011111;
			4'h7: display[1] = 8'b01110000;
			4'h8: display[1] = 8'b01111111;
			4'h9: display[1] = 8'b01111100;
			4'hA: display[1] = 8'b01111110;
			4'hB: display[1] = 8'b01001111;
			4'hC: display[1] = 8'b00010111;
			4'hD: display[1] = 8'b01101011;
			4'hE: display[1] = 8'b00011111;
			4'hF: display[1] = 8'b00011110;
			default: display[1] = 8'b11111111;
		endcase
		case(BCD[3:0])
        	4'h0: display[0] = 8'b01110111;
			4'h1: display[0] = 8'b01100000;
			4'h2: display[0] = 8'b00111011;
			4'h3: display[0] = 8'b01111001;
			4'h4: display[0] = 8'b01101100;
			4'h5: display[0] = 8'b01011101;
			4'h6: display[0] = 8'b01011111;
			4'h7: display[0] = 8'b01110000;
			4'h8: display[0] = 8'b01111111;
			4'h9: display[0] = 8'b01111100;
            4'hA: display[0] = 8'b01111110;
			4'hB: display[0] = 8'b01001111;
			4'hC: display[0] = 8'b00010111;
			4'hD: display[0] = 8'b01101011;
			4'hE: display[0] = 8'b00011111;
			4'hF: display[0] = 8'b00011110;
			default: display[0] = 8'b11111111;
		endcase
	end
endmodule