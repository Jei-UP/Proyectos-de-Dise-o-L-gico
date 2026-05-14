// =============================================================================
// tb_keypad_scanner.sv
// Testbench para keypad_scanner
//
// Pruebas incluidas:
//   1. Reset y estado inicial
//   2. Tecla '5' (col=1, fila=1) – flujo normal con debounce
//   3. Rebote (glitch corto que NO debe generar key_valid)
//   4. Tecla '#' = 4'hF (col=2, fila=3) para verificar otra decodificacion
//
// Nota: los parametros de debounce originales (540 000 ciclos) se sobreescriben
//       via defparam para acelerar la simulacion a 54 ciclos.
// =============================================================================

`timescale 1ns/1ps

module tb_keypad_scanner;

    // -------------------------------------------------------------------------
    // Señales
    // -------------------------------------------------------------------------
    logic       clk;
    logic       rst_n;
    logic [3:0] filas_raw;
    logic [3:0] columnas;
    logic [3:0] key_code;
    logic       key_valid;

    // -------------------------------------------------------------------------
    // DUT – parametros reducidos para simulacion rapida
    // -------------------------------------------------------------------------
    keypad_scanner #() dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .filas_raw (filas_raw),
        .columnas  (columnas),
        .key_code  (key_code),
        .key_valid (key_valid)
    );

    // Reducir contadores internos para acelerar simulacion
    defparam dut.COL_HOLD_CYC = 10;   // 10 ciclos por columna  (era 27 000)
    defparam dut.DEBOUNCE_CYC = 54;   // 54 ciclos de debounce  (era 540 000)

    // -------------------------------------------------------------------------
    // Reloj 27 MHz → periodo ~37 ns
    // -------------------------------------------------------------------------
    localparam real CLK_PERIOD = 37.0;
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // -------------------------------------------------------------------------
    // Utilidades
    // -------------------------------------------------------------------------
    int pass_count = 0;
    int fail_count = 0;

    task automatic check(
        input string   test_name,
        input logic    got_valid,
        input logic    exp_valid,
        input logic [3:0] got_code,
        input logic [3:0] exp_code
    );
        if (got_valid === exp_valid && (exp_valid === 1'b0 || got_code === exp_code)) begin
            $display("[PASS] %s  key_valid=%b  key_code=%0h", test_name, got_valid, got_code);
            pass_count++;
        end else begin
            $display("[FAIL] %s  got valid=%b code=%0h | esperado valid=%b code=%0h",
                     test_name, got_valid, got_code, exp_valid, exp_code);
            fail_count++;
        end
    endtask

    // Esperar N flancos de subida
    task automatic wait_cycles(input int n);
        repeat(n) @(posedge clk);
    endtask

    // Simular una pulsacion completa: presion + debounce + espera + liberacion
    // col_target: columna que el scanner debe estar activando cuando se presiona
    // fila      : mascara one-hot de fila activa
    // exp_code  : codigo esperado
    task automatic press_key(
        input logic [1:0] col_target,
        input logic [3:0] fila,
        input logic [3:0] exp_code,
        input string      label
    );
        // Esperar a que el scanner habilite la columna correcta
        begin : wait_col
            automatic int timeout = 0;
            while (columnas !== (4'b0001 << col_target)) begin
                @(posedge clk);
                timeout++;
                if (timeout > 500) begin
                    $display("[FAIL] %s  Timeout esperando columna %0d", label, col_target);
                    fail_count++;
                    disable wait_col;
                end
            end
        end

        // Activar la fila (tecla presionada)
        filas_raw = fila;

        // Dejar pasar el debounce (54 + margen)
        wait_cycles(80);

        // Capturar key_valid en el siguiente ciclo de reloj
        @(posedge clk);
        check(label, key_valid, 1'b1, key_code, exp_code);

        // Soltar la tecla y esperar debounce de liberacion
        filas_raw = 4'b0000;
        wait_cycles(80);
    endtask

    // -------------------------------------------------------------------------
    // Volcado de formas de onda (VCD)
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("sim/tb_keypad_scanner.vcd");
        $dumpvars(0, tb_keypad_scanner);
    end

    // -------------------------------------------------------------------------
    // Secuencia de pruebas
    // -------------------------------------------------------------------------
    initial begin
        $display("=== TB keypad_scanner ===");

        // -- Reset --
        rst_n    = 0;
        filas_raw = 4'b0000;
        wait_cycles(5);
        rst_n = 1;
        wait_cycles(3);

        // -- Prueba 1: Reset limpio --
        check("1-Reset inicial", key_valid, 1'b0, key_code, 4'h0);

        // -- Prueba 2: Tecla '5'  (col=1, fila[1]=1) --> 4'h5 --
        press_key(2'd1, 4'b0010, 4'h5, "2-Tecla 5");

        // -- Prueba 3: Rebote corto (no debe generar key_valid) --
        // Activamos la fila por solo 5 ciclos (< DEBOUNCE_CYC)
        begin : rebote
            automatic logic key_valid_vio = 0;
            // Esperar columna 0
            wait_cycles(2);
            filas_raw = 4'b0001;  // presion falsa
            wait_cycles(5);       // dura menos que el debounce
            filas_raw = 4'b0000;
            // Monitorear durante el periodo que duraría el debounce
            fork
                begin
                    wait_cycles(60);
                end
                begin
                    @(posedge clk iff key_valid === 1'b1);
                    key_valid_vio = 1;
                end
            join_any
            disable fork;
            if (key_valid_vio)
                $display("[FAIL] 3-Rebote corto  key_valid levantado inesperadamente");
            else begin
                $display("[PASS] 3-Rebote corto  key_valid permaneció en 0 (correcto)");
                pass_count++;
            end
        end

        // -- Prueba 4: Tecla '#' (col=2, fila[3]=1) --> 4'hF --
        press_key(2'd2, 4'b1000, 4'hF, "4-Tecla # (4'hF)");

        // -- Prueba 5: Tecla 'A' (col=3, fila[0]=1) --> 4'hA --
        press_key(2'd3, 4'b0001, 4'hA, "5-Tecla A (4'hA)");

        // -- Resumen --
        $display("-----------------------------------");
        $display("Resultados: %0d PASS  /  %0d FAIL", pass_count, fail_count);
        $display("=== FIN TB keypad_scanner ===");
        $finish;
    end

    // Timeout global de seguridad
    initial begin
        #5_000_000;
        $display("[ERROR] Timeout global de simulacion");
        $finish;
    end

endmodule