`timescale 1ns/1ps

module tb_subsistema1;

    localparam CICLOS_DEBOUNCE = 20;
    localparam CICLOS_BARRIDO  = 10;
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
    // Tarea: esperar columna con timeout simple
    // -------------------------------------------------------
    task presionar_tecla(input int fila_idx, input int col_idx);
        integer timeout;
        timeout = 0;

        // esperar la columna correcta con timeout
        while (columnas[col_idx] !== 1'b1) begin
            @(posedge clk);
            timeout = timeout + 1;
            if (timeout > CICLOS_BARRIDO * 20) begin
                $display("[ERROR] Timeout esperando columna %0d - columnas=%b",
                         col_idx, columnas);
                $finish;
            end
        end

        // activar la fila
        filas_raw[fila_idx] = 1'b1;
        repeat (CICLOS_DEBOUNCE * 4) @(posedge clk);

        // soltar la tecla
        filas_raw[fila_idx] = 1'b0;
        repeat (CICLOS_DEBOUNCE * 3) @(posedge clk);
    endtask

    // -------------------------------------------------------
    // Secuencia principal
    // -------------------------------------------------------
    initial begin
        rst       = 1'b1;
        filas_raw = 4'b0000;
        repeat (10) @(posedge clk);
        rst = 1'b0;
        repeat (20) @(posedge clk);

        $display("===========================================");
        $display("  INICIO DE SIMULACIÓN - Subsistema 1");
        $display("===========================================");

        // TEST 1: 123 # 456 #
        $display("\n[TEST 1] Ingresando: 1 2 3 # 4 5 6 #");
        presionar_tecla(0, 0);  // 1
        presionar_tecla(0, 1);  // 2
        presionar_tecla(0, 2);  // 3
        presionar_tecla(3, 2);  // #
        presionar_tecla(1, 0);  // 4
        presionar_tecla(1, 1);  // 5
        presionar_tecla(1, 2);  // 6
        presionar_tecla(3, 2);  // #

        wait (datos_listos == 1'b1);
        @(posedge clk);
        if (num1_reg == 10'd123 && num2_reg == 10'd456)
            $display("[PASS] num1=%0d, num2=%0d", num1_reg, num2_reg);
        else
            $display("[FAIL] Esperado 123/456, obtenido num1=%0d num2=%0d",
                     num1_reg, num2_reg);

        repeat (30) @(posedge clk);

        // TEST 2: 9 # 5 #
        $display("\n[TEST 2] Ingresando: 9 # 5 #");
        presionar_tecla(2, 2);  // 9
        presionar_tecla(3, 2);  // #
        presionar_tecla(1, 1);  // 5
        presionar_tecla(3, 2);  // #

        wait (datos_listos == 1'b1);
        @(posedge clk);
        if (num1_reg == 10'd9 && num2_reg == 10'd5)
            $display("[PASS] num1=%0d, num2=%0d", num1_reg, num2_reg);
        else
            $display("[FAIL] Esperado 9/5, obtenido num1=%0d num2=%0d",
                     num1_reg, num2_reg);

        repeat (30) @(posedge clk);

        // TEST 3: reset con *
        $display("\n[TEST 3] Ingresando: 1 2 * 7 # 8 #");
        presionar_tecla(0, 0);  // 1
        presionar_tecla(0, 1);  // 2
        presionar_tecla(3, 0);  // *
        presionar_tecla(2, 0);  // 7
        presionar_tecla(3, 2);  // #
        presionar_tecla(2, 1);  // 8
        presionar_tecla(3, 2);  // #

        wait (datos_listos == 1'b1);
        @(posedge clk);
        if (num1_reg == 10'd7 && num2_reg == 10'd8)
            $display("[PASS] num1=%0d, num2=%0d", num1_reg, num2_reg);
        else
            $display("[FAIL] Esperado 7/8, obtenido num1=%0d num2=%0d",
                     num1_reg, num2_reg);

        repeat (30) @(posedge clk);

        // TEST 4: límite 3 dígitos
        $display("\n[TEST 4] Ingresando: 9 9 9 9 # (4to debe ignorarse)");
        presionar_tecla(2, 2);  // 9
        presionar_tecla(2, 2);  // 9
        presionar_tecla(2, 2);  // 9
        presionar_tecla(2, 2);  // 9 ignorado
        presionar_tecla(3, 2);  // #
        presionar_tecla(0, 0);  // 1
        presionar_tecla(3, 2);  // #

        wait (datos_listos == 1'b1);
        @(posedge clk);
        if (num1_reg == 10'd999)
            $display("[PASS] num1=%0d (4to dígito ignorado)", num1_reg);
        else
            $display("[FAIL] Esperado 999, obtenido num1=%0d", num1_reg);

        $display("\n===========================================");
        $display("  FIN DE SIMULACIÓN");
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