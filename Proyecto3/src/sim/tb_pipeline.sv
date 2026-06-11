`timescale 1ns/1ps

module tb_pipeline;

    // =========================================================================
    // Parámetros
    // =========================================================================
    localparam CLK_PERIOD  = 10;   // 10 ns → 100 MHz
    localparam PIPE_STAGES = 4;    // Latencia del pipeline

    // =========================================================================
    // Señales del DUT
    // =========================================================================
    logic        clk;
    logic        rst_n;
    logic        valid;
    logic [6:0]  A;       // Dividendo (7 bits, máx 127)
    logic [4:0]  B;       // Divisor  (5 bits, máx 31)
    logic [6:0]  Q;       // Cociente
    logic [4:0]  R;       // Residuo
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
    // Estructura para casos de prueba
    // =========================================================================
    typedef struct {
        logic [6:0] dividendo;
        logic [4:0] divisor;
        logic [6:0] cociente_esp;
        logic [4:0] residuo_esp;
        string      descripcion;
    } test_case_t;

    // =========================================================================
    // Definición de casos de prueba
    // =========================================================================
    // Se cubren: divisiones exactas, con residuo, cero, divisor mayor,
    // valores máximos y mínimos, y potencias de 2.
    // =========================================================================
    localparam int NUM_TESTS = 6;

    test_case_t casos[NUM_TESTS] = '{
        // dividendo, divisor, cociente_esp, residuo_esp, descripción
        '{7'd20,  5'd4,  7'd5,  5'd0,  "División exacta simple"},
        '{7'd20,  5'd3,  7'd6,  5'd2,  "División con residuo"},
        '{7'd0,   5'd7,  7'd0,  5'd0,  "Dividendo = 0"},
        '{7'd7,   5'd1,  7'd7,  5'd0,  "Divisor = 1"},
        '{7'd5,   5'd31, 7'd0,  5'd5,  "Divisor > dividendo"},
        '{7'd127, 5'd31, 7'd4,  5'd3,  "Valores máximos (127÷31)"}
    };

    // =========================================================================
    // Variables de seguimiento
    // =========================================================================
    int tests_pasados = 0;
    int tests_fallidos = 0;

    // Cola para rastrear qué caso de prueba corresponde a cada resultado
    // (necesario porque el pipeline introduce 4 ciclos de latencia)
    typedef struct {
        logic [6:0] cociente_esp;
        logic [4:0] residuo_esp;
        string      descripcion;
        int         ciclo_envio;
    } pending_t;

    pending_t cola_pendientes[$];

    // =========================================================================
    // Tarea: aplicar un caso de prueba al DUT
    // =========================================================================
    task automatic aplicar_entrada(input test_case_t tc, input int ciclo_actual);
        @(posedge clk);
        #1; // Pequeño delay para evitar conflictos con el flanco
        A     = tc.dividendo;
        B     = tc.divisor;
        valid = 1'b1;
        cola_pendientes.push_back('{
            cociente_esp: tc.cociente_esp,
            residuo_esp:  tc.residuo_esp,
            descripcion:  tc.descripcion,
            ciclo_envio:  ciclo_actual
        });
        $display("[CICLO %0d] ENTRADA  → A=%0d  B=%0d  | Caso: %s",
                 ciclo_actual, tc.dividendo, tc.divisor, tc.descripcion);
    endtask

    // =========================================================================
    // Tarea: verificar resultado cuando done=1
    // =========================================================================
    task automatic verificar_resultado(input int ciclo_actual);
        pending_t caso;
        caso = cola_pendientes.pop_front();

        if (Q === caso.cociente_esp && R === caso.residuo_esp) begin
            $display("[CICLO %0d] ✓ PASS  → Q=%0d  R=%0d  | %s",
                     ciclo_actual, Q, R, caso.descripcion);
            tests_pasados++;
        end else begin
            $display("[CICLO %0d] ✗ FAIL  → Q=%0d (esp %0d)  R=%0d (esp %0d)  | %s",
                     ciclo_actual, Q, caso.cociente_esp, R, caso.residuo_esp,
                     caso.descripcion);
            tests_fallidos++;
        end
    endtask

    // =========================================================================
    // Flujo principal del testbench
    // =========================================================================
    int ciclo;

    initial begin
        // ------------------------------------------------------------
        // Inicialización
        // ------------------------------------------------------------
        $display("============================================================");
        $display("   TESTBENCH: divider_pipelined (Pipeline de %0d etapas)   ", PIPE_STAGES);
        $display("   Dividendo: 7 bits | Divisor: 5 bits                      ");
        $display("============================================================");

        rst_n = 1'b0;
        valid = 1'b0;
        A     = 7'b0;
        B     = 5'b0;
        ciclo = 0;

        // ------------------------------------------------------------
        // Reset durante 3 ciclos
        // ------------------------------------------------------------
        repeat(3) @(posedge clk);
        #1;
        rst_n = 1'b1;
        $display("\n[CICLO  0] Reset liberado\n");

        // ------------------------------------------------------------
        // FASE 1: Enviar todos los casos de prueba (uno por ciclo)
        // ------------------------------------------------------------
        for (int i = 0; i < NUM_TESTS; i++) begin
            ciclo++;
            aplicar_entrada(casos[i], ciclo);
        end

        // ------------------------------------------------------------
        // Desactivar valid tras el último dato
        // ------------------------------------------------------------
        @(posedge clk);
        #1;
        valid = 1'b0;
        A     = 7'b0;
        B     = 5'b0;
        ciclo++;

        // ------------------------------------------------------------
        // FASE 2: Esperar y capturar resultados cuando done=1
        // Se espera el primer resultado PIPE_STAGES ciclos después
        // del primer dato enviado.
        // ------------------------------------------------------------
        $display("\n--- Esperando resultados del pipeline ---\n");

        // Esperar hasta que llegue el primer done
        // (PIPE_STAGES ciclos después del primer envío)
        repeat(PIPE_STAGES - 1) begin
            @(posedge clk);
            ciclo++;
        end

        // Capturar un resultado por ciclo mientras haya pendientes
        while (cola_pendientes.size() > 0) begin
            @(posedge clk);
            ciclo++;
            if (done) begin
                verificar_resultado(ciclo);
            end else begin
                $display("[CICLO %0d] WARNING: done=0 cuando se esperaba resultado", ciclo);
            end
        end

        // Esperar un ciclo adicional para verificar que done vuelve a 0
        @(posedge clk);
        ciclo++;
        if (!done) begin
            $display("[CICLO %0d] ✓ done=0 correctamente después del último resultado", ciclo);
        end else begin
            $display("[CICLO %0d] ✗ WARN: done=1 sin datos pendientes", ciclo);
        end

        // ------------------------------------------------------------
        // PRUEBA EXTRA: Reset en medio de una operación
        // ------------------------------------------------------------
        $display("\n--- Prueba extra: Reset en medio de operación ---\n");
        @(posedge clk); ciclo++;
        #1;
        A     = 7'd50;
        B     = 5'd5;
        valid = 1'b1;
        $display("[CICLO %0d] Enviando dato y luego reseteando...", ciclo);

        @(posedge clk); ciclo++;
        #1;
        rst_n = 1'b0;  // Reset durante operación
        valid = 1'b0;

        @(posedge clk); ciclo++;
        #1;
        rst_n = 1'b1;
        $display("[CICLO %0d] Reset aplicado y liberado", ciclo);

        // Verificar que Q, R y done son 0 tras reset
        repeat(PIPE_STAGES + 1) @(posedge clk);
        ciclo += PIPE_STAGES + 1;
        if (done === 1'b0 && Q === 7'b0 && R === 5'b0) begin
            $display("[CICLO %0d] ✓ Reset correcto: Q=0, R=0, done=0", ciclo);
            tests_pasados++;
        end else begin
            $display("[CICLO %0d] ✗ Reset fallido: Q=%0d, R=%0d, done=%0b",
                     ciclo, Q, R, done);
            tests_fallidos++;
        end

        // ------------------------------------------------------------
        // Resumen final
        // ------------------------------------------------------------
        $display("\n============================================================");
        $display("   RESUMEN FINAL");
        $display("   Tests pasados : %0d / %0d", tests_pasados, NUM_TESTS + 1); // +1 por prueba de reset
        $display("   Tests fallidos: %0d / %0d", tests_fallidos, NUM_TESTS + 1);
        if (tests_fallidos == 0)
            $display("   *** TODOS LOS TESTS PASARON ✓ ***");
        else
            $display("   *** ATENCIÓN: %0d TEST(S) FALLARON ***", tests_fallidos);
        $display("============================================================\n");

        $finish;
    end

    // =========================================================================
    // Timeout de seguridad (evita simulaciones infinitas)
    // =========================================================================
    initial begin
        #(CLK_PERIOD * 200);
        $display("[ERROR] Timeout: la simulación excedió el tiempo máximo.");
        $finish;
    end

    // =========================================================================
    // Dump de ondas (compatible con VCD estándar)
    // =========================================================================
    initial begin
        $dumpfile("tb_pipeline.vcd");
        $dumpvars(0, tb_pipeline);
    end

endmodule