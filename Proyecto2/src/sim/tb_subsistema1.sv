`timescale 1ns/1ps

module tb_subsistema1;

    localparam CICLOS_DEBOUNCE = 20;
    localparam CICLOS_BARRIDO  = 200;
    localparam PERIODO_CLK     = 37;

    logic        clk;
    logic        rst;
    logic [3:0]  filas_raw;
    logic [3:0]  columnas;
    logic [9:0]  num1_reg;
    logic [9:0]  num2_reg;
    logic        datos_listos;

    top #(
        .CICLOS_DEBOUNCE(CICLOS_DEBOUNCE),
        .CICLOS_BARRIDO (CICLOS_BARRIDO)
    ) dut (
        .clk         (clk),
        .rst         (rst),
        .filas_raw   (filas_raw),
        .columnas    (columnas),
        .num1_reg    (num1_reg),
        .num2_reg    (num2_reg),
        .datos_listos(datos_listos)
    );

    initial clk = 0;
    always #(PERIODO_CLK/2) clk = ~clk;

    // -------------------------------------------------------
    // Flag que captura el pulso de datos_listos aunque
    // ocurra mientras el TB está ocupado en presionar_tecla.
    // -------------------------------------------------------
    logic datos_flag;
    initial datos_flag = 1'b0;
    always @(posedge clk)
        if (datos_listos) datos_flag = 1'b1;

    // -------------------------------------------------------
    // Modelo del teclado matricial
    // -------------------------------------------------------
    int tecla_fila = -1;
    int tecla_col  = -1;

    always_comb begin
        filas_raw = 4'b0000;
        if (tecla_fila >= 0 && tecla_col >= 0 && columnas[tecla_col]) begin
            filas_raw[tecla_fila] = 1'b1;
        end
    end

    // -------------------------------------------------------
    // Tarea: pulsar tecla
    // -------------------------------------------------------
    task presionar_tecla(input int fila_idx, input int col_idx);
        tecla_fila = fila_idx;
        tecla_col  = col_idx;
        repeat (CICLOS_BARRIDO * 8) @(posedge clk);
        tecla_fila = -1;
        tecla_col  = -1;
        repeat (CICLOS_BARRIDO * 4) @(posedge clk);
    endtask

    // -------------------------------------------------------
    // Secuencia principal
    // -------------------------------------------------------
    initial begin
        rst = 1'b1;
        repeat (10) @(posedge clk);
        rst = 1'b0;
        repeat (20) @(posedge clk);

        $display("===========================================");
        $display("  INICIO DE SIMULACION - Subsistema 1");
        $display("===========================================");

        // TEST 1: 123 # 456 #  -> 123 / 456
        $display("\n[TEST 1] Ingresando: 1 2 3 # 4 5 6 #");
        presionar_tecla(0, 0);  // 1
        presionar_tecla(0, 1);  // 2
        presionar_tecla(0, 2);  // 3
        presionar_tecla(3, 2);  // #
        presionar_tecla(1, 0);  // 4
        presionar_tecla(1, 1);  // 5
        presionar_tecla(1, 2);  // 6
        presionar_tecla(3, 2);  // #

        wait (datos_flag == 1'b1);
        datos_flag = 1'b0;
        @(posedge clk);
        if (num1_reg == 10'd123 && num2_reg == 10'd456)
            $display("[PASS] num1=%0d, num2=%0d", num1_reg, num2_reg);
        else
            $display("[FAIL] Esperado 123/456, obtenido num1=%0d num2=%0d",
                     num1_reg, num2_reg);

        repeat (CICLOS_BARRIDO * 4) @(posedge clk);

        // TEST 2: 9 # 5 #  -> 9 / 5
        $display("\n[TEST 2] Ingresando: 9 # 5 #");
        presionar_tecla(2, 2);  // 9
        presionar_tecla(3, 2);  // #
        presionar_tecla(1, 1);  // 5
        presionar_tecla(3, 2);  // #

        wait (datos_flag == 1'b1);
        datos_flag = 1'b0;
        @(posedge clk);
        if (num1_reg == 10'd9 && num2_reg == 10'd5)
            $display("[PASS] num1=%0d, num2=%0d", num1_reg, num2_reg);
        else
            $display("[FAIL] Esperado 9/5, obtenido num1=%0d num2=%0d",
                     num1_reg, num2_reg);

        repeat (CICLOS_BARRIDO * 4) @(posedge clk);

        // TEST 3: reset con *
        $display("\n[TEST 3] Ingresando: 1 2 * 7 # 8 #");
        presionar_tecla(0, 0);  // 1
        presionar_tecla(0, 1);  // 2
        presionar_tecla(3, 0);  // *  (reset)
        presionar_tecla(2, 0);  // 7
        presionar_tecla(3, 2);  // #
        presionar_tecla(2, 1);  // 8
        presionar_tecla(3, 2);  // #

        wait (datos_flag == 1'b1);
        datos_flag = 1'b0;
        @(posedge clk);
        if (num1_reg == 10'd7 && num2_reg == 10'd8)
            $display("[PASS] num1=%0d, num2=%0d", num1_reg, num2_reg);
        else
            $display("[FAIL] Esperado 7/8, obtenido num1=%0d num2=%0d",
                     num1_reg, num2_reg);

        repeat (CICLOS_BARRIDO * 4) @(posedge clk);

        // TEST 4: límite de 3 dígitos
        $display("\n[TEST 4] Ingresando: 9 9 9 9 # 1 # (4to debe ignorarse)");
        presionar_tecla(2, 2);  // 9
        presionar_tecla(2, 2);  // 9
        presionar_tecla(2, 2);  // 9
        presionar_tecla(2, 2);  // 9 (debe ignorarse)
        presionar_tecla(3, 2);  // #
        presionar_tecla(0, 0);  // 1
        presionar_tecla(3, 2);  // #

        wait (datos_flag == 1'b1);
        datos_flag = 1'b0;
        @(posedge clk);
        if (num1_reg == 10'd999)
            $display("[PASS] num1=%0d (4to digito ignorado)", num1_reg);
        else
            $display("[FAIL] Esperado 999, obtenido num1=%0d", num1_reg);

        $display("\n===========================================");
        $display("  FIN DE SIMULACION");
        $display("===========================================");
        $finish;
    end

    always @(posedge clk) begin
        if (datos_listos)
            $display("[MONITOR] datos_listos! num1=%0d num2=%0d",
                     num1_reg, num2_reg);
    end

    initial begin
        $dumpfile("sim/tb_subsistema1.vcd");
        $dumpvars(0, tb_subsistema1);
    end

endmodule