module registros_salida (
    input  logic        clk,
    input  logic        suma_ready,   // pulso de la FSM
    input  logic [9:0]  numero1,      // número 1 de la FSM
    input  logic [9:0]  numero2,      // número 2 de la FSM
    output logic [9:0]  num1_reg,     // número 1 congelado para subsistema 2
    output logic [9:0]  num2_reg,     // número 2 congelado para subsistema 2
    output logic        datos_listos  // indica al subsistema 2 que hay datos nuevos
);

    always_ff @(posedge clk) begin

        datos_listos <= 1'b0;  // por defecto apagado

        if (suma_ready) begin
            num1_reg     <= numero1;
            num2_reg     <= numero2;
            datos_listos <= 1'b1;  // pulso de 1 ciclo para el subsistema 2
        end

    end

endmodule