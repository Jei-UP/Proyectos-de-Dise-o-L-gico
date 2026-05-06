module counter (
    input wire clk,          // 27 MHz
    output reg [1:0] sel     // selección de dígito
);

    reg [14:0] clk_div = 0;
    reg clk_scan = 0;

    // divisor de reloj (~1 kHz)
    always @(posedge clk) begin
        clk_div <= clk_div + 1;
        if (clk_div == 27000) begin
            clk_div <= 0;
            clk_scan <= ~clk_scan;
        end
    end

    // contador MOD-4
    always @(posedge clk_scan) begin
        sel <= sel + 1;
    end

endmodule