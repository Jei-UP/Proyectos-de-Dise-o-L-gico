module fsm_teclado (
    input  logic       clk,
    input  logic       rst,
    input  logic       tecla_valida,
    input  logic [3:0] tecla,
    output logic [9:0] numero1,
    output logic [9:0] numero2,
    output logic       suma_ready
);

    typedef enum logic [2:0] {
        ESPERA_NUM1  = 3'd0,
        CAPTURA_NUM1 = 3'd1,
        ESPERA_NUM2  = 3'd2,
        CAPTURA_NUM2 = 3'd3,
        LISTO        = 3'd4
    } estado_t;

    estado_t     estado;
    logic [1:0]  cant_digitos;
    logic        es_digito;
    logic        es_confirmar;
    logic        es_reset;

    assign es_digito    = tecla_valida && (tecla <= 4'd9);
    assign es_confirmar = tecla_valida && (tecla == 4'd15);
    assign es_reset     = tecla_valida && (tecla == 4'd14);

    always_ff @(posedge clk) begin

        suma_ready <= 1'b0;

        if (rst || es_reset) begin
            estado       <= ESPERA_NUM1;
            numero1      <= '0;
            numero2      <= '0;
            cant_digitos <= '0;

        end else begin
            case (estado)

                ESPERA_NUM1: begin
                    if (es_digito) begin
                        numero1      <= {6'b0, tecla};
                        cant_digitos <= 2'd1;
                        estado       <= CAPTURA_NUM1;
                    end
                end

                CAPTURA_NUM1: begin
                    if (es_digito && cant_digitos < 2'd3) begin
                        numero1      <= (numero1 * 10) + {6'b0, tecla};
                        cant_digitos <= cant_digitos + 1;
                    end
                    if (es_confirmar) begin
                        cant_digitos <= '0;
                        estado       <= ESPERA_NUM2;
                    end
                end

                ESPERA_NUM2: begin
                    if (es_digito) begin
                        numero2      <= {6'b0, tecla};
                        cant_digitos <= 2'd1;
                        estado       <= CAPTURA_NUM2;
                    end
                end

                CAPTURA_NUM2: begin
                    if (es_digito && cant_digitos < 2'd3) begin
                        numero2      <= (numero2 * 10) + {6'b0, tecla};
                        cant_digitos <= cant_digitos + 1;
                    end
                    if (es_confirmar) begin
                        estado <= LISTO;
                    end
                end

                LISTO: begin
                    suma_ready   <= 1'b1;
                    estado       <= ESPERA_NUM1;
                    numero1      <= '0;
                    numero2      <= '0;
                    cant_digitos <= '0;
                end

            endcase
        end
    end

endmodule