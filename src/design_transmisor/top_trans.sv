module top_trans (
    //Inputs

    input wire [3:0] sw_datos,  //switches D3 al D0
    input wire [2:0] sw_error,  //Switches S2 al S0
    input wire [6:0] bus_entrada,  //Los 7 cables que vienen de la otra FPGA

    output wire [6:0] bus_salida, //Los cables que mandamos a la FPGA del otro grupo
    output wire [6:0] display_tx, //Display que monitorea lo que enviamos
    output wire [6:0] display_rx, // Display de lo que recibimos ya corregido
    output wire [3:0] leds_check); //LEDs para el ver el dato final

    //TRANSMISOR

    wire [6:0] cable_ham_limpio;

    hamm_encoder modulo_enc (.data_in(sw_datos), .data_out(cable_ham_limpio));

    inyector_error modulo_inj (.msj_puro(cable_ham_limpio), .sw_error(sw_error), .msj_con_error(bus_salida));

    trans_7_seg vis_tx (.datos(sw_datos), .seg_7(display_tx));

    //RECEPTOR
    wire [2:0] sindrome_calculado;
    wire [3:0] datos_finales ;

    parity_decoder modulo_syn (.recibido(bus_entrada), .pos_error(sindrome_calculado));

    corrector_error modulo_cor (.recibido(bus_entrada), .syndrome(sindrome_calculado), .datos_correctos(datos_finales));



    
endmodule