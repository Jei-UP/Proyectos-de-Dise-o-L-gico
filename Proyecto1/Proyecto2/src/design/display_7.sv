module display_7 (
    input wire clk,
    input wire [1:0] sel,
    input wire [3:0] dig_in,
    output wire [7:0] seg_7,
    output reg  [3:0] AN
);

    function [7:0] bcd_to_7seg;
        input [3:0] bcd;
        begin
            case (bcd)
                4'd0: bcd_to_7seg = 8'b0011_1111;
                4'd1: bcd_to_7seg = 8'b0000_0110;
                4'd2: bcd_to_7seg = 8'b0101_1011;
                4'd3: bcd_to_7seg = 8'b0100_1111;
                4'd4: bcd_to_7seg = 8'b0110_0110;
                4'd5: bcd_to_7seg = 8'b0110_1101;
                4'd6: bcd_to_7seg = 8'b0111_1101;
                4'd7: bcd_to_7seg = 8'b0000_0111;
                4'd8: bcd_to_7seg = 8'b0111_1111;
                4'd9: bcd_to_7seg = 8'b0110_1111;
                default: bcd_to_7seg = 8'b0000_0000;
            endcase
        end
    endfunction

    assign seg_7 = bcd_to_7seg(dig_in);  // ✅ usa la función

    always @(*) begin
        case (sel)
            2'b00: AN = 4'b0001;  // ✅ activo alto para NPN
            2'b01: AN = 4'b0010;
            2'b10: AN = 4'b0100;
            2'b11: AN = 4'b1000;
        endcase
    end

endmodule