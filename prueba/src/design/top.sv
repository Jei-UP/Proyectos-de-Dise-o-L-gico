// =============================================================================
// top.sv - INTEGRACIÓN FINAL (Escaneo y Desplazamiento)
// =============================================================================

module top (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [3:0] filas_raw,
    output logic [3:0] columnas,
    output logic [6:0] seg_7,
    output logic [3:0] AN
);

    // Señales de interconexión
    logic [3:0] key_code;
    logic       key_valid;
    
    // Registros para almacenar los 4 dígitos mostrados (Tipo calculadora)
    logic [3:0] d3, d2, d1, d0;

    // 1. Instancia del Escáner de Teclado
    keypad_scanner u_scanner (
        .clk        (clk),
        .rst_n      (rst_n),
        .filas_raw  (filas_raw),
        .columnas   (columnas),
        .key_code   (key_code),
        .key_valid  (key_valid)
    );

    // 2. Lógica de desplazamiento (Shift Register de 4 niveles)
    // Cuando key_valid da un pulso de un ciclo, los valores rotan hacia la izquierda.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d3 <= 4'h0;
            d2 <= 4'h0;
            d1 <= 4'h0;
            d0 <= 4'h0;
        end else if (key_valid) begin
            d3 <= d2;
            d2 <= d1;
            d1 <= d0;
            d0 <= key_code;
        end
    end

    // 3. Instancia del Display
    seven_seg_display u_display (
        .clk    (clk),
        .rst_n  (rst_n),
        .digit0 (d0),   // Derecha
        .digit1 (d1),
        .digit2 (d2),
        .digit3 (d3),   // Izquierda
        .seg_7  (seg_7),
        .AN     (AN)
    );

endmodule