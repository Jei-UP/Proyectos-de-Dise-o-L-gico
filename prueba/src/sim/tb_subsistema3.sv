`timescale 1ns/1ps

module tb_subsistema3;

    // ================================
    // SEÑALES
    // ================================
    logic clk;
    logic [1:0] sel;
    logic [3:0] dig_in;

    wire [7:0] seg_7;
    wire [3:0] AN;

    // ================================
    // DUT
    // ================================
    display_7 DUT (
        .clk(clk),
        .sel(sel),
        .dig_in(dig_in),
        .seg_7(seg_7),
        .AN(AN)
    );

    // ================================
    // RELOJ
    // ================================
    initial clk = 0;
    always #10 clk = ~clk; // 50 MHz sim

    // ================================
    // ESTÍMULOS
    // ================================
    initial begin
        // Inicial
        sel = 0;
        dig_in = 0;

        // Esperar
        #50;

        // ============================
        // Probar dígitos 0–9
        // ============================
        repeat (10) begin
            dig_in = dig_in + 1;
            #100;
        end

        // ============================
        // Probar multiplexado
        // ============================
        dig_in = 4'd5;

        sel = 2'b00; #100;
        sel = 2'b01; #100;
        sel = 2'b10; #100;
        sel = 2'b11; #100;

        // ============================
        // Probar valores inválidos
        // ============================
        dig_in = 4'd12; #100;
        dig_in = 4'd15; #100;

        // ============================
        // Fin
        // ============================
        #200;
        $finish;
    end

    // ================================
    // MONITOR
    // ================================
    initial begin
        $display("----------------------------------------------------");
        $display(" Tiempo | sel | dig_in |   seg_7   |   AN");
        $display("----------------------------------------------------");

        $monitor("%0t | %b | %d | %b | %b",
            $time,
            sel,
            dig_in,
            seg_7,
            AN
        );
    end


    initial begin
    $dumpfile("sim/tb_subsistema3.vcd");   // nombre del archivo
    $dumpvars(0, tb_subsistema3);      // guarda TODAS las señales
end

endmodule