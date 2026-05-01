module decoder_paridad (
    input wire [6:0] recibido,     // R7 a R1
    output wire [2:0] pos_error    // s2, s1, s0
);

    //Se hace un mapeo del mensaje recibido

    wire r7, r6, r5, r4, r3, r2, r1;

    assign r7 = recibido[6];
    assign r6 = recibido[5];
    assign r5 = recibido[4];
    assign r4 = recibido[3];
    assign r3 = recibido[2];
    assign r2 = recibido[1];
    assign r1 = recibido[0];
    // -----------------------------
    // Cálculo del síndrome
    // -----------------------------
    wire s0, s1, s2;

    assign s0 = r1 ^ r3 ^ r5 ^ r7;
    assign s1 = r2 ^ r3 ^ r6 ^ r7;
    assign s2 = r4 ^ r5 ^ r6 ^ r7;

    // -----------------------------
    // Salida
    // -----------------------------
    assign pos_error = {s2, s1, s0};

endmodule