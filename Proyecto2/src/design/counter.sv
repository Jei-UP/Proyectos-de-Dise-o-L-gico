module counter (
    input wire clk,
    output reg [1:0] sel = 0
);

    reg [14:0] clk_div = 0;

    always @(posedge clk) begin

        if (clk_div == 27000) begin
            clk_div <= 0;
            sel <= sel + 1;
        end
        else begin
            clk_div <= clk_div + 1;
        end

    end

endmodule