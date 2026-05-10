module display_7 (
    input wire clk,
    input wire [1:0] sel,
    input wire [3:0] dig_in,

    output wire [7:0] seg_7, // Salida para los segmentos (a-g + punto)
    output reg  [3:0] AN     // Dígitos activos (multiplexado)
);

    // -------- BCD → 7 segmentos --------
    // Función combinacional para convertir un dígito BCD a su representación en 7 segmentos
    function [7:0] bcd_to_7seg;
        input [3:0] bcd;
        begin
            case (bcd)
                4'd0: bcd_to_7seg = 8'b00111111;
                4'd1: bcd_to_7seg = 8'b00000110;
                4'd2: bcd_to_7seg = 8'b01011011;
                4'd3: bcd_to_7seg = 8'b01001111;
                4'd4: bcd_to_7seg = 8'b01100110;
                4'd5: bcd_to_7seg = 8'b01101101;
                4'd6: bcd_to_7seg = 8'b01111101;
                4'd7: bcd_to_7seg = 8'b00000111;
                4'd8: bcd_to_7seg = 8'b01111111;
                4'd9: bcd_to_7seg = 8'b01101111;
                default: bcd_to_7seg = 8'b00000000;
            endcase
        end
    endfunction

    // -------- registro de salida --------
    // Combinacional para que seg_7 y AN estén siempre sincronizados
    assign seg_7 = bcd_to_7seg(dig_in);

    // -------- activación de dígitos --------
    // Activo en ALTO: el dígito seleccionado recibe 1
    always @(*) begin
        case (sel)
            2'b00: AN = 4'b0001;  // dígito 0 activo
            2'b01: AN = 4'b0010;  // dígito 1 activo
            2'b10: AN = 4'b0100;  // dígito 2 activo
            2'b11: AN = 4'b1000;  // dígito 3 activo
        endcase
    end

endmodule