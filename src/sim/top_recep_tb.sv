`timescale 1ns/1ps

module top_recep_tb;

    reg [3:0] data_bin;        // dato original (4 bits)
    wire [6:0] code_ok;        // código Hamming generado
    reg [6:0] data_in;         // entrada al receptor (con o sin error)

    wire [3:0] data_out;
    wire [6:0] seg_7;
    wire [3:0] leds_out;

    // Encoder auxiliar (para generar código válido)
    hamm_encoder encoder (
        .data_in(data_bin),
        .data_out(code_ok)
    );

    // DUT receptor
    top_recep uut (
        .data_in(data_in),
        .data_out(data_out),
        .seg_7(seg_7),
        .leds_out(leds_out)
    );

    initial begin

        $dumpfile("top_recep_tb.vcd");
        $dumpvars(0, top_recep_tb);

        $display("======================================");
        $display("TESTBENCH HAMMING CORRECTO");
        $display("======================================");

        // =========================
        // CASO 1: SIN ERROR
        // =========================
        data_bin = 4'b1010;
        #10;
        data_in = code_ok;
        #10;

        $display("CASO 1 - Sin error");
        $display("code_ok = %b -> data_out = %b", data_in, data_out);

        // =========================
        // CASO 2: ERROR en p1 (bit 0 de TU encoder)
        // =========================
        data_bin = 4'b1010;
        #10;
        data_in = code_ok;
        data_in[0] = ~data_in[0];   // p1
        #10;

        $display("CASO 2 - Error en p1");
        $display("data_in = %b -> data_out = %b", data_in, data_out);

        // =========================
        // CASO 3: ERROR en p2
        // =========================
        data_bin = 4'b1010;
        #10;
        data_in = code_ok;
        data_in[1] = ~data_in[1];   // p2
        #10;

        $display("CASO 3 - Error en p2");
        $display("data_in = %b -> data_out = %b", data_in, data_out);

        // =========================
        // CASO 4: ERROR en d0
        // =========================
        data_bin = 4'b1010;
        #10;
        data_in = code_ok;
        data_in[2] = ~data_in[2];   // d0
        #10;

        $display("CASO 4 - Error en d0");
        $display("data_in = %b -> data_out = %b", data_in, data_out);

        // =========================
        // CASO 5: ERROR en p3
        // =========================
        data_bin = 4'b1010;
        #10;
        data_in = code_ok;
        data_in[3] = ~data_in[3];   // p3
        #10;

        $display("CASO 5 - Error en p3");
        $display("data_in = %b -> data_out = %b", data_in, data_out);

        // =========================
        // CASO 6: ERROR en d3
        // =========================
        data_bin = 4'b1010;
        #10;
        data_in = code_ok;
        data_in[6] = ~data_in[6];   // d3
        #10;

        $display("CASO 6 - Error en d3");
        $display("data_in = %b -> data_out = %b", data_in, data_out);

        $display("======================================");
        $display("FIN DE SIMULACION");
        $display("======================================");

        $stop;
    end

endmodule