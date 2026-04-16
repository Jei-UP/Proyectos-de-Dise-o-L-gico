`timescale 1ns/1ps

module top_recep_tb;

    reg [3:0] data_bin;        
    reg [6:0] data_in;         

    wire [6:0] code_ok;        

    wire [3:0] data_out;       
    wire [6:0] seg_7;
    wire [3:0] leds_out;

    // ENCODER
    hamm_encoder encoder (
        .data_in(data_bin),
        .data_out(code_ok)
    );

    // RECEPTOR
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
        data_bin = 4'b1010;   
        #10;
        data_in = code_ok;
        #10;

        $display("\nCASO 1 - SIN ERROR");
        $display("data_in  = %b", data_in);
        $display("data_out = %b", data_out);

        // ==================================================
        // CASO 2: ERROR en p1 → data_in[0] → pos Hamming 1
        // ==================================================
        data_bin = 4'b1000;   
        #10;
        data_in = code_ok;
        data_in[0] = ~data_in[0];
        #10;

        $display("\nCASO 2 - ERROR en p1 (data_in[0], pos Hamming 1)");
        $display("data_in  = %b", data_in);
        $display("data_out = %b", data_out);

        // ==================================================
        // CASO 3: ERROR en p2 → data_in[1] → pos Hamming 2
        // ==================================================
        data_bin = 4'b0111;    
        #10;
        data_in = code_ok;
        data_in[1] = ~data_in[1];
        #10;

        $display("\nCASO 3 - ERROR en p2 (data_in[1], pos Hamming 2)");
        $display("data_in  = %b", data_in);
        $display("data_out = %b", data_out);

        // ==================================================
        // CASO 4: ERROR en d0 → data_in[2] → pos Hamming 3
        // ==================================================
        data_bin = 4'b0011;   
        #10;
        data_in = code_ok;
        data_in[2] = ~data_in[2];
        #10;

        $display("\nCASO 4 - ERROR en d0 (data_in[2], pos Hamming 3)");
        $display("data_in  = %b", data_in);
        $display("data_out = %b", data_out);

        // ==================================================
        // CASO 5: ERROR en p3 → data_in[3] → pos Hamming 4
        // ==================================================
        data_bin = 4'b1101;   
        #10;
        data_in = code_ok;
        data_in[3] = ~data_in[3];
        #10;

        $display("\nCASO 5 - ERROR en p3 (data_in[3], pos Hamming 4)");
        $display("data_in  = %b", data_in);
        $display("data_out = %b", data_out);

        // ==================================================
        // CASO 6: ERROR en d3 → data_in[6] → pos Hamming 7
        // ==================================================
        data_bin = 4'b0101;   
        #10;
        data_in = code_ok;
        data_in[6] = ~data_in[6];
        #10;

        $display("\nCASO 6 - ERROR en d3 (data_in[6], pos Hamming 7)");
        $display("data_in  = %b", data_in);
        $display("data_out = %b", data_out);

        $display("\n========================================");
        $display("FIN DE SIMULACION");
        $display("========================================");

        $stop;
    end

endmodule