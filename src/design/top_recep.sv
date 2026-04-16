module top_recep (
    input wire [6:0] data_in, //Código de Hamming recibido del transmisor
    output wire [3:0] data_out, //Datos corregidos
    output wire [6:0] seg_7, //Salida para el display de 7 segmentos
    output wire [3:0] leds_out 

);

    //Instanciamos el corrector de error
    corrector_error corrector (
        .recibido(data_in),
        .sindrome({data_in[6], data_in[5], data_in[3]}), //Calculamos el sindrome a partir de los bits de paridad
        .dato_corregido(data_out)
    );

    //Instanciamos el decodificador para el display de 7 segmentos 
    recep_7_seg decodificador (
        .data_in(data_out),
        .data_out(seg_7)
    );     

    LEDS_display leds (
        .data_corregida(data_out),
        .leds(leds_out)
    );

    
    
endmodule
