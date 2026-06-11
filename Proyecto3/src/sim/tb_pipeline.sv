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
    // Casos de prueba: arrays inicializados elemento por elemento
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
    integer idx_resultado;
    integer ciclo;
    integer i;

    // =========================================================================
    // Flujo principal
    // =========================================================================
    initial begin

        // --- Cargar casos de prueba ---
        // Caso 0: División exacta simple      20 / 4  = 5  R 0
        tc_A[0]=7'd20;  tc_B[0]=5'd4;  tc_Q[0]=7'd5;  tc_R[0]=5'd0;
        // Caso 1: División con residuo         20 / 3  = 6  R 2
        tc_A[1]=7'd20;  tc_B[1]=5'd3;  tc_Q[1]=7'd6;  tc_R[1]=5'd2;
        // Caso 2: Dividendo = 0                 0 / 7  = 0  R 0
        tc_A[2]=7'd0;   tc_B[2]=5'd7;  tc_Q[2]=7'd0;  tc_R[2]=5'd0;
        // Caso 3: Divisor = 1                   7 / 1  = 7  R 0
        tc_A[3]=7'd7;   tc_B[3]=5'd1;  tc_Q[3]=7'd7;  tc_R[3]=5'd0;
        // Caso 4: Divisor > dividendo           5 / 31 = 0  R 5
        tc_A[4]=7'd5;   tc_B[4]=5'd31; tc_Q[4]=7'd0;  tc_R[4]=5'd5;
        // Caso 5: Valores máximos             127 / 31 = 4  R 3
        tc_A[5]=7'd127; tc_B[5]=5'd31; tc_Q[5]=7'd4;  tc_R[5]=5'd3;

        $display("============================================================");
        $display("  TESTBENCH: divider_pipelined  (Pipeline %0d etapas)", PIPE_STAGES);
        $display("  Dividendo: 7 bits | Divisor: 5 bits");
        $display("============================================================");

        // --- Inicialización ---
        rst_n          = 1'b0;
        valid          = 1'b0;
        A              = 7'b0;
        B              = 5'b0;
        tests_pasados  = 0;
        tests_fallidos = 0;
        idx_resultado  = 0;
        ciclo          = 0;

        // --- Reset 3 ciclos ---
        repeat(3) @(posedge clk);
        #1;
        rst_n = 1'b1;
        $display("\n[CICLO %0d] Reset liberado\n", ciclo);

        // -------------------------------------------------------
        // FASE 1: Enviar los 6 casos (uno por ciclo)
        // -------------------------------------------------------
        for (i = 0; i < NUM_TESTS; i = i + 1) begin
            @(posedge clk);
            ciclo = ciclo + 1;
            #1;
            A     = tc_A[i];
            B     = tc_B[i];
            valid = 1'b1;
            $display("[CICLO %0d] ENTRADA -> A=%0d  B=%0d  (caso %0d)",
                     ciclo, tc_A[i], tc_B[i], i);
        end

        // Desactivar valid
        @(posedge clk);
        ciclo = ciclo + 1;
        #1;
        valid = 1'b0;
        A     = 7'b0;
        B     = 5'b0;

        // -------------------------------------------------------
        // FASE 2: Esperar primer resultado
        // -------------------------------------------------------
        $display("\n--- Esperando resultados ---\n");
        repeat(PIPE_STAGES - 1) begin
            @(posedge clk);
            ciclo = ciclo + 1;
        end

        // -------------------------------------------------------
        // Capturar un resultado por ciclo
        // -------------------------------------------------------
        while (idx_resultado < NUM_TESTS) begin
            @(posedge clk);
            ciclo = ciclo + 1;

            if (done) begin
                if (Q === tc_Q[idx_resultado] && R === tc_R[idx_resultado]) begin
                    $display("[CICLO %0d] PASS -> A=%0d B=%0d | Q=%0d R=%0d",
                             ciclo,
                             tc_A[idx_resultado], tc_B[idx_resultado],
                             Q, R);
                    tests_pasados = tests_pasados + 1;
                end else begin
                    $display("[CICLO %0d] FAIL -> A=%0d B=%0d | Q=%0d(esp %0d)  R=%0d(esp %0d)",
                             ciclo,
                             tc_A[idx_resultado], tc_B[idx_resultado],
                             Q, tc_Q[idx_resultado],
                             R, tc_R[idx_resultado]);
                    tests_fallidos = tests_fallidos + 1;
                end
                idx_resultado = idx_resultado + 1;
            end else begin
                $display("[CICLO %0d] WARNING: done=0 inesperado", ciclo);
            end
        end

        // -------------------------------------------------------
        // Verificar que done vuelve a 0
        // -------------------------------------------------------
        @(posedge clk);
        ciclo = ciclo + 1;
        if (!done)
            $display("[CICLO %0d] OK: done=0 tras ultimo resultado", ciclo);
        else
            $display("[CICLO %0d] WARN: done=1 sin datos pendientes", ciclo);

        // -------------------------------------------------------
        // PRUEBA EXTRA: Reset en medio de operación
        // -------------------------------------------------------
        $display("\n--- Prueba extra: Reset en medio de operacion ---\n");
        @(posedge clk); ciclo = ciclo + 1;
        #1;
        A     = 7'd50;
        B     = 5'd5;
        valid = 1'b1;
        $display("[CICLO %0d] Enviando dato antes de reset...", ciclo);

        @(posedge clk); ciclo = ciclo + 1;
        #1;
        rst_n = 1'b0;
        valid = 1'b0;

        @(posedge clk); ciclo = ciclo + 1;
        #1;
        rst_n = 1'b1;
        $display("[CICLO %0d] Reset liberado", ciclo);

        repeat(PIPE_STAGES + 1) begin
            @(posedge clk);
            ciclo = ciclo + 1;
        end

        if (done === 1'b0 && Q === 7'b0 && R === 5'b0) begin
            $display("[CICLO %0d] PASS: Reset correcto -> Q=0 R=0 done=0", ciclo);
            tests_pasados = tests_pasados + 1;
        end else begin
            $display("[CICLO %0d] FAIL: Reset incorrecto -> Q=%0d R=%0d done=%0b",
                     ciclo, Q, R, done);
            tests_fallidos = tests_fallidos + 1;
        end

        // -------------------------------------------------------
        // Resumen
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