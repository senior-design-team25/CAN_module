module complexDivider(clk50Mhz, slowClk, divider); 
input clk50Mhz; //fast clock 
input[31:0] divider;  //rate of new clock
output slowClk; //slow clock 
reg[26:0] counter; 

initial begin 
  counter = 0; 
  slowClk = 0;
end 

reg slowClk;

always @ (posedge clk50Mhz) begin 
	  if(counter == divider) begin 
		 counter <= 1; 
		 slowClk <= ~slowClk;
	  end else begin 
		 counter <= counter + 1;
	  end
	end
endmodule