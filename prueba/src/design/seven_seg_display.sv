// =============================================================================
// seven_seg_display.sv - Mapeo corregido (Digit0 = Derecha / AN[3])
// =============================================================================

module seven_seg_display (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [3:0] digit0,   // Derecha (unidades)
    input  logic [3:0] digit1,
    input  logic [3:0] digit2,
    input  logic [3:0] digit3,   // Izquierda (millares)
    output logic [6:0] seg_7,
    output logic [3:0] AN
);

    logic [16:0] refresh_cnt;
    logic [1:0]  digit_sel;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) refresh_cnt <= '0;
        else        refresh_cnt <= refresh_cnt + 1'b1;
    end

    assign digit_sel = refresh_cnt[16:15];

    logic [3:0] current_digit;
    always_comb begin
        case (digit_sel)
            2'd0: current_digit = digit0;
            2'd1: current_digit = digit1;
            2'd2: current_digit = digit2;
            2'd3: current_digit = digit3;
            default: current_digit = 4'h0;
        endcase
    end

    // Mapeo corregido para que digit0 sea el pin AN[3] (derecha)
    // y digit3 sea el pin AN[0] (izquierda)
    always_comb begin
        case (digit_sel)
            2'd0: AN = 4'b1000; // digit0 -> AN[3] (Pin 40)
            2'd1: AN = 4'b0100; // digit1 -> AN[2] (Pin 51)
            2'd2: AN = 4'b0010; // digit2 -> AN[1] (Pin 35)
            2'd3: AN = 4'b0001; // digit3 -> AN[0] (Pin 32)
            default: AN = 4'b0000;
        endcase
    end

    // Decodificador hex -> 7 segmentos (gfedcba) - Activos en ALTO
    always_comb begin
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

endmodule