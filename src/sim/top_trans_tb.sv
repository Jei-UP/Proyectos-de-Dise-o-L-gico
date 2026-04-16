`timescale 1ns / 1ps
module top_trans_tb;

    reg  [3:0] data_in;
    reg  [2:0] sw_error;
    wire [6:0] salida;
    wire [6:0] seg_7;

    integer i, j;
    reg [6:0] msj_con_error_esperado;
    reg [6:0] msj_puro;
    reg error_detectado;

    // Instanciar top_trans completo
    top_trans uut (
        .data_in(data_in),
        .sw_error(sw_error),
        .salida(salida),
        .seg_7(seg_7)
    );

    initial begin
        $dumpfile("top_trans_tb.vcd");
        $dumpvars(0, top_trans_tb);

        error_detectado = 0;  // inicializar aquí

        $display("==========================================================");
        $display("INICIANDO TEST BENCH - TRANSMISOR HAMMING (7,4)");
        $display("==========================================================");

        for (i = 0; i < 16; i = i + 1) begin
            data_in = i;
            sw_error = 0;
            #10;

            $display("----------------------------------------------------------");
            $display("data_in=%b  seg_7=%b  salida_limpia=%b", data_in, seg_7, salida);

            for (j = 1; j < 8; j = j + 1) begin
                sw_error = j;
                #10;
                $display("  sw_error=%b -> salida=%b", sw_error, salida);
            end
        end

        $display("==========================================================");
        if (error_detectado)
            $display("TEST BENCH COMPLETADO CON ERRORES");
        else
            $display("TEST BENCH COMPLETADO EXITOSAMENTE");
        $display("==========================================================");

        #20;
        $finish;
    end

endmodule