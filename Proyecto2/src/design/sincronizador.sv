module sincronizador #(
    parameter STAGES = 2    // siempre 2 para este caso
)(
    input  logic clk,
    input  logic async_in,  // señal cruda del teclado (fila)
    output logic sync_out   // señal sincronizada, lista para usar
);

    // los dos flip-flops en serie
    logic [STAGES-1:0] cadena;

    always_ff @(posedge clk) begin
        cadena <= {cadena[STAGES-2:0], async_in};
    end

    assign sync_out = cadena[STAGES-1];

endmodule