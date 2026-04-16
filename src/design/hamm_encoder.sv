
//Como input se recibe el mensaje de 4 bits y como output genera un código de hamming con 4 bits de información y 3 de paridad
module hamm_encoder (
    input wire [3:0] data_in, output[6:0] data_out);  // porque se trabaja con Hamming (7,4)

    wire d0, d1, d2, d3;  //cables internos para los bits de información

    wire p1, p2, p3;  //cables internos para bits de paridad


    assign p1 = data_in[0] ^ data_in[1] ^ data_in[3] ; //chequea datos en posiciones 0, 1 y 3
    assign p2 = data_in[0] ^ data_in[2] ^ data_in[3] ; //chequea datos en posiciones 0, 2 y 3
    assign p3 = data_in[1] ^ data_in[2] ^ data_in[3]; //chequea datos en posiciones 1, 2 y 3


    //Asignamos el output del código de Hamming. Este va en el orden:
    // d3 | d2 | d1 | p3 | d0 | p2 | p1 |
    assign data_out = {data_in[3], data_in[2], data_in[1], p3, data_in[0], p2, p1};

endmodule
