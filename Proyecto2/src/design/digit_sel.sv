module digit_sel (
    input wire [1:0] sel,
    input wire [1:0] mode,      // 00=A, 01=B, 10=S

    input wire [11:0] A,
    input wire [11:0] B,
    input wire [15:0] S,

    output reg [3:0] dig_in
);

    always @(*) begin
        case (mode)

            2'b00: begin // A
                case (sel)
                    2'b00: dig_in = A[3:0];
                    2'b01: dig_in = A[7:4];
                    2'b10: dig_in = A[11:8];
                    2'b11: dig_in = 4'd0;
                endcase
            end

            2'b01: begin // B
                case (sel)
                    2'b00: dig_in = B[3:0];
                    2'b01: dig_in = B[7:4];
                    2'b10: dig_in = B[11:8];
                    2'b11: dig_in = 4'd0;
                endcase
            end

            2'b10: begin // S
                case (sel)
                    2'b00: dig_in = S[3:0];
                    2'b01: dig_in = S[7:4];
                    2'b10: dig_in = S[11:8];
                    2'b11: dig_in = S[15:12];
                endcase
            end

            default: dig_in = 4'd0;
        endcase
    end

endmodule