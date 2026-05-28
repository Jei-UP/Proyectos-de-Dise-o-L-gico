// tb_primera_fila.sv
// Testbench para la PRIMERA FILA del divisor pipelineado
// Equivale a la Fila i=6: r_temp = {5'b00000, A[6]}, luego resta B
//
// Operación que se prueba:
//   r_temp = {5'b00000, A[6]}
//   d_temp = r_temp - B
//   q_w6   = !d_temp[5]          (bit de signo invertido)
//   r_w6   = d_temp[5] ? r_temp[4:0] : d_temp[4:0]  (restauración)

`timescale 1ns/1ps

module tb_primera_fila;

    // -------------------------------------------------------------------------
    // DUT: módulo que implementa SOLO la primera fila
    // -------------------------------------------------------------------------
    logic [6:0] A;
    logic [4:0] B;
    logic       q_w6;
    logic [4:0] r_w6;

    primera_fila dut (
        .A   (A),
        .B   (B),
        .q_w6(q_w6),
        .r_w6(r_w6)
    );

    // -------------------------------------------------------------------------
    // Tarea de verificación
    // -------------------------------------------------------------------------
    int errores = 0;
    int pruebas = 0;

    task automatic verificar(
        input logic [6:0] a_in,
        input logic [4:0] b_in,
        input logic       q_esperado,
        input logic [4:0] r_esperado,
        input string      descripcion
    );
        A = a_in;
        B = b_in;
        #10; // esperar propagación combinacional

        pruebas++;
        if (q_w6 !== q_esperado || r_w6 !== r_esperado) begin
            $display("FALLO [%s]", descripcion);
            $display("  A=%b (%0d)  A[6]=%b  B=%b (%0d)",
                      a_in, a_in, a_in[6], b_in, b_in);
            $display("  r_temp = {00000, A[6]} = %b (%0d)",
                      {5'b00000, a_in[6]}, {5'b00000, a_in[6]});
            $display("  q_w6:  obtenido=%b  esperado=%b", q_w6, q_esperado);
            $display("  r_w6:  obtenido=%b (%0d)  esperado=%b (%0d)",
                      r_w6, r_w6, r_esperado, r_esperado);
            errores++;
        end else begin
            $display("OK    [%s]  A[6]=%b  B=%0d  q=%b  r=%0d",
                      descripcion, a_in[6], b_in, q_w6, r_w6);
        end
    endtask

    // -------------------------------------------------------------------------
    // Función para calcular el resultado esperado (modelo de referencia)
    // -------------------------------------------------------------------------
    function automatic void calcular_esperado(
        input  logic [6:0] a_in,
        input  logic [4:0] b_in,
        output logic       q_exp,
        output logic [4:0] r_exp
    );
        logic [5:0] r_temp, d_temp;
        r_temp = {5'b00000, a_in[6]};
        d_temp = r_temp - {1'b0, b_in};
        q_exp  = !d_temp[5];
        r_exp  = d_temp[5] ? r_temp[4:0] : d_temp[4:0];
    endfunction

    // -------------------------------------------------------------------------
    // Estímulos
    // -------------------------------------------------------------------------
    initial begin
        // --- Waveform dump ---
        $dumpfile("tb_primera_fila.vcd");
        $dumpvars(0, tb_primera_fila);

        $display("=======================================================");
        $display(" TESTBENCH: Primera Fila del Divisor (Fila i=6)");
        $display(" Operacion: r_temp={00000,A[6]}, d=r_temp-B");
        $display("            q=!d[5], r=restauracion");
        $display("=======================================================");

        // --- Caso 1: A[6]=0, cualquier B → siempre q=0, r=0 (0 - B < 0) ---
        $display("\n-- Grupo 1: A[6]=0 (r_temp=0), siempre menor que B>0 --");
        verificar(7'b0000000, 5'd1,  1'b0, 5'd0, "A[6]=0 B=1");
        verificar(7'b0000000, 5'd5,  1'b0, 5'd0, "A[6]=0 B=5");
        verificar(7'b0000000, 5'd15, 1'b0, 5'd0, "A[6]=0 B=15");
        verificar(7'b0000000, 5'd31, 1'b0, 5'd0, "A[6]=0 B=31");

        // --- Caso especial: B=0 con A[6]=0 → 0-0=0 → q=1, r=0 ---
        $display("\n-- Grupo 2: B=0 (division por cero, caso borde) --");
        verificar(7'b0000000, 5'd0, 1'b1, 5'd0, "A[6]=0 B=0");
        verificar(7'b1000000, 5'd0, 1'b1, 5'd1, "A[6]=1 B=0");

        // --- Caso 2: A[6]=1, r_temp=1 ---
        $display("\n-- Grupo 3: A[6]=1 (r_temp=1) --");
        // B=1: 1-1=0 → q=1, r=0
        verificar(7'b1000000, 5'd1,  1'b1, 5'd0, "A[6]=1 B=1  (1-1=0)");
        // B=2: 1-2<0 → q=0, r=1 (restaurado)
        verificar(7'b1000000, 5'd2,  1'b0, 5'd1, "A[6]=1 B=2  (1-2<0, restaura)");
        // B=31: 1-31<0 → q=0, r=1
        verificar(7'b1000000, 5'd31, 1'b0, 5'd1, "A[6]=1 B=31 (1-31<0, restaura)");

        // --- Grupo 4: solo A[6] importa, los bits bajos de A son ignorados ---
        $display("\n-- Grupo 4: bits bajos de A son ignorados en esta fila --");
        verificar(7'b1111111, 5'd1,  1'b1, 5'd0, "A=127 B=1 (A[6]=1, 1-1=0)");
        verificar(7'b1111111, 5'd2,  1'b0, 5'd1, "A=127 B=2 (A[6]=1, 1-2<0)");
        verificar(7'b0111111, 5'd1,  1'b0, 5'd0, "A=63  B=1 (A[6]=0, 0-1<0)");
        verificar(7'b0111111, 5'd31, 1'b0, 5'd0, "A=63  B=31(A[6]=0, 0-31<0)");

        // --- Grupo 5: barrido exhaustivo de todos los valores de B con A[6]=1 ---
        $display("\n-- Grupo 5: barrido B=0..31 con A[6]=1 --");
        begin
            logic       q_exp;
            logic [4:0] r_exp;
            string      desc;
            for (int b = 0; b <= 31; b++) begin
                calcular_esperado(7'b1000000, b[4:0], q_exp, r_exp);
                $sformat(desc, "sweep A[6]=1 B=%0d", b);
                verificar(7'b1000000, b[4:0], q_exp, r_exp, desc);
            end
        end

        // --- Grupo 6: barrido exhaustivo de todos los valores de B con A[6]=0 ---
        $display("\n-- Grupo 6: barrido B=0..31 con A[6]=0 --");
        begin
            logic       q_exp;
            logic [4:0] r_exp;
            string      desc;
            for (int b = 0; b <= 31; b++) begin
                calcular_esperado(7'b0000000, b[4:0], q_exp, r_exp);
                $sformat(desc, "sweep A[6]=0 B=%0d", b);
                verificar(7'b0000000, b[4:0], q_exp, r_exp, desc);
            end
        end

        // -------------------------------------------------------------------------
        // Reporte final
        // -------------------------------------------------------------------------
        $display("\n=======================================================");
        $display(" RESULTADO: %0d pruebas, %0d errores", pruebas, errores);
        if (errores == 0)
            $display(" TODAS LAS PRUEBAS PASARON");
        else
            $display(" FALLARON %0d PRUEBA(S)", errores);
        $display("=======================================================");
        $finish;
    end

endmodule


// =============================================================================
// DUT: primera_fila
// Implementa exactamente la Fila i=6 del divider_pipelined
// =============================================================================
module primera_fila (
    input  logic [6:0] A,
    input  logic [4:0] B,
    output logic       q_w6,
    output logic [4:0] r_w6
);
    logic [5:0] r_temp6, d_temp6;

    always_comb begin
        // Paso 1: resto inicial = 0, concatenar A[6]
        r_temp6 = {5'b00000, A[6]};

        // Paso 2: intentar restar B (equivale a sumar complemento a 2)
        d_temp6 = r_temp6 - {1'b0, B};

        // Paso 3: bit de signo invertido = bit de cociente
        q_w6 = !d_temp6[5];

        // Paso 4: restauración — si la resta fue negativa, devolver r_temp
        r_w6 = d_temp6[5] ? r_temp6[4:0] : d_temp6[4:0];
    end

endmodule