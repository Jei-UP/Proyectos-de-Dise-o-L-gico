module decodificador_teclado (
    input  logic       clk,
    input  logic       dato_valido,    // pulso de 1 ciclo del barrido
    input  logic [1:0] col_activa,     // columna activa (0 a 3)
    input  logic [3:0] filas_captura,  // fila activa (one-hot)
    output logic [3:0] tecla,          // valor decodificado (0-9, A-D)
    output logic       tecla_valida    // pulso de 1 ciclo con tecla lista
);

    // índice de fila a partir del one-hot
    logic [1:0] fila_idx;

    always_comb begin
        case (filas_captura)
            4'b0001: fila_idx = 2'd0;
            4'b0010: fila_idx = 2'd1;
            4'b0100: fila_idx = 2'd2;
            4'b1000: fila_idx = 2'd3;
            default: fila_idx = 2'd0;
        endcase
    end

    // tabla de decodificación fila-columna
    // tecla se expresa en valor real (0-15)
    // 10=A, 11=B, 12=C, 13=D, 14=*, 15=#
    always_ff @(posedge clk) begin

        tecla_valida <= 1'b0;  // por defecto apagado

        if (dato_valido && (filas_captura != 4'b0000)) begin

            tecla_valida <= 1'b1;

            case ({fila_idx, col_activa})
                // Fila 0
                4'b00_00: tecla <= 4'd1;
                4'b00_01: tecla <= 4'd2;
                4'b00_10: tecla <= 4'd3;
                4'b00_11: tecla <= 4'd10; // A

                // Fila 1
                4'b01_00: tecla <= 4'd4;
                4'b01_01: tecla <= 4'd5;
                4'b01_10: tecla <= 4'd6;
                4'b01_11: tecla <= 4'd11; // B

                // Fila 2
                4'b10_00: tecla <= 4'd7;
                4'b10_01: tecla <= 4'd8;
                4'b10_10: tecla <= 4'd9;
                4'b10_11: tecla <= 4'd12; // C

                // Fila 3
                4'b11_00: tecla <= 4'd14; // *
                4'b11_01: tecla <= 4'd0;
                4'b11_10: tecla <= 4'd15; // #
                4'b11_11: tecla <= 4'd13; // D

                default:  tecla <= 4'd0;
            endcase

        end
    end

endmodule