`timescale 1ns/1ps

// =============================================================================
//  tb_top.sv  —  Testbench sistema completo (Icarus Verilog compatible)
//
//  10 casos de prueba:
//    1)  472 + 358 = 830
//    2)  100 + 200 = 300
//    3)  999 + 999 = 1998
//    4)  001 + 001 = 2
//    5)  500 + 500 = 1000
//    6)  123 + 456 = 579
//    7)  999 + 001 = 1000
//    8)  750 + 250 = 1000
//    9)  321 + 679 = 1000
//   10)  100 + 900 = 1000
// =============================================================================

module tb_top;

    localparam CLK_PERIOD      = 10;
    localparam CICLOS_BARRIDO  = 20;
    localparam CICLOS_DEBOUNCE = 20;

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

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Tabla fila/columna por digito
    integer fila_de [0:9];
    integer col_de  [0:9];

    initial begin
        fila_de[0]=3; fila_de[1]=0; fila_de[2]=0; fila_de[3]=0;
        fila_de[4]=1; fila_de[5]=1; fila_de[6]=1;
        fila_de[7]=2; fila_de[8]=2; fila_de[9]=2;
        col_de[0]=1;  col_de[1]=0;  col_de[2]=1;  col_de[3]=2;
        col_de[4]=0;  col_de[5]=1;  col_de[6]=2;
        col_de[7]=0;  col_de[8]=1;  col_de[9]=2;
    end

    // Contador de casos pasados/fallidos
    integer casos_ok;
    integer casos_fallo;

    task automatic presionar_tecla(
        input integer fila_num,
        input integer col_num,
        input string  nombre_tecla
    );
        reg [3:0] col_esperada;
        integer   timeout;
        col_esperada = 4'b0001 << col_num;
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
    endtask

    task automatic ingresar_numero(
        input integer d2,
        input integer d1,
        input integer d0
    );
        presionar_tecla(fila_de[d2], col_de[d2], $sformatf("%0d",d2));
        presionar_tecla(fila_de[d1], col_de[d1], $sformatf("%0d",d1));
        presionar_tecla(fila_de[d0], col_de[d0], $sformatf("%0d",d0));
        presionar_tecla(3, 2, "#");  // confirmar
    endtask

    task automatic hacer_reset();
        rst_n = 1'b0;
        filas_raw = 4'b0000;
        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        repeat (5) @(posedge clk);
    endtask

    task automatic ejecutar_caso(
        input integer a2, input integer a1, input integer a0,
        input integer b2, input integer b1, input integer b0,
        input integer esperado,
        input integer num_caso
    );
        integer val_a, val_b;
        val_a = a2*100 + a1*10 + a0;
        val_b = b2*100 + b1*10 + b0;

        hacer_reset();

        $display("\n[Caso %0d] %0d + %0d = ? (esperado: %0d)",
                 num_caso, val_a, val_b, esperado);

        ingresar_numero(a2, a1, a0);
        ingresar_numero(b2, b1, b0);

        wait (suma_ready == 1'b1);
        @(posedge clk);

        if (suma == esperado[10:0]) begin
            $display("  OK:    suma = %0d  CORRECTO", suma);
            casos_ok = casos_ok + 1;
        end else begin
            $display("  FALLO: suma = %0d  ESPERADO %0d", suma, esperado);
            casos_fallo = casos_fallo + 1;
        end
    endtask

    // VCD
    initial begin
        $dumpfile("sim/tb_top.vcd");
        $dumpvars(0, tb_top);
    end

    // Estimulos
    initial begin
        casos_ok    = 0;
        casos_fallo = 0;
        filas_raw   = 4'b0000;
        rst_n       = 1'b0;

        $display("========================================================");
        $display(" TESTBENCH: 10 casos de suma");
        $display("========================================================");

        //            A          B        esperado  #caso
        ejecutar_caso(4,7,2,   3,5,8,   830,        1);
        ejecutar_caso(1,0,0,   2,0,0,   300,        2);
        ejecutar_caso(9,9,9,   9,9,9,   1998,       3);
        ejecutar_caso(0,0,1,   0,0,1,   2,          4);
        ejecutar_caso(5,0,0,   5,0,0,   1000,       5);
        ejecutar_caso(1,2,3,   4,5,6,   579,        6);
        ejecutar_caso(9,9,9,   0,0,1,   1000,       7);
        ejecutar_caso(7,5,0,   2,5,0,   1000,       8);
        ejecutar_caso(3,2,1,   6,7,9,   1000,       9);
        ejecutar_caso(1,0,0,   9,0,0,   1000,       10);

        $display("\n========================================================");
        $display(" RESULTADO FINAL: %0d/10 correctos, %0d fallidos",
                 casos_ok, casos_fallo);
        $display("========================================================\n");

        #100;
        $finish;
    end

    // Timeout global
    initial begin
        #(CLK_PERIOD * 5_000_000);
        $display("ERROR: Timeout global");
        $finish;
    end

endmodule
