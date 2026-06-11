module divider_pipelined (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       valid,
    input  logic [6:0] A, // Dividendo ampliado a 7 bits (Máx 127)
    input  logic [4:0] B, // Divisor ampliado a 5 bits (Máx 31)
    output logic [6:0] Q, // Cociente resultante de 7 bits
    output logic [4:0] R, // Residuo resultante de 5 bits
    output logic       done
);

    // -------------------------------------------------------------------------
    // ETAPA 1 (Registro de Flanco 1) - Procesa Fila i=6 y Fila i=5
    // -------------------------------------------------------------------------
    logic [4:0] r_st1;
    logic [1:0] q_st1;
    logic [4:0] a_st1;
    logic [4:0] b_st1;
    logic       v_st1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_st1 <= 5'b0;
            q_st1 <= 2'b0;
            a_st1 <= 5'b0;
            b_st1 <= 5'b0;
            v_st1 <= 1'b0;
        end else begin
            logic [5:0] r_temp6, d_temp6;
            logic [5:0] r_temp5, d_temp5;
            logic [4:0] r_w6, r_w5;
            logic       q_w6, q_w5;
            
            // --- Fila i = 6 ---
            r_temp6 = {5'b00000, A[6]};
            d_temp6 = r_temp6 - {1'b0, B};
            q_w6    = !d_temp6[5];
            r_w6    = d_temp6[5] ? r_temp6[4:0] : d_temp6[4:0];

            // --- Fila i = 5 ---
            r_temp5 = {r_w6, A[5]};
            d_temp5 = r_temp5 - {1'b0, B};
            q_w5    = !d_temp5[5];
            r_w5    = d_temp5[5] ? r_temp5[4:0] : d_temp5[4:0];
            
            r_st1 <= r_w5;
            q_st1 <= {q_w6, q_w5};
            a_st1 <= A[4:0]; 
            b_st1 <= B;
            v_st1 <= valid;
        end
    end

    // -------------------------------------------------------------------------
    // ETAPA 2 (Registro de Flanco 2) - Procesa Fila i=4 y Fila i=3
    // -------------------------------------------------------------------------
    logic [4:0] r_st2;
    logic [3:0] q_st2;
    logic [2:0] a_st2;
    logic [4:0] b_st2;
    logic       v_st2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_st2 <= 5'b0;
            q_st2 <= 4'b0;
            a_st2 <= 3'b0;
            b_st2 <= 5'b0;
            v_st2 <= 1'b0;
        end else begin
            logic [5:0] r_temp4, d_temp4;
            logic [5:0] r_temp3, d_temp3;
            logic [4:0] r_w4, r_w3;
            logic       q_w4, q_w3;
            
            // --- Fila i = 4 ---
            r_temp4 = {r_st1, a_st1[4]};
            d_temp4 = r_temp4 - {1'b0, b_st1};
            q_w4    = !d_temp4[5];
            r_w4    = d_temp4[5] ? r_temp4[4:0] : d_temp4[4:0];

            // --- Fila i = 3 ---
            r_temp3 = {r_w4, a_st1[3]};
            d_temp3 = r_temp3 - {1'b0, b_st1};
            q_w3    = !d_temp3[5];
            r_w3    = d_temp3[5] ? r_temp3[4:0] : d_temp3[4:0];
            
            r_st2 <= r_w3;
            q_st2 <= {q_st1, q_w4, q_w3};
            a_st2 <= a_st1[2:0];
            b_st2 <= b_st1;
            v_st2 <= v_st1;
        end
    end

    // -------------------------------------------------------------------------
    // ETAPA 3 (Registro de Flanco 3) - Procesa Fila i=2 y Fila i=1
    // -------------------------------------------------------------------------
    logic [4:0] r_st3;
    logic [5:0] q_st3;
    logic       a_st3;
    logic [4:0] b_st3;
    logic       v_st3;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_st3 <= 5'b0;
            q_st3 <= 6'b0;
            a_st3 <= 1'b0;
            b_st3 <= 5'b0;
            v_st3 <= 1'b0;
        end else begin
            logic [5:0] r_temp2, d_temp2;
            logic [5:0] r_temp1, d_temp1;
            logic [4:0] r_w2, r_w1;
            logic       q_w2, q_w1;
            
            // --- Fila i = 2 (CORREGIDO: Ahora usa b_st2) ---
            r_temp2 = {r_st2, a_st2[2]};
            d_temp2 = r_temp2 - {1'b0, b_st2};
            q_w2    = !d_temp2[5];
            r_w2    = d_temp2[5] ? r_temp2[4:0] : d_temp2[4:0];

            // --- Fila i = 1 (CORREGIDO: Ahora usa b_st2) ---
            r_temp1 = {r_w2, a_st2[1]};
            d_temp1 = r_temp1 - {1'b0, b_st2};
            q_w1    = !d_temp1[5];
            r_w1    = d_temp1[5] ? r_temp1[4:0] : d_temp1[4:0];
            
            r_st3 <= r_w1;
            q_st3 <= {q_st2, q_w2, q_w1};
            a_st3 <= a_st2[0]; 
            b_st3 <= b_st2; // CORREGIDO: Transmite el divisor real de la etapa anterior
            v_st3 <= v_st2;
        end
    end

    // -------------------------------------------------------------------------
    // ETAPA 4 (Registros de Salida - Ciclo 4) - Procesa Fila i=0
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Q    <= 7'b0;
            R    <= 5'b0;
            done <= 1'b0;
        end else begin
            logic [5:0] r_temp0, d_temp0;
            logic [4:0] r_w0;
            logic       q_w0;
            
            // --- Fila i = 0 ---
            r_temp0 = {r_st3, a_st3};
            d_temp0 = r_temp0 - {1'b0, b_st3};
            q_w0    = !d_temp0[5];
            r_w0    = d_temp0[5] ? r_temp0[4:0] : d_temp0[4:0];
            
            Q    <= {q_st3, q_w0}; 
            R    <= r_w0;          
            done <= v_st3;         
        end
    end

endmodule