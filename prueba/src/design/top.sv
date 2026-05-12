module top (
    input  logic       clk,      // 27 MHz [cite: 34, 110]
    input  logic       rst_n,
    input  logic [3:0] filas_raw,
    output logic [3:0] columnas,
    output logic [6:0] seg_7,
    output logic [3:0] AN
);

    logic [3:0] key_code;
    logic       key_valid;
    
    // Registros para Operando 1 (3 dígitos) y Operando 2 (3 dígitos)
    logic [3:0] n1_d2, n1_d1, n1_d0;
    logic [3:0] n2_d2, n2_d1, n2_d0;
    
    // Registros para el Resultado de la Suma (Hasta 4 dígitos)
    logic [3:0] res_d3, res_d2, res_d1, res_d0;

    keypad_scanner u_scanner (
        .clk(clk), .rst_n(rst_n), .filas_raw(filas_raw),
        .columnas(columnas), .key_code(key_code), .key_valid(key_valid)
    );

    typedef enum logic [1:0] {INGRESO_N1, INGRESO_N2, MOSTRAR_SUMA} state_t;
    state_t state;

    // --- LÓGICA DE CONTROL Y SUMA BCD ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= INGRESO_N1;
            {n1_d2, n1_d1, n1_d0} <= '0;
            {n2_d2, n2_d1, n2_d0} <= '0;
        end else if (key_valid) begin
            case (key_code)
                4'hE: begin // RESET (*)
                    state <= INGRESO_N1;
                    {n1_d2, n1_d1, n1_d0} <= '0;
                    {n2_d2, n2_d1, n2_d0} <= '0;
                end
                4'hF: begin // ENTER (#)
                    if (state == INGRESO_N1) state <= INGRESO_N2;
                    else if (state == INGRESO_N2) state <= MOSTRAR_SUMA;
                    else state <= INGRESO_N1;
                end
                4'h0, 4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8, 4'h9: begin
                    if (state == INGRESO_N1) begin
                        n1_d2 <= n1_d1; n1_d1 <= n1_d0; n1_d0 <= key_code;
                    end else if (state == INGRESO_N2) begin
                        n2_d2 <= n2_d1; n2_d1 <= n2_d0; n2_d0 <= key_code;
                    end
                end
            endcase
        end
    end

    // --- SUMADOR BCD COMBINACIONAL (Sin divisiones) ---
    logic [4:0] s0, s1, s2; // 5 bits para detectar el acarreo
    always_comb begin
        // Suma Unidades
        s0 = n1_d0 + n2_d0;
        if (s0 > 9) begin res_d0 = s0 - 10; s1 = n1_d1 + n2_d1 + 1; end
        else        begin res_d0 = s0;      s1 = n1_d1 + n2_d1;     end
        
        // Suma Decenas
        if (s1 > 9) begin res_d1 = s1 - 10; s2 = n1_d2 + n2_d2 + 1; end
        else        begin res_d1 = s1;      s2 = n1_d2 + n2_d2;     end
        
        // Suma Centenas y Millar (acarreo final)
        if (s2 > 9) begin res_d2 = s2 - 10; res_d3 = 4'd1; end
        else        begin res_d2 = s2;      res_d3 = 4'd0; end
    end

    // --- SELECCIÓN DE DÍGITOS PARA EL DISPLAY ---
    logic [3:0] d3, d2, d1, d0;
    always_comb begin
        case (state)
            INGRESO_N1:   {d3, d2, d1, d0} = {4'h0, n1_d2, n1_d1, n1_d0};
            INGRESO_N2:   {d3, d2, d1, d0} = {4'h0, n2_d2, n2_d1, n2_d0};
            MOSTRAR_SUMA: {d3, d2, d1, d0} = {res_d3, res_d2, res_d1, res_d0};
            default:      {d3, d2, d1, d0} = '0;
        endcase
    end

    seven_seg_display u_display (
        .clk(clk), .rst_n(rst_n),
        .digit0(d0), .digit1(d1), .digit2(d2), .digit3(d3),
        .seg_7(seg_7), .AN(AN)
    );

endmodule