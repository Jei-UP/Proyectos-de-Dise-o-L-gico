module trans_7_seg (
    input wire [3:0] datos,  // datos D2, D2, D1 Y D0
    output wire [6:0] seg_7 ///a, b, c, d, e, f, g
    );

    assign d3 = datos[3];
    assign d2 = datos[2];
    assign d1 = datos[1];
    assign d0 = datos[0];


    assign seg_7[0] = (d3) | (d2 & ~d1) | (~d2 & d1) | (d1 & ~d0); // este es segmento A

    assign seg_7[1] = (d3 & ~d2 & ~d1) | 
                        (~d3 & d2 & ~d1) | 
                        (~d3 & d2 & ~d0) | 
                        (~d3 & ~d1 & ~d0); // este es segmento B

    assign seg_7[2] = (~d3 & d1 & ~d0) | 
                        (~d2 & ~d1 & d0); // este es segmento C

    assign seg_7[3] = (~d3 & ~d2 & d1) | 
                        (~d3 & d1 & ~d0) | 
                        (~d2 & ~d1 & ~d0) | 
                        (~d3 & d2 & ~d1 & d0); //este es segmento D

    assign seg_7[4] = (~d3 & d2) | 
                        (d3 & d0) |     
                        (~d2 & ~d1); // E

    assign seg_7[5] = (~d3 & ~d2) | 
                        (~d2 & ~d1) | 
                        (~d3 & d1 & d0) | 
                        (~d3 & ~d1 & ~d0); // F

    assign seg_7[6] = (~d3 & d1) | 
                        (~d3 & d2 & d0) | 
                        (d3 & ~d2 & ~d1) | 
                        (~d3 & ~d2 & ~d0); // G

    
endmodule