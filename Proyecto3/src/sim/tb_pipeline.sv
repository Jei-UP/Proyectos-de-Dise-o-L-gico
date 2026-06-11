`timescale 1ns/1ps

module tb_pipeline;

    // =========================================================================
    // Parámetros
    // =========================================================================
    localparam CLK_PERIOD  = 10;
    localparam PIPE_STAGES = 4;
    localparam NUM_TESTS   = 6;

    // =========================================================================
    // Señales del DUT
    // =========================================================================
    logic        clk;
    logic        rst_n;
    logic        valid;
    logic [6:0]  A;
    logic [4:0]  B;
    logic [6:0]  Q;
    logic [4:0]  R;
    logic        done;

    // =========================================================================
    // Instancia del DUT
    // =========================================================================
    divider_pipelined dut (
        .clk   (clk),
        .rst_n (rst_n),
        .valid (valid),
        .A     (A),
        .B     (B),
        .Q     (Q),
        .R     (R),
        .done  (done)
    );

    // =========================================================================
    // Generador de reloj
    // =========================================================================
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // =========================================================================
    // Casos de prueba
    // =========================================================================
    reg [6:0] tc_A [0:NUM_TESTS-1];
    reg [4:0] tc_B [0:NUM_TESTS-1];
    reg [6:0] tc_Q [0:NUM_TESTS-1];
    reg [4:0] tc_R [0:NUM_TESTS-1];

    // =========================================================================
    // Variables de control
    // =========================================================================
    integer tests_pasados;
    integer tests_fallidos;
    integer i;

    // =========================================================================
    // Flujo principal
    // =========================================================================
    initial begin

        // --- Cargar casos de prueba ---
        // Caso 0: División exacta      20 / 4  = 5  R 0
        tc_A[0]=7'd20;  tc_B[0]=5'd4;  tc_Q[0]=7'd5;  tc_R[0]=5'd0;
        // Caso 1: Con residuo          20 / 3  = 6  R 2
        tc_A[1]=7'd20;  tc_B[1]=5'd3;  tc_Q[1]=7'd6;  tc_R[1]=5'd2;
        // Caso 2: Dividendo = 0         0 / 7  = 0  R 0
        tc_A[2]=7'd0;   tc_B[2]=5'd7;  tc_Q[2]=7'd0;  tc_R[2]=5'd0;
        // Caso 3: Divisor = 1           7 / 1  = 7  R 0
        tc_A[3]=7'd7;   tc_B[3]=5'd1;  tc_Q[3]=7'd7;  tc_R[3]=5'd0;
        // Caso 4: Divisor > dividendo   5 / 31 = 0  R 5
        tc_A[4]=7'd5;   tc_B[4]=5'd31; tc_Q[4]=7'd0;  tc_R[4]=5'd5;
        // Caso 5: Valores máximos     127 / 31 = 4  R 3
        tc_A[5]=7'd127; tc_B[5]=5'd31; tc_Q[5]=7'd4;  tc_R[5]=5'd3;

        $display("============================================================");
        $display("  TESTBENCH: tb_pipeline  (Pipeline %0d etapas)", PIPE_STAGES);
        $display("  Dividendo: 7 bits | Divisor: 5 bits");
        $display("============================================================");

        rst_n          = 1'b0;
        valid          = 1'b0;
        A              = 7'b0;
        B              = 5'b0;
        tests_pasados  = 0;
        tests_fallidos = 0;

        // --- Reset 3 ciclos ---
        repeat(3) @(posedge clk);
        #1;
        rst_n = 1'b1;
        $display("\n[INFO] Reset liberado\n");

        // -------------------------------------------------------
        // FASE 1: Enviar los 6 casos uno por ciclo.
        // Las entradas se aplican con #1 DESPUÉS del flanco para
        // que el FF las capture en el SIGUIENTE flanco.
        //
        // Línea de tiempo para caso 0:
        //   flanco C1: aplicamos A,B,valid=1 (con #1 de delay)
        //   flanco C2: FF1 captura → dato en etapa 1
        //   flanco C3: FF2 captura → dato en etapa 2
        //   flanco C4: FF3 captura → dato en etapa 3
        //   flanco C5: FF4 captura → Q,R,done válidos
        // -------------------------------------------------------
        for (i = 0; i < NUM_TESTS; i = i + 1) begin
            @(posedge clk); #1;
            A     = tc_A[i];
            B     = tc_B[i];
            valid = 1'b1;
            $display("[ENTRADA] Caso %0d: A=%0d  B=%0d", i, tc_A[i], tc_B[i]);
        end

        // Desactivar valid en el mismo ciclo que el último dato
        // (no avanzar un ciclo extra para no desincronizar)
        @(posedge clk); #1;
        valid = 1'b0;
        A     = 7'b0;
        B     = 5'b0;

        // -------------------------------------------------------
        // FASE 2: Esperar exactamente PIPE_STAGES-1 ciclos más.
        // Ya avanzamos 1 ciclo al desactivar valid, así que el
        // total desde el último envío será PIPE_STAGES flancos,
        // momento en que done=1 y Q,R son válidos.
        // -------------------------------------------------------
        $display("\n--- Capturando resultados ---\n");
        repeat(PIPE_STAGES - 1) @(posedge clk);

        // -------------------------------------------------------
        // FASE 3: Capturar un resultado por ciclo.
        // Cada caso fue enviado 1 ciclo después del anterior,
        // así que sus resultados también salen 1 ciclo separados.
        // -------------------------------------------------------
        for (i = 0; i < NUM_TESTS; i = i + 1) begin
            // El primer resultado ya está listo (esperamos arriba),
            // los siguientes llegan cada ciclo sucesivo.
            if (i > 0) @(posedge clk);

            if (!done) begin
                $display("[WARN ] Caso %0d: done=0 (latencia incorrecta)", i);
                tests_fallidos = tests_fallidos + 1;
            end else if (Q === tc_Q[i] && R === tc_R[i]) begin
                $display("[PASS ] Caso %0d: A=%0d / B=%0d = Q:%0d R:%0d",
                         i, tc_A[i], tc_B[i], Q, R);
                tests_pasados = tests_pasados + 1;
            end else begin
                $display("[FAIL ] Caso %0d: A=%0d / B=%0d | Q:%0d(esp %0d)  R:%0d(esp %0d)",
                         i, tc_A[i], tc_B[i],
                         Q, tc_Q[i], R, tc_R[i]);
                tests_fallidos = tests_fallidos + 1;
            end
        end

        // -------------------------------------------------------
        // Verificar que done vuelve a 0
        // -------------------------------------------------------
        @(posedge clk);
        if (!done)
            $display("\n[INFO] done=0 correctamente tras ultimo resultado");
        else
            $display("\n[WARN] done=1 inesperado tras ultimos datos");

        // -------------------------------------------------------
        // PRUEBA EXTRA: Reset en medio de operación
        // -------------------------------------------------------
        $display("\n--- Prueba extra: Reset en medio de operacion ---");
        @(posedge clk); #1;
        A     = 7'd50;
        B     = 5'd5;
        valid = 1'b1;
        $display("[INFO] Dato enviado, aplicando reset...");

        @(posedge clk); #1;
        rst_n = 1'b0;
        valid = 1'b0;

        @(posedge clk); #1;
        rst_n = 1'b1;
        $display("[INFO] Reset liberado");

        repeat(PIPE_STAGES + 1) @(posedge clk);

        if (done === 1'b0 && Q === 7'b0 && R === 5'b0) begin
            $display("[PASS ] Reset correcto: Q=0 R=0 done=0");
            tests_pasados = tests_pasados + 1;
        end else begin
            $display("[FAIL ] Reset incorrecto: Q=%0d R=%0d done=%0b", Q, R, done);
            tests_fallidos = tests_fallidos + 1;
        end

        // -------------------------------------------------------
        // Resumen final
        // -------------------------------------------------------
        $display("\n============================================================");
        $display("  RESUMEN FINAL");
        $display("  Tests pasados : %0d / %0d", tests_pasados,  NUM_TESTS + 1);
        $display("  Tests fallidos: %0d / %0d", tests_fallidos, NUM_TESTS + 1);
        if (tests_fallidos == 0)
            $display("  *** TODOS LOS TESTS PASARON ***");
        else
            $display("  *** %0d TEST(S) FALLARON ***", tests_fallidos);
        $display("============================================================\n");

        $finish;
    end

    // =========================================================================
    // Timeout de seguridad
    // =========================================================================
    initial begin
        #(CLK_PERIOD * 200);
        $display("[ERROR] Timeout: simulacion excedio el tiempo maximo.");
        $finish;
    end

    // =========================================================================
    // Dump de ondas
    // =========================================================================
    initial begin
        $dumpfile("tb_pipeline.vcd");
        $dumpvars(0, tb_pipeline);
    end

endmodule