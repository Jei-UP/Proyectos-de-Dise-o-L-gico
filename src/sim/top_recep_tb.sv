`timescale 1ns/1ps

module top_recep_tb;

    reg [3:0] data_bin;        // dato original
    reg [6:0] data_in;         // código con o sin error

    wire [6:0] code_ok;        // código correcto del encoder

    wire [3:0] data_out;       // dato corregido final
    wire [6:0] seg_7;
    wire [3:0] leds_out;

    // señales internas del corrector (DEBUG)
    wire [2:0] syndrome;
    wire [2:0] error_pos;
    wire [3:0] dato_corregido;

    // =========================
    // ENCODER
    // =========================
    hamm_encoder encoder (
        .data_in(data_bin),
        .data_out(code_ok)
    );

    // =========================
    // RECEPTOR (TU SISTEMA COMPLETO)
    // =========================
    top_recep uut (
        .data_in(data_in),
        .data_out(data_out),
        .seg_7(seg_7),
        .leds_out(leds_out)
    );

    initial begin

        $dumpfile("top_recep_tb.vcd");
        $dumpvars(0, top_recep_tb);

        $display("========================================");
        $display("TESTBENCH HAMMING CON CORRECTOR");
        $display("========================================");

        // ==================================================
        // CASO 1: SIN ERROR
        // ==================================================
        data_bin = 4'b1010;   //Número 10
        #10;
        data_in = code_ok;
        #10;

        $display("\nCASO 1 - SIN ERROR");
        $display("data_in        = %b", data_in);
        $display("data_out       = %b", data_out);

        // ==================================================
        // CASO 2: ERROR en p1 (bit 0 de TU diseño)
        // ==================================================
        data_bin = 4'b1000;   // Número 8
        #10;
        data_in = code_ok;
        data_in[0] = ~data_in[0];
        #10;

        $display("\nCASO 2 - ERROR en bit 1");
        $display("data_in        = %b", data_in);
        $display("data_out       = %b", data_out);

        // ==================================================
        // CASO 3: ERROR en p2
        // ==================================================
        data_bin = 4'b0111;    //Número 7
        #10;
        data_in = code_ok;
        data_in[1] = ~data_in[1];
        #10;

        $display("\nCASO 3 - ERROR en bit 2");
        $display("data_in        = %b", data_in);
        $display("data_out       = %b", data_out);

        // ==================================================
        // CASO 4: ERROR en d0
        // ==================================================
        data_bin = 4'b0011;   //Número 3
        #10;
        data_in = code_ok;
        data_in[2] = ~data_in[2];
        #10;

        $display("\nCASO 4 - ERROR en bit 3");
        $display("data_in        = %b", data_in);
        $display("data_out       = %b", data_out);

        // ==================================================
        // CASO 5: ERROR en p3
        // ==================================================
        data_bin = 4'b1101;   //Número 13
        #10;
        data_in = code_ok;
        data_in[3] = ~data_in[3];
        #10;

        $display("\nCASO 5 - ERROR en bit 4");
        $display("data_in        = %b", data_in);
        $display("data_out       = %b", data_out);

        // ==================================================
        // CASO 6: ERROR en d3
        // ==================================================
        data_bin = 4'b1111;   //Número 15
        #10;
        data_in = code_ok;
        data_in[6] = ~data_in[6];
        #10;

        $display("\nCASO 6 - ERROR en bit 5");
        $display("data_in        = %b", data_in);
        $display("data_out       = %b", data_out);

        $display("\n========================================");
        $display("FIN DE SIMULACION");
        $display("========================================");

        $stop;
    end

endmodule