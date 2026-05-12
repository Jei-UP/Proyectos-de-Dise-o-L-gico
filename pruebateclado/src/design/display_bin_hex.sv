module display_bin_hex (
    input  logic [3:0] switch,
    output logic [6:0] seven // a b c d e f g (ACTIVO-ALTO, cátodo común)
);
    always_comb begin
        seven = 7'b0000000; // apagado
        case (switch)
            4'b0000: seven = 7'b1111110; // 0
            4'b0001: seven = 7'b0110000; // 1
            4'b0010: seven = 7'b1101101; // 2
            4'b0011: seven = 7'b1111001; // 3
            4'b0100: seven = 7'b0110011; // 4
            4'b0101: seven = 7'b1011011; // 5
            4'b0110: seven = 7'b1011111; // 6
            4'b0111: seven = 7'b1110000; // 7
            4'b1000: seven = 7'b1111111; // 8
            4'b1001: seven = 7'b1111011; // 9
            4'b1010: seven = 7'b1110111; // A
            4'b1011: seven = 7'b0011111; // b
            4'b1100: seven = 7'b1001110; // c
            4'b1101: seven = 7'b0111101; // d
            4'b1111: seven = 7'b0000000; // apagado
            default: seven = 7'b0000000;
        endcase
    end
endmodule