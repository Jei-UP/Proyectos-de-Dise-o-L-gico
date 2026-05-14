`timescale 1ns / 1ps
module tb_top;

    // =========================================================================
    // Parámetros del reloj del sistema (27 MHz)
    // =========================================================================
    localparam CLK_FREQ_MHZ  = 27;
    localparam T             = 37;   // periodo redondeado en ns (~37.037 ns)

    // =========================================================================
    // Señales internas
    // =========================================================================
    reg        clk;
    reg        rst_n;
    reg  [3:0] filas_raw;
    wire [3:0] columnas;
    wire [6:0] seg_7;
    wire [3:0] AN;

    // =========================================================================
    // Instanciación del DUT
    // =========================================================================
    top DUT (
        .clk      (clk),
        .rst_n    (rst_n),
        .filas_raw(filas_raw),
        .columnas (columnas),
        .seg_7    (seg_7),
        .AN       (AN)
    );

    // =========================================================================
    // Generación del reloj
    // =========================================================================
    always begin
        clk = 1'b0; #(T/2);
        clk = 1'b1; #(T/2);
    end

    // =========================================================================
    // Task: simular la pulsación de una tecla
    //
    // El scanner activa una columna a la vez (one-hot activo ALTO).
    // Se espera a que la columna correcta esté activa, luego se levanta
    // la fila correspondiente durante 40 ms para superar el debounce.
    //
    // col_pattern: máscara one-hot de la columna buscada (ej. 4'b0001 = col 0)
    // row_pattern: máscara one-hot de la fila activa    (ej. 4'b0001 = fila 0)
    // =========================================================================
    task press_key;
        input [3:0] col_pattern;
        input [3:0] row_pattern;
        begin
            @(posedge clk);
            wait (columnas == col_pattern);   // esperar columna correcta
            filas_raw = row_pattern;
            #(40_000_000);                    // mantener 40 ms (supera debounce)
            filas_raw = 4'b0000;
            #(10_000_000);                    // pausa entre teclas
            @(posedge clk);
        end
    endtask

    // =========================================================================
    // Secuencia de verificación
    // =========================================================================
    initial begin
        // Habilitar trazas para GTKWave
        $dumpfile("sim/tb_top.vcd");
        $dumpvars(0, tb_top);

        // Estado inicial
        filas_raw = 4'b0000;
        rst_n     = 1'b1;
        #(T * 10);

        // Reset global
        rst_n = 1'b0;
        #(T * 10);
        rst_n = 1'b1;
        #(T * 10);

        // =====================================================================
        //   PRUEBA 1: 123 + 45 = 168
        //
        //   Mapa del teclado (col activa ALTA, fila activa ALTA):
        //
        //        col0    col1    col2    col3
        //   f0:   1       2       3       A
        //   f1:   4       5       6       B
        //   f2:   7       8       9       C
        //   f3:   *       0       #       D
        // =====================================================================
        $display("=== PRUEBA 1: 123 + 45 = 168 ===");

        // Ingresar primer número: 1 2 3
        // Tecla '1' -> col0 (4'b0001), fila0 (4'b0001)
        press_key(4'b0001, 4'b0001);
        $display("  Digitado: 1");

        // Tecla '2' -> col1 (4'b0010), fila0 (4'b0001)
        press_key(4'b0010, 4'b0001);
        $display("  Digitado: 2");

        // Tecla '3' -> col2 (4'b0100), fila0 (4'b0001)
        press_key(4'b0100, 4'b0001);
        $display("  Digitado: 3");

        // Confirmar primer número con '#' (Enter) -> col2 (4'b0100), fila3 (4'b1000)
        press_key(4'b0100, 4'b1000);
        $display("  Enter (# / paso a N2)");

        // Ingresar segundo número: 4 5
        // Tecla '4' -> col0 (4'b0001), fila1 (4'b0010)
        press_key(4'b0001, 4'b0010);
        $display("  Digitado: 4");

        // Tecla '5' -> col1 (4'b0010), fila1 (4'b0010)
        press_key(4'b0010, 4'b0010);
        $display("  Digitado: 5");

        // Confirmar con '#' y mostrar resultado -> col2 (4'b0100), fila3 (4'b1000)
        press_key(4'b0100, 4'b1000);
        $display("  Enter (# / mostrar suma, deberia ser 168)");

        // Observar resultado en el display
        #(100_000_000);

        // =====================================================================
        //   LIMPIAR con '*' (Reset de la FSM)
        //   Tecla '*' -> col0 (4'b0001), fila3 (4'b1000)
        // =====================================================================
        $display("  Limpiando con '*'");
        press_key(4'b0001, 4'b1000);
        #(50_000_000);

        // =====================================================================
        //   PRUEBA 2: 99 + 99 = 198  (verificar acarreo de centenas)
        // =====================================================================
        $display("=== PRUEBA 2: 99 + 99 = 198 ===");

        // '9' -> col2 (4'b0100), fila2 (4'b0100)
        press_key(4'b0100, 4'b0100);
        $display("  Digitado: 9");
        press_key(4'b0100, 4'b0100);
        $display("  Digitado: 9");

        // '#' para confirmar N1
        press_key(4'b0100, 4'b1000);
        $display("  Enter (paso a N2)");

        press_key(4'b0100, 4'b0100);
        $display("  Digitado: 9");
        press_key(4'b0100, 4'b0100);
        $display("  Digitado: 9");

        // '#' para calcular
        press_key(4'b0100, 4'b1000);
        $display("  Enter (mostrar suma, deberia ser 198)");

        #(100_000_000);

        // =====================================================================
        //   LIMPIAR y FIN
        // =====================================================================
        $display("  Limpiando con '*'");
        press_key(4'b0001, 4'b1000);
        #(50_000_000);

        $display("=== Simulacion terminada ===");
        $finish;
    end

endmodule