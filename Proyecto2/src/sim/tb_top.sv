`timescale 1ns/1ps

// =============================================================================
//  tb_top.sv  —  Testbench completo del sistema (compatible Icarus Verilog)
//
//  Escenario:
//    Numero 1 : 4 7 2   ->  472  (digito a digito, luego # para confirmar)
//    Numero 2 : 3 5 8   ->  358  (idem)
//    Resultado esperado : 472 + 358 = 830
//
//  Mapa teclas (fila x columna):
//    fila\col   0     1     2     3
//       0       1     2     3     A
//       1       4     5     6     B
//       2       7     8     9     C
//       3       *     0     #     D
// =============================================================================

module tb_top;

    // =========================================================================
    // PARAMETROS DE SIMULACION
    // =========================================================================
    localparam CLK_PERIOD      = 10;   // 10 ns -> 100 MHz
    localparam CICLOS_BARRIDO  = 20;   // reducido para sim rapida
    localparam CICLOS_DEBOUNCE = 20;

    // =========================================================================
    // SENALES
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
    // TABLA FILA/COLUMNA POR DIGITO
    // Inicializada en procedimiento para compatibilidad con Icarus Verilog
    //   digito:  0  1  2  3  4  5  6  7  8  9
    //   fila:    3  0  0  0  1  1  1  2  2  2
    //   columna: 1  0  1  2  0  1  2  0  1  2
    // =========================================================================
    integer fila_de [0:9];
    integer col_de  [0:9];

    initial begin
        fila_de[0] = 3; fila_de[1] = 0; fila_de[2] = 0; fila_de[3] = 0;
        fila_de[4] = 1; fila_de[5] = 1; fila_de[6] = 1;
        fila_de[7] = 2; fila_de[8] = 2; fila_de[9] = 2;

        col_de[0]  = 1; col_de[1]  = 0; col_de[2]  = 1; col_de[3]  = 2;
        col_de[4]  = 0; col_de[5]  = 1; col_de[6]  = 2;
        col_de[7]  = 0; col_de[8]  = 1; col_de[9]  = 2;
    end

    // =========================================================================
    // TAREA: presionar una tecla
    // =========================================================================
    task automatic presionar_tecla(
        input integer  fila_num,
        input integer  col_num,
        input string   nombre_tecla
    );
        reg   [3:0] col_esperada;
        integer     timeout;

        col_esperada = 4'b0001 << col_num;

        $display("[%0t ns] Presionando '%s' (fila=%0d, col=%0d)",
                 $time, nombre_tecla, fila_num, col_num);

        timeout = 0;
        while (columnas !== col_esperada) begin
            @(posedge clk);
            timeout = timeout + 1;
            if (timeout > CICLOS_BARRIDO * 20) begin
                $display("  ERROR: timeout esperando columna %b", col_esperada);
                disable presionar_tecla;
            end
        end

        filas_raw[fila_num] = 1'b1;
        repeat (CICLOS_BARRIDO) @(posedge clk);
        filas_raw[fila_num] = 1'b0;
        repeat (CICLOS_BARRIDO * 6) @(posedge clk);

        $display("[%0t ns]   -> tecla '%s' procesada", $time, nombre_tecla);
    endtask

    // =========================================================================
    // TAREA: ingresar un numero de 3 digitos + confirmacion con #
    // =========================================================================
    task automatic ingresar_numero(
        input integer d2,
        input integer d1,
        input integer d0,
        input string  nombre
    );
        integer valor;
        valor = d2*100 + d1*10 + d0;

        $display("\n[%0t ns] === Ingresando %s = %0d%0d%0d (%0d) ===",
                 $time, nombre, d2, d1, d0, valor);

        presionar_tecla(fila_de[d2], col_de[d2], $sformatf("%0d", d2));
        presionar_tecla(fila_de[d1], col_de[d1], $sformatf("%0d", d1));
        presionar_tecla(fila_de[d0], col_de[d0], $sformatf("%0d", d0));
        presionar_tecla(3, 2, "#");

        $display("[%0t ns] === %s confirmado ===", $time, nombre);
    endtask

    // =========================================================================
    // TAREA: mostrar estado del display
    // =========================================================================
    task automatic mostrar_display(input string etiqueta);
        integer digito_activo;
        case (AN)
            4'b0001: digito_activo = 0;
            4'b0010: digito_activo = 1;
            4'b0100: digito_activo = 2;
            default: digito_activo = 3;
        endcase
        $display("\n[%0t ns] --- Display [%s] ---", $time, etiqueta);
        $display("  AN       = %b  (digito activo: %0d)", AN, digito_activo);
        $display("  seg_7    = %b  (dp g f e d c b a)", seg_7);
        $display("  num1_reg = %0d", num1_reg);
        $display("  num2_reg = %0d", num2_reg);
        $display("  suma     = %0d", suma);
        $display("  LEDs     = %b  (activo bajo: 0=encendido)", led);
    endtask

    // =========================================================================
    // MONITOR CONTINUO
    // =========================================================================
    initial begin
        $monitor("[%0t ns] col=%b filas=%b | tecla_v=%b modo=%b | n1=%0d n2=%0d | suma=%0d rdy=%b",
            $time, columnas, filas_raw,
            DUT.tecla_valida, DUT.modo,
            DUT.numero1, DUT.numero2,
            suma, suma_ready
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
    // ESTIMULOS PRINCIPALES
    // =========================================================================
    initial begin
        filas_raw = 4'b0000;
        rst_n     = 1'b0;
        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        repeat (5)  @(posedge clk);

        $display("\n========================================================");
        $display(" TESTBENCH: Suma 472 + 358 = 830");
        $display("========================================================");

        // FASE 1: A = 472
        ingresar_numero(4, 7, 2, "A");
        repeat (10) @(posedge clk);
        mostrar_display("Despues de ingresar A=472");
        if (DUT.numero1 == 10'd472)
            $display("  OK: numero1 = %0d  CORRECTO", DUT.numero1);
        else
            $display("  FALLO: numero1 = %0d  ESPERADO 472", DUT.numero1);

        // FASE 2: B = 358
        ingresar_numero(3, 5, 8, "B");
        repeat (10) @(posedge clk);
        mostrar_display("Despues de ingresar B=358");
        if (DUT.numero2 == 10'd358)
            $display("  OK: numero2 = %0d  CORRECTO", DUT.numero2);
        else
            $display("  FALLO: numero2 = %0d  ESPERADO 358", DUT.numero2);

        // FASE 3: Esperar suma
        $display("\n[%0t ns] Esperando suma_ready...", $time);
        wait (suma_ready == 1'b1);
        @(posedge clk);
        mostrar_display("Resultado de la suma");
        if (suma == 11'd830)
            $display("  OK: suma = %0d  CORRECTO (472 + 358 = 830)", suma);
        else
            $display("  FALLO: suma = %0d  ESPERADO 830", suma);

        // FASE 4: Display multiplexado
        $display("\n[%0t ns] Observando display (20 ciclos de scan)...", $time);
        repeat (20 * CICLOS_BARRIDO) @(posedge clk);
        mostrar_display("Display estable mostrando suma");

        // FASE 5: Reset
        $display("\n[%0t ns] Aplicando reset...", $time);
        rst_n = 1'b0;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (5) @(posedge clk);
        if (DUT.numero1 == 0 && DUT.numero2 == 0)
            $display("  OK: Reset correcto: numero1=%0d numero2=%0d", DUT.numero1, DUT.numero2);
        else
            $display("  FALLO: Reset incorrecto: numero1=%0d numero2=%0d", DUT.numero1, DUT.numero2);

        $display("\n========================================================");
        $display(" TESTBENCH COMPLETADO");
        $display("========================================================\n");
        #100;
        $finish;
    end

    // =========================================================================
    // TIMEOUT GLOBAL
    // =========================================================================
    initial begin
        #(CLK_PERIOD * 1_000_000);
        $display("ERROR: Timeout global alcanzado");
        $finish;
    end

endmodule
