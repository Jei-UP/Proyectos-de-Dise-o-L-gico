module top_trans (
    //Inputs

    input wire [3:0] sw_datos,  //switches D3 al D0
    input wire [2:0] sw_error,  //Switches S2 al S0

    output wire [6:0] bus_salida, //Los cables que mandamos a la FPGA del otro grupo
    output wire [6:0] display_tx); //Display que monitorea lo que enviamos
    

    //TRANSMISOR

    wire [6:0] cable_ham_limpio;

    hamm_encoder modulo_enc (.data_in(sw_datos), .data_out(cable_ham_limpio));

    inyector_error modulo_inj (.msj_puro(cable_ham_limpio), .sw_error(sw_error), .msj_con_error(bus_salida));

    trans_7_seg vis_tx (.datos(sw_datos), .seg_7(display_tx));



    
endmodule