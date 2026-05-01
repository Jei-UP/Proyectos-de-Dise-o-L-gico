module barrido_columnas #(
    parameter CICLOS_POR_COL = 27_000
)(
    input  logic       clk,
    input  logic       rst,
    input  logic [3:0] filas,
    output logic [3:0] columnas,
    output logic [1:0] col_activa,
    output logic [3:0] filas_captura,
    output logic       dato_valido
);

    logic [14:0] contador_tiempo;
    logic [3:0]  anillo;
    logic [3:0]  filas_reg;
    logic [1:0]  col_activa_reg;

    // Decodificación combinacional del anillo (one-hot) a índice (2 bits)
    logic [1:0] col_activa_comb;
    always_comb begin
        case (anillo)
            4'b0001: col_activa_comb = 2'd0;
            4'b0010: col_activa_comb = 2'd1;
            4'b0100: col_activa_comb = 2'd2;
            4'b1000: col_activa_comb = 2'd3;
            default: col_activa_comb = 2'd0;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            anillo          <= 4'b0001;
            contador_tiempo <= '0;
            dato_valido     <= 1'b0;
            filas_reg       <= '0;
            col_activa_reg  <= 2'd0;
        end else begin
            dato_valido <= 1'b0;
            if (contador_tiempo == CICLOS_POR_COL - 1) begin
                contador_tiempo <= '0;
                // Capturar las filas y la columna ACTUAL antes de rotar
                filas_reg       <= filas;
                col_activa_reg  <= col_activa_comb;
                dato_valido     <= |filas;
                // Recién ahora rotar el anillo
                anillo          <= {anillo[2:0], anillo[3]};
            end else begin
                contador_tiempo <= contador_tiempo + 1;
            end
        end
    end

    assign columnas      = anillo;
    assign col_activa    = col_activa_reg;
    assign filas_captura = filas_reg;

endmodule