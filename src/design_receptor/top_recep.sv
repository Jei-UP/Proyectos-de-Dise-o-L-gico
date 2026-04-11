module moduleName (
    input wire [6:0] bus_entrada,  //Los 7 cables que vienen de la otra FPGA
    output wire [6:0] display_rx, // Display de lo que recibimos ya corregido
    output wire [3:0] leds_check //LEDs para el ver el dato final
);

    //RECEPTOR
    wire [2:0] sindrome_calculado;
    wire [3:0] datos_finales ;

    parity_decoder modulo_syn (.recibido(bus_entrada), .pos_error(sindrome_calculado));

    corrector_error modulo_cor (.recibido(bus_entrada), .sindrome(sindrome_calculado), .datos_corregido(datos_finales));

    recep_7_seg vis_rx (.datos(datos_finales), .seg_7(display_rx));

    assign leds_check = datos_finales;
    
endmodule