// top.sv - Integración Final: FSM, Suma BCD y Blanking
module top (
    input  logic       clk,      // Reloj de 27 MHz [cite: 34, 110]
    input  logic       rst_n,    // Reset físico (Botón S1/S2)
    input  logic [3:0] filas_raw,
    output logic [3:0] columnas,
    output logic [6:0] seg_7,
    output logic [3:0] AN
);

    // --- Señales de Interconexión ---
    logic [3:0] key_code;
    logic       key_valid;
    logic [3:0] en_mask; // Máscara para encender/apagar dígitos (Blanking)
    
    // Registros para Operandos (Dígitos individuales BCD)
    logic [3:0] n1_d2, n1_d1, n1_d0;
    logic [3:0] n2_d2, n2_d1, n2_d0;
    
    // Registros para el Resultado (Hasta 4 dígitos)
    logic [3:0] res_d3, res_d2, res_d1, res_d0;

    // --- Instancia del Escáner de Teclado ---
    keypad_scanner u_scanner (
        .clk(clk), .rst_n(rst_n), .filas_raw(filas_raw),
        .columnas(columnas), .key_code(key_code), .key_valid(key_valid)
    );

    // --- Máquina de Estados (FSM) ---
    typedef enum logic [1:0] {
        INGRESO_N1,
        INGRESO_N2,
        MOSTRAR_SUMA
    } state_t;

    state_t state;

    // --- Lógica de Control Principal (Sincrónica) ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= INGRESO_N1;
            en_mask <= 4'b0000;
            {n1_d2, n1_d1, n1_d0} <= '0;
            {n2_d2, n2_d1, n2_d0} <= '0;
        end else if (key_valid) begin
            case (key_code)
                // TECLA RESET (*)
                4'hE: begin 
                    state <= INGRESO_N1;
                    en_mask <= 4'b0000;
                    {n1_d2, n1_d1, n1_d0} <= '0;
                    {n2_d2, n2_d1, n2_d0} <= '0;
                end

                // TECLA ENTER (#)
                4'hF: begin 
                    case (state)
                        INGRESO_N1: begin
                            state <= INGRESO_N2;
                            en_mask <= 4'b0000; // Limpia el display para el 2do número
                        end
                        INGRESO_N2: begin
                            state <= MOSTRAR_SUMA;
                            en_mask <= 4'b1111; // Enciende todos para ver el resultado
                        end
                        MOSTRAR_SUMA: begin
                            state <= INGRESO_N1;
                            en_mask <= 4'b0000;
                            {n1_d2, n1_d1, n1_d0} <= '0;
                            {n2_d2, n2_d1, n2_d0} <= '0;
                        end
                    endcase
                end

                // TECLAS NUMÉRICAS (0-9) - Solución Robusta
                4'h0, 4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8, 4'h9: begin
                    if (state != MOSTRAR_SUMA) begin
                        // Actualiza la máscara de blanking (desplazamiento a la izquierda)
                        en_mask <= {en_mask[2:0], 1'b1};
                        
                        // Captura del número (Shift Register de dígitos)
                        if (state == INGRESO_N1) begin
                            n1_d2 <= n1_d1; n1_d1 <= n1_d0; n1_d0 <= key_code;
                        end else if (state == INGRESO_N2) begin
                            n2_d2 <= n2_d1; n2_d1 <= n2_d0; n2_d0 <= key_code;
                        end
                    end
                end

                // TECLAS A, B, C, D: Ignoradas
                default: ; 
            endcase
        end
    end

    // --- Sumador BCD (Combinacional) ---
    // Realiza la suma dígito por dígito para ahorrar espacio en la FPGA
    logic [4:0] s0, s1, s2; // 5 bits para el acarreo
    always_comb begin
        // Unidades
        s0 = n1_d0 + n2_d0;
        if (s0 > 9) begin res_d0 = s0 - 10; s1 = n1_d1 + n2_d1 + 1; end
        else        begin res_d0 = s0[3:0]; s1 = n1_d1 + n2_d1;     end
        
        // Decenas
        if (s1 > 9) begin res_d1 = s1 - 10; s2 = n1_d2 + n2_d2 + 1; end
        else        begin res_d1 = s1[3:0]; s2 = n1_d2 + n2_d2;     end
        
        // Centenas y Millar (acarreo final)
        if (s2 > 9) begin res_d2 = s2 - 10; res_d3 = 4'd1; end
        else        begin res_d2 = s2[3:0]; res_d3 = 4'd0; end
    end

    // --- Multiplexor de Pantalla ---
    logic [3:0] d3, d2, d1, d0;
    always_comb begin
        case (state)
            INGRESO_N1:   {d3, d2, d1, d0} = {4'h0, n1_d2, n1_d1, n1_d0};
            INGRESO_N2:   {d3, d2, d1, d0} = {4'h0, n2_d2, n2_d1, n2_d0};
            MOSTRAR_SUMA: {d3, d2, d1, d0} = {res_d3, res_d2, res_d1, res_d0};
            default:      {d3, d2, d1, d0} = '0;
        endcase
    end

    // --- Instancia del Display con Blanking ---
    seven_seg_display u_display (
        .clk(clk), .rst_n(rst_n),
        .digit0(d0), .digit1(d1), .digit2(d2), .digit3(d3),
        .en_mask(en_mask),
        .seg_7(seg_7), .AN(AN)
    );

endmodule