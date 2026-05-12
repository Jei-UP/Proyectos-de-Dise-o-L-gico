`timescale 1ns/1ps
module tb_top;

    // ============================================================
    // CLOCK
    // ============================================================
    reg clk;

    initial clk = 0;

    // ~27 MHz
    always #18.5 clk = ~clk;

    // ============================================================
    // DUT SIGNALS
    // ============================================================
    reg rst_n;
    reg [3:0] filas_raw;

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
    // PARAMETROS
    // ============================================================
    parameter PRESS_TIME   = 25000000;
    parameter RELEASE_TIME = 25000000;

    // ============================================================
    // TASK: PRESS KEY
    // ============================================================
    task press_key;

        input [3:0] key;

        reg [3:0] target_col;
        reg [3:0] target_row;

        begin

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

                4'hE: begin target_col=4'b0001; target_row=4'b1000; end
                4'hF: begin target_col=4'b0100; target_row=4'b1000; end

                default: begin
                    target_col = 4'b0000;
                    target_row = 4'b0000;
                end

            endcase

            // Esperar columna correcta
            wait(columnas == target_col);

            // Presionar
            filas_raw = target_row;

            #(PRESS_TIME);

            // Soltar
            filas_raw = 4'b0000;

            #(RELEASE_TIME);

        end

    endtask

    // ============================================================
    // TASK: INGRESAR NUMERO
    // ============================================================
    task ingresar_numero;

        input [3:0] d2;
        input [3:0] d1;
        input [3:0] d0;

        begin

            if (d2 != 0)
                press_key(d2);

            if ((d2 != 0) || (d1 != 0))
                press_key(d1);

            press_key(d0);

            // ENTER
            press_key(4'hF);

        end

    endtask

    // ============================================================
    // TASK: VERIFICAR
    // ============================================================
    task verificar;

        input [3:0] e3;
        input [3:0] e2;
        input [3:0] e1;
        input [3:0] e0;

        begin

            #1000;

            $display("----------------------------------------");

            $display("Esperado = %0d%0d%0d%0d",
                     e3,e2,e1,e0);

            $display("Obtenido = %0d%0d%0d%0d",
                     DUT.d3,
                     DUT.d2,
                     DUT.d1,
                     DUT.d0);

            if ((DUT.d3 == e3) &&
                (DUT.d2 == e2) &&
                (DUT.d1 == e1) &&
                (DUT.d0 == e0))
            begin
                $display("PASS");
            end
            else begin
                $display("FAIL");
            end

            $display("----------------------------------------");

        end

    endtask

    // ============================================================
    // TEST
    // ============================================================
    initial begin

        $dumpfile("sim/tb_top.vcd");
        $dumpvars(0, tb_top);

        filas_raw = 0;
        rst_n = 0;

        #1000;
        rst_n = 1;

        // ========================================================
        // CASO 1
        // ========================================================
        $display("251 + 302 = 553");

        ingresar_numero(4'd2,4'd5,4'd1);
        ingresar_numero(4'd3,4'd0,4'd2);

        verificar(4'd0,4'd5,4'd5,4'd3);

        press_key(4'hF);

        // ========================================================
        // CASO 2
        // ========================================================
        $display("526 + 67 = 593");

        ingresar_numero(4'd5,4'd2,4'd6);
        ingresar_numero(4'd0,4'd6,4'd7);

        verificar(4'd0,4'd5,4'd9,4'd3);

        press_key(4'hF);

        // ========================================================
        // CASO 3
        // ========================================================
        $display("150 + 750 = 900");

        ingresar_numero(4'd1,4'd5,4'd0);
        ingresar_numero(4'd7,4'd5,4'd0);

        verificar(4'd0,4'd9,4'd0,4'd0);

        press_key(4'hF);

        // ========================================================
        // CASO 4
        // ========================================================
        $display("320 + 640 = 960");

        ingresar_numero(4'd3,4'd2,4'd0);
        ingresar_numero(4'd6,4'd4,4'd0);

        verificar(4'd0,4'd9,4'd6,4'd0);

        press_key(4'hF);

        $display("FIN DE SIMULACION");

        $finish;

    end

    // ============================================================
    // TIMEOUT
    // ============================================================
    initial begin

        #2000000000;

        $display("TIMEOUT");

        $finish;

    end

endmodule
