`timescale 1ns/1ps

module tb_pipeline;

    // =========================================================================
    // Parámetros
    // =========================================================================
    localparam CLK_PERIOD  = 10;
    localparam PIPE_STAGES = 4;
    localparam NUM_TESTS   = 6;
    // Total de ciclos del loop: NUM_TESTS + PIPE_STAGES burbujas al final
    localparam TOTAL_CICLOS = NUM_TESTS + PIPE_STAGES;

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
        .clk(clk), .rst_n(rst_n), .valid(valid),
        .A(A), .B(B), .Q(Q), .R(R), .done(done)
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

    integer tests_pasados;
    integer tests_fallidos;
    integer ciclo;      // ciclo actual del loop (0 a TOTAL_CICLOS-1)
    integer res_idx;    // índice del resultado a capturar

    // =========================================================================
    // Flujo principal
    // =========================================================================
    initial begin

        // Caso 0: División exacta       20 / 4  = 5  R 0
        tc_A[0]=7'd20;  tc_B[0]=5'd4;  tc_Q[0]=7'd5;  tc_R[0]=5'd0;
        // Caso 1: Con residuo           20 / 3  = 6  R 2
        tc_A[1]=7'd20;  tc_B[1]=5'd3;  tc_Q[1]=7'd6;  tc_R[1]=5'd2;
        // Caso 2: Dividendo = 0          0 / 7  = 0  R 0
        tc_A[2]=7'd0;   tc_B[2]=5'd7;  tc_Q[2]=7'd0;  tc_R[2]=5'd0;
        // Caso 3: Divisor = 1            7 / 1  = 7  R 0
        tc_A[3]=7'd7;   tc_B[3]=5'd1;  tc_Q[3]=7'd7;  tc_R[3]=5'd0;
        // Caso 4: Divisor > dividendo    5 / 31 = 0  R 5
        tc_A[4]=7'd5;   tc_B[4]=5'd31; tc_Q[4]=7'd0;  tc_R[4]=5'd5;
        // Caso 5: Valores máximos      127 / 31 = 4  R 3
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

        // Reset 3 ciclos
        repeat(3) @(posedge clk);
        #1; rst_n = 1'b1;
        $display("\n[INFO] Reset liberado\n");

        // -------------------------------------------------------
        // LOOP ÚNICO: envío y captura solapados
        //
        // En cada ciclo del loop:
        //   - Si ciclo < NUM_TESTS  → aplica entrada del caso [ciclo]
        //   - Si ciclo >= NUM_TESTS → valid=0 (burbujas de drenado)
        //   - Si ciclo >= PIPE_STAGES → captura resultado [ciclo-PIPE_STAGES]
        //
        // Ejemplo con NUM_TESTS=6, PIPE_STAGES=4:
        //   ciclo 0: envía caso 0
        //   ciclo 1: envía caso 1
        //   ciclo 2: envía caso 2
        //   ciclo 3: envía caso 3
        //   ciclo 4: envía caso 4, captura caso 0
        //   ciclo 5: envía caso 5, captura caso 1
        //   ciclo 6: burbuja,      captura caso 2
        //   ciclo 7: burbuja,      captura caso 3
        //   ciclo 8: burbuja,      captura caso 4
        //   ciclo 9: burbuja,      captura caso 5
        // -------------------------------------------------------
        for (ciclo = 0; ciclo < TOTAL_CICLOS; ciclo = ciclo + 1) begin
            @(posedge clk); #1;

            // --- Envío ---
            if (ciclo < NUM_TESTS) begin
                A     = tc_A[ciclo];
                B     = tc_B[ciclo];
                valid = 1'b1;
                $display("[ENTRADA] Caso %0d: A=%0d  B=%0d", ciclo, tc_A[ciclo], tc_B[ciclo]);
            end else begin
                valid = 1'b0;
                A     = 7'b0;
                B     = 5'b0;
            end

            // --- Captura ---
            if (ciclo >= PIPE_STAGES) begin
                res_idx = ciclo - PIPE_STAGES;
                if (!done) begin
                    $display("[WARN ] Caso %0d: done=0 (latencia incorrecta)", res_idx);
                    tests_fallidos = tests_fallidos + 1;
                end else if (Q === tc_Q[res_idx] && R === tc_R[res_idx]) begin
                    $display("[PASS ] Caso %0d: A=%0d / B=%0d = Q:%0d R:%0d",
                             res_idx, tc_A[res_idx], tc_B[res_idx], Q, R);
                    tests_pasados = tests_pasados + 1;
                end else begin
                    $display("[FAIL ] Caso %0d: A=%0d / B=%0d | Q:%0d(esp %0d)  R:%0d(esp %0d)",
                             res_idx, tc_A[res_idx], tc_B[res_idx],
                             Q, tc_Q[res_idx], R, tc_R[res_idx]);
                    tests_fallidos = tests_fallidos + 1;
                end
            end
        end

        // Verificar done=0 tras último resultado
        @(posedge clk);
        if (!done)
            $display("\n[INFO] done=0 correctamente tras ultimo resultado");
        else
            $display("\n[WARN] done=1 inesperado tras ultimos datos");

        // -------------------------------------------------------
        // PRUEBA EXTRA: Reset en medio de operación
        // -------------------------------------------------------
        $display("\n--- Prueba extra: Reset en medio de operacion ---");
        // -------------------------------------------------------
        // PRUEBA EXTRA: Reset en medio de operación
        // -------------------------------------------------------
        $display("\n--- Prueba extra: Reset en medio de operacion ---");

        // Inyectar un dato
        @(posedge clk); #1;
        A     = 7'd50;
        B     = 5'd5;
        valid = 1'b1;

        $display("[INFO] Dato enviado, aplicando reset...");

        // Activar reset asíncrono
        #1;
        rst_n = 1'b0;
        valid = 1'b0;

        // Mantener reset durante 2 ciclos completos
        repeat(2) @(posedge clk);

        // Liberar reset
        #1;
        rst_n = 1'b1;

        $display("[INFO] Reset liberado");

        // Esperar más que la profundidad del pipeline
        repeat(PIPE_STAGES + 2) @(posedge clk);
        #1;

        // Información de depuración
        $display("[DEBUG] Tras reset: Q=%0d R=%0d done=%0b", Q, R, done);

        // Verificación funcional
        if (done === 1'b0) begin
            $display("[PASS ] Reset correcto: no se generaron resultados validos");
            tests_pasados = tests_pasados + 1;
        end else begin
            $display("[FAIL ] Reset incorrecto: done=%0b (debia ser 0)", done);
            tests_fallidos = tests_fallidos + 1;
        end

        // Resumen
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

    // Timeout
    initial begin
        #(CLK_PERIOD * 200);
        $display("[ERROR] Timeout.");
        $finish;
    end

    // Dump de ondas
    initial begin
        $dumpfile("tb_pipeline.vcd");
        $dumpvars(0, tb_pipeline);
    end

endmodule