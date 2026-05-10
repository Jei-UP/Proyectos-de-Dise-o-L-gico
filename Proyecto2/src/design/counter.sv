module counter (
    input  wire        clk,
    input  wire        rst,
    output reg  [1:0]  sel
);

    reg [16:0] clk_div;  // más bits para mayor rango

    always @(posedge clk) begin
        if (rst) begin
            clk_div <= 0;
            sel     <= 0;
        end else begin
            if (clk_div >= 17'd67500) begin  // ~2.5ms por dígito @ 27MHz
                clk_div <= 0;
                sel     <= sel + 1;
            end else begin
                clk_div <= clk_div + 1;
            end
        end
    end

endmodule