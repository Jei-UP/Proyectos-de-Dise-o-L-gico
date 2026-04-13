module top_trans (
    //inputs
    input wire [2:0] sw_error, //switches para inyectar error;
    input wire [3:0] data_in, //datos de 4 bits para generar el código de Hamming
    //outputs
    output wire [6:0] data_out, //Código de Hamming generado
    output wire [6:0] data_con_error, //Código de Hamming con error inyectado
    output wire [6:0] seg_7 //Salida para el display de 7 segmentos
    );

    //Instanciamos el encoder de Hamming
    hamm_encoder encoder (
        .data_in(data_in),
        .data_out(data_out)
    );

    //Instanciamos el inyector de error
    inyector_error inyector (
        .msj_puro(data_out),
        .sw_error(sw_error),
        .msj_con_error(data_con_error)
    );          

    //Instanciamos el decodificador para el display de 7 segmentos
    decodificador_7seg decodificador (
        .data_in(data_con_error),
        .data_out(seg_7)
    );


endmodule