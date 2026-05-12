`timescale 1ns/1ps

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

    integer casos_ok;
    integer casos_fallo;

    // =========================================================
    // MONITOR: imprime cada vez que cambia algo relevante
    // =========================================================
    initial begin
        $monitor("[%0t ns] col=%b filas=%b | dato_v=%b tecla_v=%b tecla=%0d | estado=%0d | n1=%0d n2=%0d | suma=%0d rdy=%b",
            $time,
            columnas, filas_raw,
            DUT.dato_valido,
            DUT.tecla_valida,
            DUT.tecla,
            DUT.fsm_inst.estado,
            DUT.numero1, DUT.numero2,
            suma, suma_ready
        );
    end

    task automatic presionar_tecla(
        input integer fila_num,
        input integer col_num,
        input string  nombre_tecla
    );
        reg [3:0] col_esperada;
        integer   timeout;
        col_esperada = 4'b0001 << col_num;

        $display("[%0t ns] >>> Esperando columna %b para tecla '%s'",
                 $time, col_esperada, nombre_tecla);

        timeout = 0;
        while (columnas !== col_esperada) begin
            @(posedge clk);
            timeout = timeout + 1;
            if (timeout > CICLOS_BARRIDO * 20) begin
                $display("[%0t ns] ERROR: timeout esperando columna %b (columnas=%b)",
                         $time, col_esperada, columnas);
                disable presionar_tecla;
            end
        end

        $display("[%0t ns] >>> Columna %b activa, presionando fila %0d",
                 $time, col_esperada, fila_num);

        filas_raw[fila_num] = 1'b1;
        repeat (CICLOS_BARRIDO) @(posedge clk);
        filas_raw[fila_num] = 1'b0;

        $display("[%0t ns] >>> Tecla '%s' soltada, esperando release...",
                 $time, nombre_tecla);

        repeat (CICLOS_BARRIDO * 6) @(posedge clk);

        $display("[%0t ns] >>> Tecla '%s' completada. tecla_v=%b n1=%0d n2=%0d",
                 $time, nombre_tecla, DUT.tecla_valida, DUT.numero1, DUT.numero2);
    endtask

    task automatic ingresar_numero(
        input integer d2,
        input integer d1,
        input integer d0
    );
        presionar_tecla(fila_de[d2], col_de[d2], $sformatf("%0d",d2));
        presionar_tecla(fila_de[d1], col_de[d1], $sformatf("%0d",d1));
        presionar_tecla(fila_de[d0], col_de[d0], $sformatf("%0d",d0));
        presionar_tecla(3, 2, "#");
    endtask

    task automatic hacer_reset();
        rst_n     = 1'b0;
        filas_raw = 4'b0000;
        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        repeat (5) @(posedge clk);
    endtask

    // VCD
    initial begin
        $dumpfile("sim/tb_top.vcd");
        $dumpvars(0, tb_top);
    end

    // Solo el Caso 1 para diagnostico
    initial begin
        casos_ok    = 0;
        casos_fallo = 0;
        filas_raw   = 4'b0000;
        rst_n       = 1'b0;

        $display("========================================================");
        $display(" DIAGNOSTICO: Caso 1 — 472 + 358 = 830");
        $display("========================================================");

        hacer_reset();

        $display("\n--- Ingresando A = 472 ---");
        ingresar_numero(4, 7, 2);

        $display("\n--- Estado FSM despues de A: estado=%0d numero1=%0d ---",
                 DUT.fsm_inst.estado, DUT.numero1);

        $display("\n--- Ingresando B = 358 ---");
        ingresar_numero(3, 5, 8);

        $display("\n--- Estado FSM despues de B: estado=%0d numero2=%0d ---",
                 DUT.fsm_inst.estado, DUT.numero2);

        $display("\n--- Esperando suma_ready (timeout 5000 ciclos)... ---");
        begin : espera_suma
            integer t;
            t = 0;
            while (suma_ready !== 1'b1) begin
                @(posedge clk);
                t = t + 1;
                if (t > 5000) begin
                    $display("TIMEOUT: suma_ready nunca llego. estado=%0d n1=%0d n2=%0d datos_listos=%b",
                             DUT.fsm_inst.estado, DUT.numero1, DUT.numero2, datos_listos);
                    disable espera_suma;
                end
            end
        end

        @(posedge clk);
        if (suma == 11'd830)
            $display("OK: suma = %0d  CORRECTO", suma);
        else
            $display("FALLO: suma = %0d  ESPERADO 830", suma);

        $display("\n========================================================");
        $display(" DIAGNOSTICO COMPLETADO");
        $display("========================================================\n");
        #100;
        $finish;
    end

    initial begin
        #(CLK_PERIOD * 500_000);
        $display("TIMEOUT GLOBAL alcanzado. Ultima estado FSM=%0d n1=%0d n2=%0d",
                 DUT.fsm_inst.estado, DUT.numero1, DUT.numero2);
        $finish;
    end

endmodule
