```systemverilog
`timescale 1ns/1ps

module tb_top;

    // ============================================================
    // CLOCK
    // ============================================================
    logic clk;
    initial clk = 0;

    // 27 MHz aprox
    always #18.5 clk = ~clk;

    // ============================================================
    // DUT SIGNALS
    // ============================================================
    logic rst_n;
    logic [3:0] filas_raw;

    wire [3:0] columnas;
    wire [6:0] seg_7;
    wire [3:0] AN;

    // ============================================================
    // DUT
    // ============================================================
    top DUT (
        .clk(clk),
        .rst_n(rst_n),
        .filas_raw(filas_raw),
        .columnas(columnas),
        .seg_7(seg_7),
        .AN(AN)
    );

    // ============================================================
    // PARÁMETROS
    // ============================================================
    localparam PRESS_TIME   = 25_000_000; // >20ms debounce
    localparam RELEASE_TIME = 25_000_000;

    // ============================================================
    // MAPEO DE TECLAS
    // ============================================================
    //
    // Teclado:
    //
    // 1 2 3 A
    // 4 5 6 B
    // 7 8 9 C
    // * 0 # D
    //
    // columnas:
    // 0001 0010 0100 1000
    //
    // filas:
    // row0 row1 row2 row3
    //
    // ============================================================

    task automatic press_key(input [3:0] key);

        logic [3:0] target_col;
        logic [3:0] target_row;

        begin

            // ----------------------------------------------------
            // Decodificación tecla -> fila/columna
            // ----------------------------------------------------
            case(key)

                4'h1: begin target_col=4'b0001; target_row=4'b0001; end
                4'h2: begin target_col=4'b0010; target_row=4'b0001; end
                4'h3: begin target_col=4'b0100; target_row=4'b0001; end

                4'h4: begin target_col=4'b0001; target_row=4'b0010; end
                4'h5: begin target_col=4'b0010; target_row=4'b0010; end
                4'h6: begin target_col=4'b0100; target_row=4'b0010; end

                4'h7: begin target_col=4'b0001; target_row=4'b0100; end
                4'h8: begin target_col=4'b0010; target_row=4'b0100; end
                4'h9: begin target_col=4'b0100; target_row=4'b0100; end

                4'h0: begin target_col=4'b0010; target_row=4'b1000; end

                4'hE: begin target_col=4'b0001; target_row=4'b1000; end // *
                4'hF: begin target_col=4'b0100; target_row=4'b1000; end // #

                default: begin
                    target_col = 4'b0000;
                    target_row = 4'b0000;
                end
            endcase

            // ----------------------------------------------------
            // Esperar a que el scanner active la columna correcta
            // ----------------------------------------------------
            wait(columnas == target_col);

            // Presionar tecla
            filas_raw = target_row;

            // Mantener suficiente tiempo para debounce
            #(PRESS_TIME);

            // Soltar tecla
            filas_raw = 4'b0000;

            #(RELEASE_TIME);

        end
    endtask

    // ============================================================
    // INGRESAR NÚMERO
    // ============================================================
    task automatic ingresar_numero(
        input [3:0] d2,
        input [3:0] d1,
        input [3:0] d0
    );
        begin

            if (d2 != 0)
                press_key(d2);

            if (d2 != 0 || d1 != 0)
                press_key(d1);

            press_key(d0);

            // ENTER (#)
            press_key(4'hF);

        end
    endtask

    // ============================================================
    // VERIFICACIÓN
    // ============================================================
    task automatic verificar(
        input string nombre,
        input [3:0] e3,
        input [3:0] e2,
        input [3:0] e1,
        input [3:0] e0
    );

        begin

            #1000;

            $display("------------------------------------------------");
            $display("CASO: %s", nombre);

            $display("Esperado: %0d%0d%0d%0d",
                      e3,e2,e1,e0);

            $display("Obtenido: %0d%0d%0d%0d",
                      DUT.d3,
                      DUT.d2,
                      DUT.d1,
                      DUT.d0);

            if (DUT.d3 == e3 &&
                DUT.d2 == e2 &&
                DUT.d1 == e1 &&
                DUT.d0 == e0)
            begin
                $display("PASS");
            end
            else begin
                $display("FAIL");
            end

            $display("------------------------------------------------");

        end

    endtask

    // ============================================================
    // TEST SEQUENCE
    // ============================================================
    initial begin

        $dumpfile("tb_top.vcd");
        $dumpvars(0,tb_top);

        filas_raw = 0;
        rst_n = 0;

        #1000;
        rst_n = 1;

        // ========================================================
        // CASO 1
        // ========================================================
        $display("\n251 + 302 = 553");

        ingresar_numero(4'd2,4'd5,4'd1);
        ingresar_numero(4'd3,4'd0,4'd2);

        verificar(
            "251 + 302",
            4'd0,
            4'd5,
            4'd5,
            4'd3
        );

        press_key(4'hF);

        // ========================================================
        // CASO 2
        // ========================================================
        $display("\n526 + 67 = 593");

        ingresar_numero(4'd5,4'd2,4'd6);
        ingresar_numero(4'd0,4'd6,4'd7);

        verificar(
            "526 + 67",
            4'd0,
            4'd5,
            4'd9,
            4'd3
        );

        press_key(4'hF);

        // ========================================================
        // CASO 3
        // ========================================================
        $display("\n150 + 750 = 900");

        ingresar_numero(4'd1,4'd5,4'd0);
        ingresar_numero(4'd7,4'd5,4'd0);

        verificar(
            "150 + 750",
            4'd0,
            4'd9,
            4'd0,
            4'd0
        );

        press_key(4'hF);

        // ========================================================
        // CASO 4
        // ========================================================
        $display("\n320 + 640 = 960");

        ingresar_numero(4'd3,4'd2,4'd0);
        ingresar_numero(4'd6,4'd4,4'd0);

        verificar(
            "320 + 640",
            4'd0,
            4'd9,
            4'd6,
            4'd0
        );

        press_key(4'hF);

        $display("\n==================================");
        $display("FIN DE SIMULACIÓN");
        $display("==================================");

        $finish;

    end

    // ============================================================
    // TIMEOUT
    // ============================================================
    initial begin
        #2_000_000_000;
        $display("TIMEOUT");
        $finish;
    end

endmodule
```
