module top #(
    parameter CICLOS_DEBOUNCE = 270_000,
    parameter CICLOS_BARRIDO  = 27_000
)(
    input  logic       clk,
    input  logic       rst_n,        // activo en bajo
    input  logic [3:0] filas_raw,

    output logic [3:0] columnas,
    output logic [9:0] num1_reg,
    output logic [9:0] num2_reg,
    output logic       datos_listos,

    // SALIDAS PARA SUBSISTEMA 3
    output logic [10:0] suma,
    output logic        suma_ready,
    output logic [7:0] seg_7,
    output logic [3:0] AN
);

    // =========================================================
    // RESET
    // =========================================================
    logic rst;
    assign rst = ~rst_n;

    // =========================================================
    // SEÑALES INTERNAS
    // =========================================================
    logic [3:0] filas_sync;
    logic [3:0] filas_debounced;

    logic [1:0] col_activa;
    logic [3:0] filas_captura;
    logic       dato_valido;

    logic [3:0] tecla;
    logic       tecla_valida;

    logic [9:0] numero1;
    logic [9:0] numero2;

    logic suma_ready_fsm;
    logic [1:0] modo;  // viene de la FSM: 00=A, 01=B, 10=suma

    // Señales internas del subsistema 2
    logic [10:0] suma_internal;
    logic        suma_ready_internal;

    // =========================================================
    // SINCRONIZADOR
    // =========================================================
    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : gen_sync
            sincronizador sync_inst (
                .clk      (clk),
                .async_in (filas_raw[i]),
                .sync_out (filas_sync[i])
            );
        end
    endgenerate

    // =========================================================
    // DEBOUNCE
    // =========================================================
    assign filas_debounced = filas_sync;

    // =========================================================
    // BARRIDO TECLADO
    // =========================================================
    barrido_columnas #(
        .CICLOS_POR_COL(CICLOS_BARRIDO)
    ) barrido_inst (
        .clk          (clk),
        .rst          (rst),
        .filas        (filas_debounced),
        .columnas     (columnas),
        .col_activa   (col_activa),
        .filas_captura(filas_captura),
        .dato_valido  (dato_valido)
    );

    // =========================================================
    // DECODIFICADOR
    // =========================================================
    decodificador_teclado deco_inst (
        .clk          (clk),
        .dato_valido  (dato_valido),
        .col_activa   (col_activa),
        .filas_captura(filas_captura),
        .tecla        (tecla),
        .tecla_valida (tecla_valida)
    );

    // =========================================================
    // FSM TECLADO
    // =========================================================
    fsm_teclado #(
        .CICLOS_BARRIDO(CICLOS_BARRIDO)
    ) fsm_inst (
        .clk         (clk),
        .rst         (rst),
        .tecla_valida(tecla_valida),
        .tecla       (tecla),
        .numero1     (numero1),
        .numero2     (numero2),
        .suma_ready  (suma_ready_fsm),
        .modo        (modo)
    );

    // =========================================================
    // REGISTROS DE SALIDA
    // =========================================================
    registros_salida regs_inst (
        .clk          (clk),
        .rst          (rst),          // ✔ conectado
        .suma_ready   (suma_ready_fsm),
        .numero1      (numero1),
        .numero2      (numero2),
        .num1_reg     (num1_reg),
        .num2_reg     (num2_reg),
        .datos_listos (datos_listos)
    );

    // =========================================================
    // SUBSISTEMA 2 - SUMA
    // =========================================================
    subsistema_suma suma_inst (
        .clk(clk),
        .rst(rst),

        .datos_listos(datos_listos),
        .num1_reg(num1_reg),
        .num2_reg(num2_reg),

        .suma(suma_internal),
        .suma_ready(suma_ready_internal)
    );

    // =========================================================
    // SALIDAS HACIA SUBSISTEMA 3
    // =========================================================
    assign suma       = suma_internal;
    assign suma_ready = suma_ready_internal;




    // =========================================================
    // SUBSISTEMA 3 - DISPLAY 7 SEGMENTOS
    // =========================================================

    // ---------- Señales internas ----------
    logic [1:0]  sel;
    logic [3:0]  dig_in;
    logic [15:0] suma_bcd;
    logic [15:0] num1_bcd;
    logic [15:0] num2_bcd;
    logic [15:0] bcd_activo;   // BCD que se manda al display según modo

    // ---------- Función de conversión BIN → BCD (Double Dabble) ----------
    // Macro local como tarea que se repite para los 3 valores
    function automatic [15:0] bin_to_bcd_11;
        input [10:0] bin;
        integer k;
        reg [15:0] bcd;
        begin
            bcd = 0;
            for (k = 10; k >= 0; k = k - 1) begin
                if (bcd[3:0]   >= 5) bcd[3:0]   = bcd[3:0]   + 3;
                if (bcd[7:4]   >= 5) bcd[7:4]   = bcd[7:4]   + 3;
                if (bcd[11:8]  >= 5) bcd[11:8]  = bcd[11:8]  + 3;
                if (bcd[15:12] >= 5) bcd[15:12] = bcd[15:12] + 3;
                bcd = {bcd[14:0], bin[k]};
            end
            bin_to_bcd_11 = bcd;
        end
    endfunction

    always @(*) begin
        suma_bcd = bin_to_bcd_11(suma_internal);
        num1_bcd = bin_to_bcd_11({1'b0, numero1});  // numero1 es 10 bits
        num2_bcd = bin_to_bcd_11({1'b0, numero2});
    end

    // ---------- Selección de qué mostrar según el modo ----------
    always @(*) begin
        case (modo)
            2'b00:   bcd_activo = num1_bcd;   // ingresando A
            2'b01:   bcd_activo = num2_bcd;   // ingresando B
            2'b10:   bcd_activo = suma_bcd;   // resultado
            default: bcd_activo = num1_bcd;
        endcase
    end

    // ---------- Instancia contador de barrido ----------
    counter scan (
        .clk(clk),
        .rst(rst),
        .sel(sel)
    );

    // ---------- Selector de dígito ----------
    always @(*) begin
        case (sel)
            2'b00: dig_in = bcd_activo[3:0];
            2'b01: dig_in = bcd_activo[7:4];
            2'b10: dig_in = bcd_activo[11:8];
            2'b11: dig_in = bcd_activo[15:12];
        endcase
    end

    // ---------- Decodificador + display ----------
    display_7 disp (
        .clk(clk),
        .sel(sel),
        .dig_in(dig_in),
        .seg_7(seg_7),
        .AN(AN)
    );

endmodule