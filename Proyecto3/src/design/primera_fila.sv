// primera_fila.sv
// Implementa ÚNICAMENTE la Fila i=6 del divisor pipelineado
// Equivale a la primera fila del circuito de resta con restauración
//
// Operación:
//   r_temp = {5'b00000, A[6]}   — resto inicial = 0, traer MSB del dividendo
//   d_temp = r_temp - B          — intentar restar el divisor
//   q_w6   = !d_temp[5]          — bit de signo invertido = bit de cociente
//   r_w6   = restauración        — si negativo, devolver r_temp; si no, d_temp

//module primera_fila (
   // input  logic [6:0] A,    // Dividendo de 7 bits (solo se usa A[6])
   // input  logic [4:0] B,    // Divisor de 5 bits
  //  output logic       q_w6, // Bit de cociente de esta fila
  //  output logic [4:0] r_w6  // Resta parcial resultante
//);
    //logic [5:0] r_temp6;  
    //logic [5:0] d_temp6;  

    //assign r_temp6 = {5'b00000, A[6]};       // paso 1: resto inicial
    //assign d_temp6 = r_temp6 - {1'b0, B};    // paso 2: restar B
    //assign q_w6    = !d_temp6[5];             // paso 3: bit de cociente
  //  assign r_w6    = d_temp6[5] ? r_temp6[4:0] : d_temp6[4:0]; // paso 4: restaurar

//endmodule

module primera_fila (
    input  logic [6:0] A,
    input  logic [4:0] B,

    output logic       Q6,
    output logic [4:0] R
);

    logic [4:0] Rp;   // R'
    logic [5:0] Rtemp; // R temporal ampliado a 6 bits para la resta
    logic [5:0] D;  // D temporal ampliado a 6 bits para la resta

    // Paso 1:
    // R' = 0
    assign Rp = 5'b00000;

    // Paso 2:
    // R = {R'[3:0], A6}
    assign Rtemp = {Rp, A[6]};

    // Paso 3:
    // D = R - B
    assign D = Rtemp - {1'b0, B};

    // Paso 4 y 5:
    // si D < 0 => restaurar
    assign R = D[5] ? Rtemp[4:0] : D[4:0];

    // Paso 6:
    // Q6 = 0 si negativo, 1 si positivo
    assign Q6 = !D[5];

endmodule