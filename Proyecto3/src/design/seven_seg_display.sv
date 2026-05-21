// seven_seg_display.sv - Versión compatible con Yosys y Blanking
module seven_seg_display (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [3:0] digit0, digit1, digit2, digit3,
    input  logic [3:0] en_mask, // 1 = Encendido, 0 = Apagado
    output logic [6:0] seg_7,
    output logic [3:0] AN
);
    // 1. Contador para el refresco de los displays
    logic [16:0] refresh_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) refresh_cnt <= '0;
        else        refresh_cnt <= refresh_cnt + 1'b1;
    end

    // 2. Selección de dígito (Declaración y asignación juntas para evitar errores de ancho)
    // Usamos los bits altos del contador para alternar entre los 4 displays
    wire [1:0] digit_sel = refresh_cnt[16:15];

    logic [3:0] current_digit;
    logic       current_en;

    // 3. Multiplexor de datos y habilitación (Blanking)
    always_comb begin
        case (digit_sel)
            2'd0: begin current_digit = digit0; current_en = en_mask[0]; end
            2'd1: begin current_digit = digit1; current_en = en_mask[1]; end
            2'd2: begin current_digit = digit2; current_en = en_mask[2]; end
            2'd3: begin current_digit = digit3; current_en = en_mask[3]; end
            default: begin current_digit = 4'h0; current_en = 1'b0; end
        endcase
    end

    // 4. Mapeo de ánodos (Activos en ALTO para TangNano) [cite: 292-296]
    always_comb begin
        case (digit_sel)
            2'd0: AN = 4'b1000; // digit0 -> AN[3]
            2'd1: AN = 4'b0100; // digit1 -> AN[2]
            2'd2: AN = 4'b0010; // digit2 -> AN[1]
            2'd3: AN = 4'b0001; // digit3 -> AN[0]
            default: AN = 4'b0000;
        endcase
    end

    // 5. Decodificador Hexadecimal a 7 Segmentos con Blanking
    always_comb begin
        if (!current_en) begin
            seg_7 = 7'b0000000; // Apagado total si la máscara es 0
        end else begin
            case (current_digit)
                4'h0: seg_7 = 7'b0111111;
                4'h1: seg_7 = 7'b0000110;
                4'h2: seg_7 = 7'b1011011;
                4'h3: seg_7 = 7'b1001111;
                4'h4: seg_7 = 7'b1100110;
                4'h5: seg_7 = 7'b1101101;
                4'h6: seg_7 = 7'b1111101;
                4'h7: seg_7 = 7'b0000111;
                4'h8: seg_7 = 7'b1111111;
                4'h9: seg_7 = 7'b1101111;
                4'hA: seg_7 = 7'b1110111;
                4'hB: seg_7 = 7'b1111100;
                4'hC: seg_7 = 7'b0111001;
                4'hD: seg_7 = 7'b1011110;
                4'hE: seg_7 = 7'b1111001;
                4'hF: seg_7 = 7'b1110001;
                default: seg_7 = 7'b0000000;
            endcase
        end
    end

endmodule