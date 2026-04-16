`timescale 1ns/1ps

module top_recep_tb;

    reg [6:0] data_in;
    reg [6:0] data_ok;   // código Hamming válido base
    wire [3:0] data_out;
    wire [6:0] seg_7;
    wire [3:0] leds_out;

    top_recep uut (
        .data_in(data_in),
        .data_out(data_out),
        .seg_7(seg_7),
        .leds_out(leds_out)
    );

    initial begin

        $dumpfile("top_recep_tb.vcd");
        $dumpvars(0, top_recep_tb);

        $display("Inicio de simulación...");

        // =========================
        // CASO 1: SIN ERROR
        // =========================
        data_ok = 7'b1001101;   // código válido
        data_in = data_ok;
        #10;
        $display("Caso 1 - Sin error | data_in=%b -> data_out=%b", data_in, data_out);

        // =========================
        // CASO 2: ERROR en posición 1 (bit 0 Verilog)
        // =========================
        data_ok = 7'b1001101;
        data_in = data_ok;
        data_in[0] = ~data_in[0];   // inyección real de error
        #10;
        $display("Caso 2 - Error en posición Hamming 1 | data_in=%b -> data_out=%b", data_in, data_out);

        // =========================
        // CASO 3: ERROR en posición 3
        // =========================
        data_ok = 7'b1001101;
        data_in = data_ok;
        data_in[2] = ~data_in[2];
        #10;
        $display("Caso 3 - Error en posición Hamming 3 | data_in=%b -> data_out=%b", data_in, data_out);

        // =========================
        // CASO 4: ERROR en posición 5
        // =========================
        data_ok = 7'b1001101;
        data_in = data_ok;
        data_in[4] = ~data_in[4];
        #10;
        $display("Caso 4 - Error en posición Hamming 5 | data_in=%b -> data_out=%b", data_in, data_out);

        // =========================
        // CASO 5: SIN ERROR
        // =========================
        data_ok = 7'b0110011;
        data_in = data_ok;
        #10;
        $display("Caso 5 - Sin error | data_in=%b -> data_out=%b", data_in, data_out);

        // =========================
        // CASO 6: ERROR en posición 7
        // =========================
        data_ok = 7'b0110011;
        data_in = data_ok;
        data_in[6] = ~data_in[6];
        #10;
        $display("Caso 6 - Error en posición Hamming 7 | data_in=%b -> data_out=%b", data_in, data_out);

        $display("Fin de simulación");
        $stop;
    end

endmodule