module top_recep (
    input  wire [6:0] data_in,
    output wire [3:0] data_out,      // dato corregido → va a LEDs y a selector
    output wire [2:0] pos_error,     // síndrome → va a selector
    output wire [6:0] seg_7,
    output wire [3:0] leds_out
);
    wire [2:0] sindrome;

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

    assign pos_error = sindrome;  // expone el síndrome hacia el selector externo

endmodule