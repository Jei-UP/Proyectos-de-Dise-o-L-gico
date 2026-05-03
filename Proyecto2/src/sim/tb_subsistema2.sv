`timescale 1ns/1ps

module tb_subsistema2;

    // =========================================================
    // SEÑALES
    // =========================================================
    logic clk;
    logic rst;

    logic datos_listos;
    logic [9:0] num1_reg;
    logic [9:0] num2_reg;

    logic [10:0] suma;
    logic suma_ready;

    // =========================================================
    // DUT
    // =========================================================
    subsistema_suma dut (
        .clk(clk),
        .rst(rst),

        .datos_listos(datos_listos),
        .num1_reg(num1_reg),
        .num2_reg(num2_reg),

        .suma(suma),
        .suma_ready(suma_ready)
    );

    // =========================================================
    // RELOJ
    // =========================================================
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz simulado

    // =========================================================
    // TASK: aplicar operación
    // =========================================================
    task aplicar_suma(input int a, input int b);
    begin
        num1_reg = a;
        num2_reg = b;

        @(posedge clk);
        datos_listos = 1'b1;

        @(posedge clk);
        datos_listos = 1'b0;

        // esperar resultado
        @(posedge clk);
    end
    endtask

    // =========================================================
    // TESTS
    // =========================================================
    initial begin

        // ---------------------------
        // INIT
        // ---------------------------
        rst = 1;
        datos_listos = 0;
        num1_reg = 0;
        num2_reg = 0;

        repeat (5) @(posedge clk);
        rst = 0;

        $display("\n==================================");
        $display(" INICIO TEST SUBSISTEMA 2 (SUMA)");
        $display("==================================\n");

        // =====================================================
        // TEST 1
        // =====================================================
        aplicar_suma(123, 456);

        if (suma == 579)
            $display("[PASS] 123 + 456 = %0d", suma);
        else
            $display("[FAIL] esperado 579, obtenido %0d", suma);

        // =====================================================
        // TEST 2
        // =====================================================
        aplicar_suma(9, 5);

        if (suma == 14)
            $display("[PASS] 9 + 5 = %0d", suma);
        else
            $display("[FAIL] esperado 14, obtenido %0d", suma);

        // =====================================================
        // TEST 3
        // =====================================================
        aplicar_suma(999, 1);

        if (suma == 1000)
            $display("[PASS] 999 + 1 = %0d", suma);
        else
            $display("[FAIL] esperado 1000, obtenido %0d", suma);

        // =====================================================
        // TEST 4 (overflow control visual)
        // =====================================================
        aplicar_suma(1023, 1);

        $display("[INFO] 1023 + 1 = %0d (verificacion de overflow 11 bits)", suma);

        // =====================================================
        // FIN
        // =====================================================
        $display("\n==================================");
        $display(" FIN TESTBENCH SUBSISTEMA 2");
        $display("==================================\n");

        $finish;

    end

    // =========================================================
    // MONITOR (opcional pero útil)
    // =========================================================
    always @(posedge clk) begin
        if (suma_ready)
            $display("[MONITOR] suma lista = %0d", suma);
    end

    // =========================================================
    // VCD
    // =========================================================
    initial begin
        $dumpfile("sim/tb_subsistema2.vcd");
        $dumpvars(0, tb_subsistema2);
    end

endmodule