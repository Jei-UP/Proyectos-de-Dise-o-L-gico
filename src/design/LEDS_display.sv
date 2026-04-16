module LEDS_display (
    input  wire [3:0] data_corregida,
    output wire [3:0] leds
);
    assign leds = data_corregida;
endmodule