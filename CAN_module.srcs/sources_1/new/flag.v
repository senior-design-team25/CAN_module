//
// Setable and resetable flag
//

module flag(in, out, reset);

input in;
output reg out;
input reset;

always @(posedge in or posedge reset) begin
    if (reset) begin
        out <= 1'b0;
    end else begin
        out <= in;
    end
end

endmodule
