

// Modulo: registros_salida.sv
// Descripción: Este módulo almacena los números de entrada cuando la suma está lista 
// y genera una señal de datos_listos para indicar que los datos están disponibles para su uso en otros módulos.
module registros_salida (
    input  logic        clk,
    input  logic        rst,

    input  logic        suma_ready,
    input  logic [9:0]  numero1,
    input  logic [9:0]  numero2,

    output logic [9:0]  num1_reg,
    output logic [9:0]  num2_reg,
    output logic        datos_listos
);

    always_ff @(posedge clk) begin

        if (rst) begin
            num1_reg     <= 0;
            num2_reg     <= 0;
            datos_listos <= 0;
        end
        else begin

            datos_listos <= 1'b0;

            if (suma_ready) begin
                num1_reg     <= numero1;
                num2_reg     <= numero2;
                datos_listos <= 1'b1;
            end

        end
    end

endmodule