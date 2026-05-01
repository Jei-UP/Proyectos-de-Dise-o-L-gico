module top #(
    parameter CICLOS_DEBOUNCE = 270_000,
    parameter CICLOS_BARRIDO  = 27_000
)(
    input  logic       clk,
    input  logic       rst,
    input  logic [3:0] filas_raw,
    output logic [3:0] columnas,
    output logic [9:0] num1_reg,
    output logic [9:0] num2_reg,
    output logic       datos_listos
);

    // PASO 3 — sincronizador
    logic [3:0] filas_sync;

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

    // PASO 4 — debounce
    logic [3:0] filas_debounced;

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

    // PASO 5 — barrido de columnas
    logic [1:0] col_activa;
    logic [3:0] filas_captura;
    logic       dato_valido;

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

    // PASO 6 — decodificador
    logic [3:0] tecla;
    logic       tecla_valida;

    decodificador_teclado deco_inst (
        .clk          (clk),
        .dato_valido  (dato_valido),
        .col_activa   (col_activa),
        .filas_captura(filas_captura),
        .tecla        (tecla),
        .tecla_valida (tecla_valida)
    );

    // PASO 7 — FSM
    logic [9:0] numero1;
    logic [9:0] numero2;
    logic       suma_ready;

    fsm_teclado fsm_inst (
        .clk         (clk),
        .rst         (rst),
        .tecla_valida(tecla_valida),
        .tecla       (tecla),
        .numero1     (numero1),
        .numero2     (numero2),
        .suma_ready  (suma_ready)
    );

    // PASO 8 — registros de salida
    registros_salida regs_inst (
        .clk         (clk),
        .suma_ready  (suma_ready),
        .numero1     (numero1),
        .numero2     (numero2),
        .num1_reg    (num1_reg),
        .num2_reg    (num2_reg),
        .datos_listos(datos_listos)
    );

endmodule