// tb_primera_fila.sv
// Testbench para la PRIMERA FILA del divisor pipelineado
// Equivale a la Fila i=6: r_temp = {5'b00000, A[6]}, luego resta B
//
// Operación que se prueba:
//   r_temp = {5'b00000, A[6]}
//   d_temp = r_temp - B
//   q_w6   = !d_temp[5]          (bit de signo invertido)
//   r_w6   = d_temp[5] ? r_temp[4:0] : d_temp[4:0]  (restauración)
//
// Compatibilidad: Icarus Verilog con -g2012
//   iverilog -g2012 -o sim tb_primera_fila.sv && vvp sim
//   gtkwave tb_primera_fila.vcd

