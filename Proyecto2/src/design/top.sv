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
    output logic       datos_listos
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

    // SALIDA DEL SUBSISTEMA 2
    logic [10:0] suma;
    logic suma_ready_sum;

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
    generate
        for (i = 0; i < 4; i++) begin : gen_debounce
            debounce #(
                .LIMITE(CICLOS_DEBOUNCE)
            ) debounce_inst (
                .clk      (clk),
                .rst      (rst),
                .senal_in (filas_sync[i]),
                .senal_out(filas_debounced[i])
            );
        end
    endgenerate

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
        .suma_ready  (suma_ready_fsm)
    );

    // =========================================================
    // REGISTROS DE SALIDA
    // =========================================================
    registros_salida regs_inst (
        .clk          (clk),
        .suma_ready   (suma_ready_fsm),
        .numero1      (numero1),
        .numero2      (numero2),
        .num1_reg     (num1_reg),
        .num2_reg     (num2_reg),
        .datos_listos (datos_listos)
    );

    // =========================================================
    // SUBSISTEMA 2 - SUMA (TU PARTE)
    // =========================================================
    subsistema_suma suma_inst (
        .clk(clk),
        .rst(rst),

        .datos_listos(datos_listos),
        .num1_reg(num1_reg),
        .num2_reg(num2_reg),

        .suma(suma),
        .suma_ready(suma_ready_sum)
    );

endmodule