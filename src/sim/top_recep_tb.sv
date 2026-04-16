`timescale 1ns/1ps

module top_recep_tb;

    reg  [6:0] data_in;
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
        $display("==========================================================");

        // Para cada caso: primero probamos sin error, luego con error en cada bit
        // Los codewords vienen directamente de las salidas verificadas del transmisor

        // data_in=0000 -> codeword=0000000 -> dato esperado=0000
        data_in = 7'b0000000; #10;
        $display("dato=0000 | sin error     | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0000) ? "OK" : "ERROR");
        data_in = 7'b0000001; #10;
        $display("dato=0000 | error bit 0   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0000) ? "OK" : "ERROR");
        data_in = 7'b0000010; #10;
        $display("dato=0000 | error bit 1   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0000) ? "OK" : "ERROR");
        data_in = 7'b0000100; #10;
        $display("dato=0000 | error bit 2   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0000) ? "OK" : "ERROR");
        data_in = 7'b0001000; #10;
        $display("dato=0000 | error bit 3   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0000) ? "OK" : "ERROR");
        data_in = 7'b0010000; #10;
        $display("dato=0000 | error bit 4   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0000) ? "OK" : "ERROR");
        data_in = 7'b0100000; #10;
        $display("dato=0000 | error bit 5   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0000) ? "OK" : "ERROR");
        data_in = 7'b1000000; #10;
        $display("dato=0000 | error bit 6   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0000) ? "OK" : "ERROR");

        $display("----------------------------------------------------------");

        // data_in=0001 -> codeword=0000111 -> dato esperado=0001
        data_in = 7'b0000111; #10;
        $display("dato=0001 | sin error     | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0001) ? "OK" : "ERROR");
        data_in = 7'b0000110; #10;
        $display("dato=0001 | error bit 0   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0001) ? "OK" : "ERROR");
        data_in = 7'b0000101; #10;
        $display("dato=0001 | error bit 1   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0001) ? "OK" : "ERROR");
        data_in = 7'b0000011; #10;
        $display("dato=0001 | error bit 2   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0001) ? "OK" : "ERROR");
        data_in = 7'b0001111; #10;
        $display("dato=0001 | error bit 3   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0001) ? "OK" : "ERROR");
        data_in = 7'b0010111; #10;
        $display("dato=0001 | error bit 4   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0001) ? "OK" : "ERROR");
        data_in = 7'b0100111; #10;
        $display("dato=0001 | error bit 5   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0001) ? "OK" : "ERROR");
        data_in = 7'b1000111; #10;
        $display("dato=0001 | error bit 6   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0001) ? "OK" : "ERROR");

        $display("----------------------------------------------------------");

        // data_in=0110 -> codeword=0110011 -> dato esperado=0110
        data_in = 7'b0110011; #10;
        $display("dato=0110 | sin error     | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0110) ? "OK" : "ERROR");
        data_in = 7'b0110010; #10;
        $display("dato=0110 | error bit 0   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0110) ? "OK" : "ERROR");
        data_in = 7'b0110001; #10;
        $display("dato=0110 | error bit 1   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0110) ? "OK" : "ERROR");
        data_in = 7'b0110111; #10;
        $display("dato=0110 | error bit 2   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0110) ? "OK" : "ERROR");
        data_in = 7'b0111011; #10;
        $display("dato=0110 | error bit 3   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0110) ? "OK" : "ERROR");
        data_in = 7'b0100011; #10;
        $display("dato=0110 | error bit 4   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0110) ? "OK" : "ERROR");
        data_in = 7'b0010011; #10;
        $display("dato=0110 | error bit 5   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0110) ? "OK" : "ERROR");
        data_in = 7'b1110011; #10;
        $display("dato=0110 | error bit 6   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b0110) ? "OK" : "ERROR");

        $display("----------------------------------------------------------");

        // data_in=1001 -> codeword=1001100 -> dato esperado=1001
        data_in = 7'b1001100; #10;
        $display("dato=1001 | sin error     | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b1001) ? "OK" : "ERROR");
        data_in = 7'b1001101; #10;
        $display("dato=1001 | error bit 0   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b1001) ? "OK" : "ERROR");
        data_in = 7'b1001110; #10;
        $display("dato=1001 | error bit 1   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b1001) ? "OK" : "ERROR");
        data_in = 7'b1001000; #10;
        $display("dato=1001 | error bit 2   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b1001) ? "OK" : "ERROR");
        data_in = 7'b1000100; #10;
        $display("dato=1001 | error bit 3   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b1001) ? "OK" : "ERROR");
        data_in = 7'b1011100; #10;
        $display("dato=1001 | error bit 4   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b1001) ? "OK" : "ERROR");
        data_in = 7'b1101100; #10;
        $display("dato=1001 | error bit 5   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b1001) ? "OK" : "ERROR");
        data_in = 7'b0001100; #10;
        $display("dato=1001 | error bit 6   | data_in=%b -> data_out=%b %s", data_in, data_out, (data_out==4'b1001) ? "OK" : "ERROR");

        $display("==========================================================");
        $display("Fin de simulación");
        $finish;
    end

endmodule