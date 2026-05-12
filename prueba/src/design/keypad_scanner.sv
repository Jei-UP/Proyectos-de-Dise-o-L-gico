

module keypad_scanner (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [3:0] filas_raw,
    output logic [3:0] columnas,  //activa una columna a la vez con el one hot
    output logic [3:0] key_code,
    output logic       key_valid    // pulso de 1 ciclo en tecla validada
);

    // -------------------------------------------------------------------------
    // Parametros de temporizacion (clk = 27 MHz)
    // -------------------------------------------------------------------------
    localparam int CNT_W        = 20;
    localparam int COL_HOLD_CYC = 27_000;   // ~1 ms por columna
    localparam int DEBOUNCE_CYC = 540_000;  // ~20 ms antirrebote

    // -------------------------------------------------------------------------
    // Sincronizacion de las filas (2 FF para evitar metaestabilidad)
    // -------------------------------------------------------------------------
    logic [3:0] filas_meta, filas_sync;
    always_ff @(posedge clk or negedge rst_n) begin   
        if (!rst_n) begin
            filas_meta <= 4'b0000;
            filas_sync <= 4'b0000;
        end else begin
            filas_meta <= filas_raw;
            filas_sync <= filas_meta;   // filas_sync es la version sincronizada y estable de las filas
        end
    end

    // -------------------------------------------------------------------------
    // Estados de la FSM
    // -------------------------------------------------------------------------
    typedef enum logic [1:0] {
        SCAN,
        DEBOUNCE_PRESS,
        WAIT_RELEASE,
        DEBOUNCE_RELEASE
    } state_t;

    state_t           state;
    logic [1:0]       col_idx;
    logic [CNT_W-1:0] counter;
    logic [3:0]       captured_key;

    // -------------------------------------------------------------------------
    // Manejo de columnas: one-hot activo ALTO segun col_idx
    // -------------------------------------------------------------------------
    always_comb begin
        case (col_idx)
            2'd0:    columnas = 4'b0001;
            2'd1:    columnas = 4'b0010;
            2'd2:    columnas = 4'b0100;
            2'd3:    columnas = 4'b1000;
            default: columnas = 4'b0001;
        endcase
    end

    // -------------------------------------------------------------------------
    // Funcion de decodificacion (col, fila) -> codigo hexadecimal de la tecla
    // -------------------------------------------------------------------------
    function automatic logic [3:0] decode_key(input logic [1:0] col,
                                              input logic [3:0] rows);
        decode_key = 4'h0;
        if (rows[0]) begin
            case (col)
                2'd0: decode_key = 4'h1;
                2'd1: decode_key = 4'h2;
                2'd2: decode_key = 4'h3;
                2'd3: decode_key = 4'hA;
            endcase
        end else if (rows[1]) begin
            case (col)
                2'd0: decode_key = 4'h4;
                2'd1: decode_key = 4'h5;
                2'd2: decode_key = 4'h6;
                2'd3: decode_key = 4'hB;
            endcase
        end else if (rows[2]) begin
            case (col)
                2'd0: decode_key = 4'h7;
                2'd1: decode_key = 4'h8;
                2'd2: decode_key = 4'h9;
                2'd3: decode_key = 4'hC;
            endcase
        end else if (rows[3]) begin
            case (col)
                2'd0: decode_key = 4'hE;  // '*'
                2'd1: decode_key = 4'h0;
                2'd2: decode_key = 4'hF;  // '#'
                2'd3: decode_key = 4'hD;
            endcase
        end
    endfunction

    // -------------------------------------------------------------------------
    // FSM principal
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= SCAN;
            col_idx      <= 2'd0;
            counter      <= '0;
            captured_key <= 4'h0;
            key_code     <= 4'h0;
            key_valid    <= 1'b0;
        end else begin
            key_valid <= 1'b0;  // por defecto, sin pulso

            case (state)
                // ---------------------------------------------------------
                SCAN: begin
                    if (|filas_sync) begin
                        // Hay alguna fila activa: capturar y entrar a debounce
                        captured_key <= decode_key(col_idx, filas_sync);
                        counter      <= '0;
                        state        <= DEBOUNCE_PRESS;
                    end else if (counter >= CNT_W'(COL_HOLD_CYC - 1)) begin
                        counter <= '0;
                        col_idx <= col_idx + 2'd1;
                    end else begin
                        counter <= counter + 1'b1;
                    end
                end

                // ---------------------------------------------------------
                DEBOUNCE_PRESS: begin
                    if (counter >= CNT_W'(DEBOUNCE_CYC - 1)) begin
                        // Pasados los 20 ms, verifico que la misma tecla
                        // siga presionada
                        if ((|filas_sync) &&
                            (decode_key(col_idx, filas_sync) == captured_key)) begin
                            key_code  <= captured_key;
                            key_valid <= 1'b1;        // PULSO DE TECLA VALIDA
                            counter   <= '0;
                            state     <= WAIT_RELEASE;
                        end else begin
                            // Falsa alarma o rebote: regresar a escaneo
                            counter <= '0;
                            state   <= SCAN;
                        end
                    end else begin
                        counter <= counter + 1'b1;
                    end
                end

                // ---------------------------------------------------------
                WAIT_RELEASE: begin
                    if (!(|filas_sync)) begin
                        counter <= '0;
                        state   <= DEBOUNCE_RELEASE;
                    end
                end

                // ---------------------------------------------------------
                DEBOUNCE_RELEASE: begin
                    if (|filas_sync) begin
                        // Rebote: la tecla volvio a aparecer
                        counter <= '0;
                        state   <= WAIT_RELEASE;
                    end else if (counter >= CNT_W'(DEBOUNCE_CYC - 1)) begin
                        counter <= '0;
                        state   <= SCAN;
                    end else begin
                        counter <= counter + 1'b1;
                    end
                end

                // ---------------------------------------------------------
                default: state <= SCAN;
            endcase
        end
    end

endmodule