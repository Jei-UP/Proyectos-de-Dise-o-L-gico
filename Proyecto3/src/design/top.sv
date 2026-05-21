// top.sv - Configuración de Integración Completa para Puntaje Extra (127D / 31D)
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
    logic [3:0] n1_d2, n1_d1, n1_d0; // Dividendo (Soporta 3 dígitos físicos, ej: 1-2-7)
    logic [3:0] n2_d2, n2_d1, n2_d0; // Divisor
    
    // Señales ampliadas para el Divisor
    logic [6:0] dividendo_bin;
    logic [4:0] divisor_bin;
    logic       div_valid;
    logic       div_done;
    logic [6:0] q_bin;
    logic [4:0] r_bin;
    
    logic       mostrar_residuo;

    // --- Instancia del Escáner de Teclado del Proyecto II ---
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

    // --- Conversión de Entrada: BCD a Binario Ampliado con Casteo Fuerte ---
    always_comb begin
        dividendo_bin = 7'(n1_d2 * 7'd100) + 7'(n1_d1 * 7'd10) + 7'(n1_d0);
        divisor_bin   = 5'(n2_d1 * 4'd10) + 5'(n2_d0); // El divisor llega a 31 (máx 2 dígitos)
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
            div_valid <= 1'b0;

            case (state)
                INGRESO_DIVIDENDO: begin
                    if (key_valid) begin
                        if (key_code == 4'hE) begin 
                            {n1_d2, n1_d1, n1_d0} <= '0;
                            en_mask <= 4'b0000;
                        end else if (key_code == 4'hF) begin 
                            state   <= INGRESO_DIVISOR;
                            en_mask <= 4'b0000; 
                        end else if (key_code <= 4'h9) begin 
                            en_mask <= {en_mask[2:0], 1'b1};
                            n1_d2   <= n1_d1;
                            n1_d1   <= n1_d0;
                            n1_d0   <= key_code;
                        end
                    end
                end

                INGRESO_DIVISOR: begin
                    if (key_valid) begin
                        if (key_code == 4'hE) begin 
                            {n2_d2, n2_d1, n2_d0} <= '0;
                            en_mask <= 4'b0000;
                        end else if (key_code == 4'hF) begin 
                            state <= START_DIV;
                        end else if (key_code <= 4'h9) begin 
                            en_mask <= {en_mask[2:0], 1'b1};
                            n2_d2   <= n2_d1;
                            n2_d1   <= n2_d0;
                            n2_d0   <= key_code;
                        end
                    end
                end

                START_DIV: begin
                    div_valid <= 1'b1; 
                    state     <= WAIT_DIV;
                end

                WAIT_DIV: begin
                    if (div_done) begin 
                        state   <= MOSTRAR_RESULTADO;
                        en_mask <= 4'b1111; 
                    end
                end

                MOSTRAR_RESULTADO: begin
                    if (key_valid) begin
                        if (key_code == 4'hE || key_code == 4'hF) begin 
                            state           <= INGRESO_DIVIDENDO;
                            en_mask         <= 4'b0000;
                            {n1_d2, n1_d1, n1_d0} <= '0;
                            {n2_d2, n2_d1, n2_d0} <= '0;
                            mostrar_residuo <= 1'b0;
                        end else if (key_code == 4'hA) begin 
                            mostrar_residuo <= ~mostrar_residuo;
                        end
                    end
                end

                default: state <= INGRESO_DIVIDENDO;
            endcase
        end
    end

    // --- Instancia del Divisor Segmentado Ampliado ---
    divider_pipelined u_divider (
        .clk(clk), .rst_n(rst_n), .valid(div_valid),
        .A(dividendo_bin), .B(divisor_bin),
        .Q(q_bin), .R(r_bin), .done(div_done)
    );

    // --- Conversión de Salida Avanzada: Binario a BCD de 3 dígitos ---
    logic [3:0] q_bcd_d2, q_bcd_d1, q_bcd_d0;
    logic [3:0] r_bcd_d1, r_bcd_d0;

    always_comb begin
        // El cociente puede llegar a 127, requiriendo centenas, decenas y unidades
        q_bcd_d2 = q_bin / 7'd100;
        q_bcd_d1 = (q_bin % 7'd100) / 7'd10;
        q_bcd_d0 = q_bin % 7'd10;
        
        // El residuo máximo es menor a 31, requiere solo decenas y unidades
        r_bcd_d1 = {2'b00, r_bin} / 5'd10;
        r_bcd_d0 = {2'b00, r_bin} % 5'd10;
    end

    // --- Multiplexor de Selección de Pantalla Inteligente ---
    logic [3:0] d3, d2, d1, d0;
    always_comb begin
        case (state)
            INGRESO_DIVIDENDO: {d3, d2, d1, d0} = {4'h0, n1_d2, n1_d1, n1_d0};
            INGRESO_DIVISOR:   {d3, d2, d1, d0} = {4'h0, n2_d2, n2_d1, n2_d0};
            START_DIV, WAIT_DIV: {d3, d2, d1, d0} = '0;
            MOSTRAR_RESULTADO: begin
                if (mostrar_residuo)
                    {d3, d2, d1, d0} = {4'hD, 4'h0, r_bcd_d1, r_bcd_d0}; // Imprime: "d  30"
                else
                    {d3, d2, d1, d0} = {4'hC, q_bcd_d2, q_bcd_d1, q_bcd_d0}; // Imprime: "C127" (Aprovecha los 4 dígitos)
            end
            default: {d3, d2, d1, d0} = '0;
        endcase
    end

    // --- Instancia del Display del Proyecto II ---
    seven_seg_display u_display (
        .clk(clk), .rst_n(rst_n),
        .digit0(d0), .digit1(d1), .digit2(d2), .digit3(d3),
        .en_mask(en_mask),
        .seg_7(seg_7), .AN(AN)
    );

endmodule