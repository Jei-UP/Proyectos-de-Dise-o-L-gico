`timescale 1ns/1ps

module top_recep_tb;

    reg [6:0] data_in;
    wire [3:0] data_out;
    wire [6:0] seg_7;
    wire [3:0] leds_out;

    // DUT
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

        // Caso 1: Sin error
        data_in = 7'b1001101;
        #10;
        $display("Caso 1 - Sin error | data_in=%b -> data_out=%b", data_in, data_out);

        // Caso 2: Error en posición Hamming 1 
        data_in = 7'b1001100; 
        #10;
        $display("Caso 2 - Error en posición Hamming 1 | data_in=%b -> data_out=%b", data_in, data_out);

        // Caso 3: Error en posición Hamming 3
        data_in = 7'b1001001; 
        #10;
        $display("Caso 3 - Error en posición Hamming 3 | data_in=%b -> data_out=%b", data_in, data_out);

        // Caso 4: Error en posición Hamming 5
        data_in = 7'b1101101; 
        #10;
        $display("Caso 4 - Error en posición Hamming 5 | data_in=%b -> data_out=%b", data_in, data_out);

        // Caso 5: Sin error
        data_in = 7'b0110011;
        #10;
        $display("Caso 5 - Sin error | data_in=%b -> data_out=%b", data_in, data_out);

        // Caso 6: Error en posición Hamming 7
        data_in = 7'b1110011;
        #10;
        $display("Caso 6 - Error en posición Hamming 7 | data_in=%b -> data_out=%b", data_in, data_out);

        $display("Fin de simulación");
        $stop;
    end

endmodule