module debounce #(
    parameter LIMITE = 270_000
)(
    input  logic clk,
    input  logic rst,
    input  logic senal_in,
    output logic senal_out
);

    logic [17:0] contador;
    logic        estado_actual;

    always_ff @(posedge clk) begin
        if (rst) begin
            contador      <= '0;
            estado_actual <= 1'b0;
        end else begin
            // Si la entrada coincide con el estado estable, no hay cambio:
            // resetear el contador.
            // Si difiere, contar; cuando se sostuvo el cambio LIMITE
            // ciclos, aceptar el nuevo estado.
            if (senal_in == estado_actual) begin
                contador <= '0;
            end else if (contador == LIMITE - 1) begin
                estado_actual <= senal_in;
                contador      <= '0;
            end else begin
                contador <= contador + 1;
            end
        end
    end

    assign senal_out = estado_actual;

endmodule