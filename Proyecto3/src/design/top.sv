// top.sv - Integración Final Corregida: FSM con Cobertura de Dígitos Explícita
module top (
    input  logic       clk,      
    input  logic       rst_n,    
    input  logic [3:0] filas_raw,
    output logic [3:0] columnas,
    output logic [6:0] seg_7,
    output logic [3:0] AN
);

    // --- Señales de Interconexión ---
    logic [3:0] key_code;
    logic       key_valid;
    logic [3:0] en_mask; 
    
    // Registros para Operandos BCD
    logic [3:0] n1_d2, n1_d1, n1_d0; 
    logic [3:0] n2_d2, n2_d1, n2_d0; 
    
    // Señales ampliadas para el Divisor
    logic [6:0] dividendo_bin;
    logic [4:0] divisor_bin;
    logic       div_valid;
    logic       div_done;
    logic [6:0] q_bin;
    logic [4:0] r_bin;
    
    logic       mostrar_residuo;

    // --- Instancia del Escáner de Teclado ---
    keypad_scanner u_scanner (
        .clk(clk), .rst_n(rst_n), .filas_raw(filas_raw),
        .columnas(columnas), .key_code(key_code), .key_valid(key_valid)
    );

    // --- Máquina de Estados (FSM) ---
    typedef enum logic [2:0] {
        INGRESO_DIVIDENDO,
        INGRESO_DIVISOR,
        START_DIV,
        WAIT_DIV,
        MOSTRAR_RESULTADO
    } state_t;
    state_t state;

    // --- Conversión de Entrada: BCD a Binario ---
    always_comb begin
        dividendo_bin = 7'(n1_d2 * 7'd100) + 7'(n1_d1 * 7'd10) + 7'(n1_d0);
        divisor_bin   = 5'(n2_d1 * 4'd10) + 5'(n2_d0); 
    end

    // --- Lógica de Control de la FSM (Sincrónica) ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= INGRESO_DIVIDENDO;
            en_mask         <= 4'b0000;
            {n1_d2, n1_d1, n1_d0} <= '0;
            {n2_d2, n2_d1, n2_d0} <= '0;
            div_valid       <= 1'b0;
            mostrar_residuo <= 1'b0;
        end else begin
            div_valid <= 1'b0; // Pulso por defecto

            case (state)
                // ---------------------------------------------------------
                INGRESO_DIVIDENDO: begin
                    if (key_valid) begin
                        case (key_code)
                            4'hE: begin // Tecla '*' (Clear)
                                {n1_d2, n1_d1, n1_d0} <= '0;
                                en_mask <= 4'b0000;
                            end
                            4'hF: begin // Tecla '#' (Enter)
                                state   <= INGRESO_DIVISOR;
                                en_mask <= 4'b0000; 
                            end
                            // LISTA EXPLÍCITA (Estilo robusto del Proyecto II)
                            4'h0, 4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8, 4'h9: begin
                                en_mask <= {en_mask[2:0], 1'b1};
                                n1_d2   <= n1_d1;
                                n1_d1   <= n1_d0;
                                n1_d0   <= key_code;
                            end
                            default: ; // Ignora letras A, B, C, D
                        endcase
                    end
                end

                // ---------------------------------------------------------
                INGRESO_DIVISOR: begin
                    if (key_valid) begin
                        case (key_code)
                            4'hE: begin // Tecla '*' (Clear)
                                {n2_d2, n2_d1, n2_d0} <= '0;
                                en_mask <= 4'b0000;
                            end
                            4'hF: begin // Tecla '#' (Calcular)
                                state <= START_DIV;
                            end
                            // LISTA EXPLÍCITA
                            4'h0, 4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8, 4'h9: begin
                                en_mask <= {en_mask[2:0], 1'b1};
                                n2_d2   <= n2_d1;
                                n2_d1   <= n2_d0;
                                n2_d0   <= key_code;
                            end
                            default: ; 
                        endcase
                    end
                end

                // ---------------------------------------------------------
                START_DIV: begin
                    div_valid <= 1'b1; 
                    state     <= WAIT_DIV;
                end

                // ---------------------------------------------------------
                WAIT_DIV: begin
                    if (div_done) begin 
                        state   <= MOSTRAR_RESULTADO;
                        en_mask <= 4'b1111; 
                    end
                end

                // ---------------------------------------------------------
                MOSTRAR_RESULTADO: begin
                    if (key_valid) begin
                        case (key_code)
                            4'hE, 4'hF: begin // '*' o '#' regresan al inicio
                                state           <= INGRESO_DIVIDENDO;
                                en_mask         <= 4'b0000;
                                {n1_d2, n1_d1, n1_d0} <= '0;
                                {n2_d2, n2_d1, n2_d0} <= '0;
                                mostrar_residuo <= 1'b0;
                            end
                            4'hA: begin // Tecla 'A' conmuta visualización
                                mostrar_residuo <= ~mostrar_residuo;
                            end
                            default: ;
                        endcase
                    end
                end

                default: state <= INGRESO_DIVIDENDO;
            endcase
        end
    end

    // --- Instancia del Divisor Segmentado ---
    divider_pipelined u_divider (
        .clk(clk), .rst_n(rst_n), .valid(div_valid),
        .A(dividendo_bin), .B(divisor_bin),
        .Q(q_bin), .R(r_bin), .done(div_done)
    );

    // --- Conversión de Salida: Binario a BCD de 3 dígitos ---
    logic [3:0] q_bcd_d2, q_bcd_d1, q_bcd_d0;
    logic [3:0] r_bcd_d1, r_bcd_d0;

    always_comb begin
        q_bcd_d2 = q_bin / 7'd100;
        q_bcd_d1 = (q_bin % 7'd100) / 7'd10;
        q_bcd_d0 = q_bin % 7'd10;
        
        r_bcd_d1 = {2'b00, r_bin} / 5'd10;
        r_bcd_d0 = {2'b00, r_bin} % 5'd10;
    end

    // --- Multiplexor de Selección de Pantalla ---
    logic [3:0] d3, d2, d1, d0;
    always_comb begin
        case (state)
            INGRESO_DIVIDENDO: {d3, d2, d1, d0} = {4'h0, n1_d2, n1_d1, n1_d0};
            INGRESO_DIVISOR:   {d3, d2, d1, d0} = {4'h0, n2_d2, n2_d1, n2_d0};
            START_DIV, WAIT_DIV: {d3, d2, d1, d0} = '0;
            MOSTRAR_RESULTADO: begin
                if (mostrar_residuo)
                    {d3, d2, d1, d0} = {4'hD, 4'h0, r_bcd_d1, r_bcd_d0}; 
                else
                    {d3, d2, d1, d0} = {4'hC, q_bcd_d2, q_bcd_d1, q_bcd_d0}; 
            end
            default: {d3, d2, d1, d0} = '0;
        endcase
    end

    // --- Instancia del Display ---
    seven_seg_display u_display (
        .clk(clk), .rst_n(rst_n),
        .digit0(d0), .digit1(d1), .digit2(d2), .digit3(d3),
        .en_mask(en_mask),
        .seg_7(seg_7), .AN(AN)
    );

endmodule