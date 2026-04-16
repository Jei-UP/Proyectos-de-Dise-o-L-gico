module trans_7_seg (
    input  wire [3:0] datos,
    output wire [6:0] seg_7   // seg_7[0]=a, seg_7[1]=b, ..., seg_7[6]=g
);

    wire d3, d2, d1, d0;

    assign d3 = datos[3];
    assign d2 = datos[2];
    assign d1 = datos[1];
    assign d0 = datos[0];

    // Segmento A
    assign seg_7[0] = (~d2 & ~d0) | (d3 & ~d0) | (d2 & d1) |
                      (~d3 & d1)  | (d3 & ~d2 & ~d1) | (~d3 & d2 & d0);

    // Segmento B
    assign seg_7[1] = (~d2 & ~d0) | (~d3 & ~d2) | (~d3 & d1 & ~d0) |
                      (d3 & ~d1 & d0) | (~d3 & d1 & d0);

    // Segmento C
    assign seg_7[2] = (~d3 & d2) | (d3 & ~d2) | (~d1 & d0) |
                      (~d3 & ~d1) | (~d3 & d0);

    // Segmento D
    assign seg_7[3] = (d3 & ~d1)        | (~d2 & d1 & ~d0) | (~d2 & d1 & d0) |
                  (d2 & ~d1 & d0)   | (~d3 & d1 & ~d0) | (d2 & d1 & ~d0) |
                  (~d3 & ~d2 & ~d0); // término que faltaba

    // Segmento E
    assign seg_7[4] = (~d2 & ~d0) | (d3 & d2) | (d3 & d1) | (d1 & ~d0);

    // Segmento F
    assign seg_7[5] = (~d1 & ~d0) | (d3 & ~d2) | (d3 & d1) |
                      (d2 & ~d0)  | (~d3 & d2 & ~d1);

    // Segmento G
    assign seg_7[6] = (d3 & ~d2) | (d1 & ~d0) | (d3 & d0) |
                      (~d3 & d2 & ~d1) | (~d3 & ~d2 & d1);

endmodule