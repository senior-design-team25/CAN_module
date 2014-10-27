//
// UART interface
//

module uarttx(data, send, ready, tx, clk);

//parameter DIV;

input [7:0] data;
input send;
output ready;
output reg tx;
input clk;

wire fsend;
reg [3:0] state = 0;

assign ready = state == 0;

//flag f(send, fsend, state == 1);

always @(posedge clk) begin
    if (state == 0) begin
        tx <= 1'b1;
        state <= send ? 1 : 0;
    end else begin
        tx <= state == 1 ? 1'b0 : data[state-2];
        state <= state == 9 ? 0 : state + 1;
    end
end

endmodule

/*
module uartrx(data, recv, rx, clk);

parameter DIV;

output reg [7:0] data;
output recv;
input rx;
input clk;

wire uclk;
reg [4:0] state = 0;
reg [7:0] buffer;

div #(DIV/2) (clk, uclk);
pulse (state == 0, recv);

always @(posedge uclk) begin
    if (state == 18) begin
        data <= buffer;
        state <= 0;
    end else if (state == 0) begin
        state <= rx == 1'b0 ? 1 : 0;
    end else if (state[0] == 1'b1) begin
        state <= state + 1;
    end else begin
        buffer[state[4:1]] <= rx;
        state <= state + 1;
    end 
end

endmodule



module uart50tx(data, send, ready, tx, clk);

input [7:0] data;
input send;
output ready;
output tx;
input clk;

uarttx #(434) (data, send, ready, tx, clk);

endmodule


module uart50rx(data, recv, rx, clk);

output [7:0] data;
output recv;
input rx;
input clk;

uartrx #(434) (data, recv, rx, clk);

endmodule
*/