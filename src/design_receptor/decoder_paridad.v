
//Módulo que toma el mensaje recibido y calcula la paridad de estos para luego enviarlos al corrector

module decoder_paridad (
    input wire [6:0] recibido,    //R7 a R1
    output wire [2:0] pos_error);  //s2, s1 y s0


    //Se hace un mapeo del mensaje recibido

    wire r7 = recibido[6],
    r6 = recibido[5],
    r5 = recibido[4],
    r4 = recbido[3],
    r3 = recibido[2],
    r2 = recibido[1],
    r1 = recibido[0];

    //Ecuaciones para síndromes (XORs)
    wire s0 = r1 ^ r3 ^ r5 ^ r7;
    wire s1 = r2 ^ r3 ^ r6 ^ r7;
    wire s2 = r4 ^ r5 ^ r6 ^ r7;

    //Mandamos bits al bus de salida

    assign pos_error = {s2, s1, s0};


    
endmodule