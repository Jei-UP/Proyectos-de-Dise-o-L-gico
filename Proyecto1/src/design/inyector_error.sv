// Se le "inyecta" un error al código de Hamming para probar la detección de errores del receptor de otro grupo

module inyector_error (
    input wire [6:0] msj_puro, //Código generado en hamm_encoder
    input wire [2:0] sw_error, //switches de posición (S2, S1 o S0)
    output wire [6:0] msj_con_error);


    //Definimos s2, s1 y s0 desde switches
    wire s2 = sw_error[2];
    wire s1 = sw_error[1];
    wire s0 = sw_error[0];


    //Decoder 3 a 8 que activa 1 de las 8 salidas
   // wire y0 = !s2 & !s1 & !s0 no se añade porque no inyecta ningún error
    wire y1 = !s2 & !s1 & s0; 
    wire y2 = !s2 & s1 & !s0;
    wire y3 = !s2 & s1 & s0;
    wire y4 = s2 & !s1 & !s0;
    wire y5 = s2 & !s1 & s0;
    wire y6 = s2 & s1 & !s0;
    wire y7 = s2 & s1 & s0;

    //Ahora, se inyecta el error con un los XOR en la posición respectiva del mensaje recibido
    assign msj_con_error[0] = msj_puro[0] ^ y1;
    assign msj_con_error[1] = msj_puro[1] ^ y2;
    assign msj_con_error[2] = msj_puro[2] ^ y3;
    assign msj_con_error[3] = msj_puro[3] ^ y4;
    assign msj_con_error[4] = msj_puro[4] ^ y5;
    assign msj_con_error[5] = msj_puro[5] ^ y6;
    assign msj_con_error[6] = msj_puro[6] ^ y7;

endmodule
