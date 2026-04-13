`timescale 1ns/1ps

module top_trans_tb;

    // Inputs al DUT
    reg [3:0] data_in;
    reg [2:0] sw_error;

    // Outputs del DUT
    wire [6:0] data_out;
    wire [6:0] data_con_error;
    wire [6:0] seg_7;

    // Instancia del DUT (Device Under Test)
    top_trans dut (
        .data_in(data_in),
        .sw_error(sw_error),
        .data_out(data_out),
        .data_con_error(data_con_error),
        .seg_7(seg_7)
    );

    // Estímulos
    initial begin
        $dumpfile("top_trans.vcd");
        $dumpvars(0, top_trans_tb);

        // valores iniciales
        data_in   = 4'b0000;
        sw_error  = 3'b000;

        #10;

        // Caso 1: sin error
        data_in  = 4'b1010;
        sw_error = 3'b000;

        #10;

        // Caso 2: con error en bit 1
        sw_error = 3'b001;

        #10;

        // Caso 3: otro dato
        data_in  = 4'b1101;
        sw_error = 3'b010;

        #10;

        // Caso 4: más error
        sw_error = 3'b111;

        #20;

        $finish;
    end

endmodule
