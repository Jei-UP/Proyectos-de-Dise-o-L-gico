module display_LEDS (
    input  logic [3:0] data_corregida, //Datos de 4 bits para mostrar en los LEDs,
    output logic [3:0] leds
);

    assign leds = data_corregida;

endmodule
