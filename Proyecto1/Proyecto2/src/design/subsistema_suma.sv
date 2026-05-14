module subsistema_suma (
    input logic clk,
    input logic rst,

    input logic datos_listos,
    input logic [9:0] num1_reg,
    input logic [9:0] num2_reg,

    output logic [10:0] suma,
    output logic suma_ready
);

logic [10:0] suma_reg;

always_ff @(posedge clk) begin
    if (rst) begin
        suma_reg <= 11'd0;
        suma_ready <= 1'b0;
    end else begin
        suma_ready <= 1'b0;

        if (datos_listos) begin
            suma_reg <= num1_reg + num2_reg;
            suma_ready <= 1'b1;
        end
    end
end

assign suma = suma_reg;

endmodule