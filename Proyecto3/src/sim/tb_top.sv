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
        $dumpfile("tb_top.vcd");
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
        //   Mapa del teclado (col activa ALTA, fila activa ALTA):
        //
        //        col0    col1    col2    col3
        //   f0:   1       2       3       A
        //   f1:   4       5       6       B
        //   f2:   7       8       9       C
        //   f3:   *       0       #       D
        // =====================================================================

        // =====================================================================
        //   PRUEBA 1: 140 + 36 = 176
        // =====================================================================
        $display("=== PRUEBA 1: 140 + 36 = 176 ===");

        // Ingresar primer número: 1 4 0
        press_key(4'b0001, 4'b0001);   // '1' -> col0, fila0
        $display("  Digitado: 1");

        press_key(4'b0001, 4'b0010);   // '4' -> col0, fila1
        $display("  Digitado: 4");

        press_key(4'b0010, 4'b1000);   // '0' -> col1, fila3
        $display("  Digitado: 0");

        press_key(4'b0100, 4'b1000);   // '#' -> col2, fila3  (confirmar N1)
        $display("  Enter (# / paso a N2)");

        // Ingresar segundo número: 3 6
        press_key(4'b0100, 4'b0001);   // '3' -> col2, fila0
        $display("  Digitado: 3");

        press_key(4'b0100, 4'b0010);   // '6' -> col2, fila1
        $display("  Digitado: 6");

        press_key(4'b0100, 4'b1000);   // '#' -> col2, fila3  (calcular)
        $display("  Enter (# / mostrar suma, deberia ser 176)");

        #(100_000_000);

        // Limpiar con '*' -> col0, fila3
        $display("  Limpiando con '*'");
        press_key(4'b0001, 4'b1000);
        #(50_000_000);

        // =====================================================================
        //   PRUEBA 2: 561 + 256 = 817
        // =====================================================================
        $display("=== PRUEBA 2: 561 + 256 = 817 ===");

        // Ingresar primer número: 5 6 1
        press_key(4'b0010, 4'b0010);   // '5' -> col1, fila1
        $display("  Digitado: 5");

        press_key(4'b0100, 4'b0010);   // '6' -> col2, fila1
        $display("  Digitado: 6");

        press_key(4'b0001, 4'b0001);   // '1' -> col0, fila0
        $display("  Digitado: 1");

        press_key(4'b0100, 4'b1000);   // '#' -> col2, fila3  (confirmar N1)
        $display("  Enter (# / paso a N2)");

        // Ingresar segundo número: 2 5 6
        press_key(4'b0010, 4'b0001);   // '2' -> col1, fila0
        $display("  Digitado: 2");

        press_key(4'b0010, 4'b0010);   // '5' -> col1, fila1
        $display("  Digitado: 5");

        press_key(4'b0100, 4'b0010);   // '6' -> col2, fila1
        $display("  Digitado: 6");

        press_key(4'b0100, 4'b1000);   // '#' -> col2, fila3  (calcular)
        $display("  Enter (# / mostrar suma, deberia ser 817)");

        #(100_000_000);

        // Limpiar con '*'
        $display("  Limpiando con '*'");
        press_key(4'b0001, 4'b1000);
        #(50_000_000);

        $display("=== Simulacion terminada ===");
        $finish;
    end

endmodule