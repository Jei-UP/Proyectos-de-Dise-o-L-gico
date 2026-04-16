module top_recep (
    input wire [6:0] data_in,      // Código de Hamming recibido
    output wire [3:0] data_out,    // Datos corregidos
    output wire [6:0] seg_7,       // Display 7 segmentos
    output wire [3:0] leds_out     // LEDs
);

    // -----------------------------
    // Señal interna del síndrome
    // -----------------------------
    wire [2:0] pos_error;

    // -----------------------------
    // Decoder de paridad (NUEVO)
    // -----------------------------
    decoder_paridad dec_paridad (
        .recibido(data_in),
        .pos_error(pos_error)
    );

    // -----------------------------
    // Corrector de error
    // AHORA usa el síndrome real
    // -----------------------------
    corrector_error corrector (
        .recibido(data_in),
        .sindrome(pos_error),
        .dato_corregido(data_out)
    );

    // -----------------------------
    // Display 7 segmentos
    // -----------------------------
    recep_7_seg decodificador (
        .datos(data_out),
        .seg_7(seg_7)
    );

    // -----------------------------
    // LEDs
    // -----------------------------
    LEDS_display leds (
        .data_corregida(data_out),
        .leds(leds_out)
    );

endmodule