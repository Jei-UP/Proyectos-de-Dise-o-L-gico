module display_7 (
    input wire clk,
    input wire [1:0] sel,
    input wire [3:0] dig_in,

    output reg [7:0] seg_7,
    output reg [3:0] AN
);

    // -------- BCD → 7 segmentos --------
    function [7:0] bcd_to_7seg;
        input [3:0] bcd;
        begin
            case (bcd)
                4'd0: bcd_to_7seg = 8'b11000000;
                4'd1: bcd_to_7seg = 8'b11111001;
                4'd2: bcd_to_7seg = 8'b10100100;
                4'd3: bcd_to_7seg = 8'b10110000;
                4'd4: bcd_to_7seg = 8'b10011001;
                4'd5: bcd_to_7seg = 8'b10010010;
                4'd6: bcd_to_7seg = 8'b10000010;
                4'd7: bcd_to_7seg = 8'b11111000;
                4'd8: bcd_to_7seg = 8'b10000000;
                4'd9: bcd_to_7seg = 8'b10010000;
                default: bcd_to_7seg = 8'b11111111;
            endcase
        end
    endfunction

    // -------- registro de salida --------
    always @(posedge clk) begin
        seg_7 <= bcd_to_7seg(dig_in);
    end

    // -------- activación de dígitos --------
    always @(*) begin
        case (sel)
            2'b00: AN = 4'b1110;
            2'b01: AN = 4'b1101;
            2'b10: AN = 4'b1011;
            2'b11: AN = 4'b0111;
        endcase
    end

endmodule