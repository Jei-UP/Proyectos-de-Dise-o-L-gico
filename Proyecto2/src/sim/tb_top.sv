`timescale 1ns/1ps

// =============================================================================
//  tb_top.sv  —  Testbench completo del sistema
//
//  Escenario:
//    Número 1 : 4 7 2   →  472  (se ingresa dígito a dígito, luego # para confirmar)
//    Número 2 : 3 5 8   →  358  (ídem)
//    Resultado esperado : 472 + 358 = 830
//
//  Flujo del teclado (4x4 matricial, pull-down, activo alto):
//    - columnas es salida de la FPGA  (barrido one-hot)
//    - filas_raw es entrada a la FPGA (la tecla conecta columna → fila)
//    - Para simular una tecla se espera a que la columna correcta esté activa
//      y se fuerza la fila correspondiente en alto durante un período.
//
//  Mapa teclas:
//    fila\col   0     1     2     3
//       0       1     2     3     A
//       1       4     5     6     B
//       2       7     8     9     C
//       3       *     0     #     D
//
//  Parámetros reducidos para simulación:
//    CICLOS_POR_COL = 20  (barrido muy rápido)
//    CICLOS_BARRIDO = 20  (release timer muy corto)
// =============================================================================

module tb_top;

    // =========================================================================
    // PARÁMETROS DE SIMULACIÓN
    // =========================================================================
    localparam CLK_PERIOD     = 10;   // 10 ns → 100 MHz (simulación)
    localparam CICLOS_BARRIDO = 20;   // reducido para sim rápida
    localparam CICLOS_DEBOUNCE= 20;

    // =========================================================================
    // SEÑALES
    // =========================================================================
    logic        clk;
    logic        rst_n;
    logic [3:0]  filas_raw;

    wire  [3:0]  columnas;
    wire  [9:0]  num1_reg;
    wire  [9:0]  num2_reg;
    wire         datos_listos;
    wire  [10:0] suma;
    wire         suma_ready;
    wire  [7:0]  seg_7;
    wire  [3:0]  AN;
    wire  [5:0]  led;

    // =========================================================================
    // DUT
    // =========================================================================
    top #(
        .CICLOS_DEBOUNCE(CICLOS_DEBOUNCE),
        .CICLOS_BARRIDO (CICLOS_BARRIDO)
    ) DUT (
        .clk         (clk),
        .rst_n       (rst_n),
        .filas_raw   (filas_raw),
        .columnas    (columnas),
        .num1_reg    (num1_reg),
        .num2_reg    (num2_reg),
        .datos_listos(datos_listos),
        .suma        (suma),
        .suma_ready  (suma_ready),
        .seg_7       (seg_7),
        .AN          (AN),
        .led         (led)
    );

    // =========================================================================
    // RELOJ
    // =========================================================================
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // =========================================================================
    // TAREA: presionar una tecla
    //   fila_num : 0-3  (fila física del teclado)
    //   col_num  : 0-3  (columna física del teclado)
    //
    //  La tarea espera a que el barrido active la columna correcta,
    //  luego fuerza la fila durante CICLOS_BARRIDO ciclos y la suelta.
    //  Después espera el release timer antes de retornar.
    // =========================================================================
    task automatic presionar_tecla(
        input int fila_num,
        input int col_num,
        input string nombre_tecla
    );
        logic [3:0] col_esperada;
        int         timeout;

        col_esperada = 4'b0001 << col_num;  // one-hot de la columna

        $display("[%0t ns] Presionando tecla '%s' (fila=%0d, col=%0d)",
                 $time, nombre_tecla, fila_num, col_num);

        // Esperar a que el barrido active la columna correcta (con timeout)
        timeout = 0;
        while (columnas !== col_esperada) begin
            @(posedge clk);
            timeout++;
            if (timeout > CICLOS_BARRIDO * 20) begin
                $display("  ERROR: timeout esperando columna %b", col_esperada);
                disable presionar_tecla;
            end
        end

        // Activar la fila (activo alto, pull-down)
        filas_raw[fila_num] = 1'b1;

        // Mantener la tecla presionada durante el tiempo de barrido
        repeat (CICLOS_BARRIDO) @(posedge clk);

        // Soltar la tecla
        filas_raw[fila_num] = 1'b0;

        // Esperar release timer (CICLOS_BARRIDO * 5 + margen)
        repeat (CICLOS_BARRIDO * 6) @(posedge clk);

        $display("[%0t ns]   → tecla '%s' procesada", $time, nombre_tecla);
    endtask

    // =========================================================================
    // TAREA: ingresar un número de 3 dígitos + confirmación (#)
    //   Mapa de teclas:
    //     1→(f0,c0)  2→(f0,c1)  3→(f0,c2)
    //     4→(f1,c0)  5→(f1,c1)  6→(f1,c2)
    //     7→(f2,c0)  8→(f2,c1)  9→(f2,c2)
    //     *→(f3,c0)  0→(f3,c1)  #→(f3,c2)  D→(f3,c3)
    // =========================================================================
    // Tabla fila/columna por dígito
    int fila_de [0:9] = '{3, 0, 0, 0, 1, 1, 1, 2, 2, 2};
    int col_de  [0:9] = '{1, 0, 1, 2, 0, 1, 2, 0, 1, 2};

    task automatic ingresar_numero(
        input int d2,   // centenas
        input int d1,   // decenas
        input int d0,   // unidades
        input string nombre
    );
        int valor;
        valor = d2*100 + d1*10 + d0;
        $display("\n[%0t ns] === Ingresando número %s = %0d%0d%0d (%0d) ===",
                 $time, nombre, d2, d1, d0, valor);

        presionar_tecla(fila_de[d2], col_de[d2], $sformatf("%0d", d2));
        presionar_tecla(fila_de[d1], col_de[d1], $sformatf("%0d", d1));
        presionar_tecla(fila_de[d0], col_de[d0], $sformatf("%0d", d0));

        // Confirmar con #  (fila 3, col 2)
        presionar_tecla(3, 2, "#");
        $display("[%0t ns] === Número %s confirmado ===", $time, nombre);
    endtask

    // =========================================================================
    // TAREA: mostrar estado del display
    // =========================================================================
    task automatic mostrar_display(input string etiqueta);
        $display("\n[%0t ns] --- Display [%s] ---", $time, etiqueta);
        $display("  AN      = %b  (dígito activo: %0d)",
                 AN, AN == 4'b0001 ? 0 :
                     AN == 4'b0010 ? 1 :
                     AN == 4'b0100 ? 2 : 3);
        $display("  seg_7   = %b  (dp g f e d c b a)", seg_7);
        $display("  num1_reg= %0d", num1_reg);
        $display("  num2_reg= %0d", num2_reg);
        $display("  suma    = %0d", suma);
        $display("  LEDs    = %b  (activo bajo)", led);
    endtask

    // =========================================================================
    // MONITOR CONTINUO — imprime cuando cambia algo relevante
    // =========================================================================
    initial begin
        $monitor("[%0t ns] | columnas=%b filas_raw=%b | tecla_v=%b | modo=%b | num1=%0d num2=%0d | suma=%0d suma_rdy=%b",
            $time,
            columnas,
            filas_raw,
            DUT.tecla_valida,
            DUT.modo,
            DUT.numero1,
            DUT.numero2,
            suma,
            suma_ready
        );
    end

    // =========================================================================
    // VOLCADO VCD
    // =========================================================================
    initial begin
        $dumpfile("sim/tb_top.vcd");
        $dumpvars(0, tb_top);
    end

    // =========================================================================
    // ESTÍMULOS PRINCIPALES
    // =========================================================================
    initial begin
        // -----------------------------------------------------------------
        // Reset
        // -----------------------------------------------------------------
        filas_raw = 4'b0000;
        rst_n     = 1'b0;
        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        repeat (5)  @(posedge clk);

        $display("\n========================================================");
        $display(" TESTBENCH: Suma 472 + 358 = 830");
        $display("========================================================\n");

        // -----------------------------------------------------------------
        // FASE 1: Ingresar número 1 = 472
        // -----------------------------------------------------------------
        ingresar_numero(4, 7, 2, "A");

        // Verificar que num1 se capturó
        repeat (10) @(posedge clk);
        mostrar_display("Después de ingresar A=472");

        if (DUT.numero1 == 10'd472)
            $display("  ✅ numero1 = %0d  CORRECTO", DUT.numero1);
        else
            $display("  ❌ numero1 = %0d  ESPERADO 472", DUT.numero1);

        // -----------------------------------------------------------------
        // FASE 2: Ingresar número 2 = 358
        // -----------------------------------------------------------------
        ingresar_numero(3, 5, 8, "B");

        repeat (10) @(posedge clk);
        mostrar_display("Después de ingresar B=358");

        if (DUT.numero2 == 10'd358)
            $display("  ✅ numero2 = %0d  CORRECTO", DUT.numero2);
        else
            $display("  ❌ numero2 = %0d  ESPERADO 358", DUT.numero2);

        // -----------------------------------------------------------------
        // FASE 3: Esperar resultado de la suma
        // -----------------------------------------------------------------
        $display("\n[%0t ns] Esperando suma_ready...", $time);
        wait (suma_ready == 1'b1);
        @(posedge clk);

        mostrar_display("Resultado de la suma");

        if (suma == 11'd830)
            $display("  ✅ suma = %0d  CORRECTO (472 + 358 = 830)", suma);
        else
            $display("  ❌ suma = %0d  ESPERADO 830", suma);

        // -----------------------------------------------------------------
        // FASE 4: Observar display multiplexado por varios ciclos
        // -----------------------------------------------------------------
        $display("\n[%0t ns] Observando display multiplexado (20 ciclos de scan)...", $time);
        repeat (20 * CICLOS_BARRIDO) @(posedge clk);
        mostrar_display("Display estable mostrando suma");

        // -----------------------------------------------------------------
        // FASE 5: Reset y verificar limpieza
        // -----------------------------------------------------------------
        $display("\n[%0t ns] Aplicando reset...", $time);
        rst_n = 1'b0;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (5) @(posedge clk);

        if (DUT.numero1 == 0 && DUT.numero2 == 0)
            $display("  ✅ Reset correcto: numero1=%0d numero2=%0d", DUT.numero1, DUT.numero2);
        else
            $display("  ❌ Reset fallido: numero1=%0d numero2=%0d", DUT.numero1, DUT.numero2);

        // -----------------------------------------------------------------
        // FIN
        // -----------------------------------------------------------------
        $display("\n========================================================");
        $display(" TESTBENCH COMPLETADO");
        $display("========================================================\n");

        #100;
        $finish;
    end

    // =========================================================================
    // TIMEOUT GLOBAL (evita simulación infinita)
    // =========================================================================
    initial begin
        #(CLK_PERIOD * 1_000_000);
        $display("ERROR: Timeout global alcanzado");
        $finish;
    end

endmodule
