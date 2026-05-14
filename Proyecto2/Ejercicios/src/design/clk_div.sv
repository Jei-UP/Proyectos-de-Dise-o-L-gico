module clk_div(
    input  wire clk27,
    output reg  clk_out = 0
);

integer count = 0;

// 27 MHz / (2*(6+1)) = 1.928 MHz aprox

always @(posedge clk27) begin
    if(count == 6) begin
        count <= 0;
        clk_out <= ~clk_out;
    end
    else begin
        count <= count + 1;
    end
end

endmodule