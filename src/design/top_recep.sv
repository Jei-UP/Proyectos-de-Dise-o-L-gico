module top_recep (
    input  wire [6:0] data_in,
    output wire [3:0] data_out,
    output wire [6:0] seg_7,
    output wire [3:0] leds_out
);
    wire [2:0] sindrome;

    // Ahora sí se instancia decoder_paridad
    decoder_paridad decodificador_paridad (
        .recibido(data_in),
        .pos_error(sindrome)
    );

    corrector_error corrector (
        .recibido(data_in),
        .sindrome(sindrome),
        .dato_corregido(data_out)
    );

    recep_7_seg decodificador (
        .datos(data_out),
        .seg_7(seg_7)
    );

    LEDS_display leds (
        .data_corregida(data_out),
        .leds(leds_out)
    );

endmodule