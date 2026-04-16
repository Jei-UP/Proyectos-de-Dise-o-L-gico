`timescale 1ns/1ps

module tb_top_recep;

    reg [6:0] data_in;
    wire [3:0] data_out;
    wire [6:0] seg_7;
    wire [3:0] leds_out;

    // Instancia del DUT (Device Under Test)
    top_recep uut (
        .data_in(data_in),
        .data_out(data_out),
        .seg_7(seg_7),
        .leds_out(leds_out)
    );

    // Procedimiento de prueba
    initial begin

        
        $dumpfile("top_recep_tb.vcd");
        $dumpvars(0, top_recep_tb);

        $display("Inicio de simulación...");
        
        // Caso 1: Sin error (ejemplo válido de Hamming)
        data_in = 7'b1001101; 
        #10;
        $display("Caso 1 - Sin error | data_in=%b -> data_out=%b", data_in, data_out);

        // Caso 2: Error en bit 0
        data_in = 7'b1001100; 
        #10;
        $display("Caso 2 - Error bit 0 | data_in=%b -> data_out=%b", data_in, data_out);

        // Caso 3: Error en bit 2
        data_in = 7'b1001001; 
        #10;
        $display("Caso 3 - Error bit 2 | data_in=%b -> data_out=%b", data_in, data_out);

        // Caso 4: Error en bit 4
        data_in = 7'b1101101; 
        #10;
        $display("Caso 4 - Error bit 4 | data_in=%b -> data_out=%b", data_in, data_out);

        // Caso 5: Otro dato válido sin error
        data_in = 7'b0110011;
        #10;
        $display("Caso 5 - Sin error | data_in=%b -> data_out=%b", data_in, data_out);

        // Caso 6: Error en bit 6
        data_in = 7'b1110011;
        #10;
        $display("Caso 6 - Error bit 6 | data_in=%b -> data_out=%b", data_in, data_out);

        $display("Fin de simulación");
        $stop;
    end

endmodule