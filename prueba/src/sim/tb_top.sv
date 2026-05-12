// =============================================================================
// tb_top.sv
// Testbench de integración para el módulo top.sv
//
// Estrategia:
//   El keypad_scanner tiene tiempos de antirrebote de 20 ms reales (540,000
//   ciclos a 27 MHz), lo que hace inviable simularlo ciclo a ciclo. Por eso
//   este testbench usa un wrapper (top_tb_wrap) que replica la FSM, el sumador
//   BCD y el display de top.sv, pero recibe key_valid/key_code directamente,
//   sin pasar por el scanner. Esto mantiene intacta toda la lógica de negocio.
//
// Casos de prueba:
//   251 + 302 = 553
//   526 +  67 = 593
//   150 + 750 = 900
//   320 + 640 = 960
// =============================================================================
 
`timescale 1ns/1ps
 
module tb_top;
 
    // -------------------------------------------------------------------------
    // Parámetros de simulación
    // -------------------------------------------------------------------------
    localparam CLK_PERIOD = 37;   // ~27 MHz  (37 ns por ciclo)
    localparam KEY_DELAY  = 10;   // ciclos de separación entre teclas
 
    // -------------------------------------------------------------------------
    // Señales del DUT
    // -------------------------------------------------------------------------
    logic       clk;
    logic       rst_n;
    logic [3:0] key_code_drv;
    logic       key_valid_drv;
    logic [6:0] seg_7;
    logic [3:0] AN;
    logic [3:0] en_mask;
 
    // -------------------------------------------------------------------------
    // Instancia del wrapper
    // -------------------------------------------------------------------------
    top_tb_wrap u_top (
        .clk      (clk),
        .rst_n    (rst_n),
        .key_code (key_code_drv),
        .key_valid(key_valid_drv),
        .seg_7    (seg_7),
        .AN       (AN),
        .en_mask  (en_mask)
    );
 
    // -------------------------------------------------------------------------
    // Reloj
    // -------------------------------------------------------------------------
    initial clk = 0;
    always  #(CLK_PERIOD/2) clk = ~clk;
 
    // -------------------------------------------------------------------------
    // Tarea: enviar una tecla (pulso de 1 ciclo en key_valid)
    // -------------------------------------------------------------------------
    task automatic send_key(input logic [3:0] code);
        @(posedge clk);
        key_code_drv  <= code;
        key_valid_drv <= 1'b1;
        @(posedge clk);
        key_valid_drv <= 1'b0;
        repeat(KEY_DELAY) @(posedge clk);
    endtask
 
    // -------------------------------------------------------------------------
    // Tarea: ingresar un número de 3 dígitos BCD y confirmar con '#'
    //   Solo envía las centenas si son != 0 para respetar el shift-register
    //   del top.sv (igual que lo haría un usuario real)
    // -------------------------------------------------------------------------
    task automatic ingresar_numero(
        input logic [3:0] d2,   // centenas
        input logic [3:0] d1,   // decenas
        input logic [3:0] d0    // unidades
    );
        if (d2 != 0)             send_key(d2);
        if (d2 != 0 || d1 != 0) send_key(d1);
        send_key(d0);
        send_key(4'hF);   // '#' = ENTER
    endtask
 
    // -------------------------------------------------------------------------
    // Tarea: verificar el resultado en el display
    // -------------------------------------------------------------------------
    task automatic verificar(
        input string      nombre,
        input logic [3:0] exp_d3,
        input logic [3:0] exp_d2,
        input logic [3:0] exp_d1,
        input logic [3:0] exp_d0
    );
        repeat(5) @(posedge clk);   // estabilización combinacional
 
        $display("------------------------------------------------------------");
        $display("CASO : %s", nombre);
        $display("  Esperado  : d3=%0h d2=%0h d1=%0h d0=%0h  (%0d%0d%0d%0d)",
                  exp_d3, exp_d2, exp_d1, exp_d0,
                  exp_d3, exp_d2, exp_d1, exp_d0);
        $display("  Obtenido  : d3=%0h d2=%0h d1=%0h d0=%0h  en_mask=%b",
                  u_top.d3, u_top.d2, u_top.d1, u_top.d0, en_mask);
        $display("  AN=%b  seg_7=%b", AN, seg_7);
 
        if (u_top.d3 === exp_d3 &&
            u_top.d2 === exp_d2 &&
            u_top.d1 === exp_d1 &&
            u_top.d0 === exp_d0)
            $display("  >>> PASS <<<");
        else
            $display("  >>> FAIL <<< obtenido %h%h%h%h, esperado %h%h%h%h",
                      u_top.d3, u_top.d2, u_top.d1, u_top.d0,
                      exp_d3, exp_d2, exp_d1, exp_d0);
        $display("------------------------------------------------------------");
    endtask
 
    // -------------------------------------------------------------------------
    // Secuencia principal
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
 
        // Reset
        rst_n         = 0;
        key_valid_drv = 0;
        key_code_drv  = 0;
        repeat(10) @(posedge clk);
        rst_n = 1;
        repeat(5)  @(posedge clk);
 
        $display("============================================================");
        $display("  INICIO DE SIMULACION - tb_top");
        $display("============================================================");
 
        // =====================================================================
        // CASO 1: 251 + 302 = 553
        // =====================================================================
        $display("\n[CASO 1]  251 + 302 = 553");
        ingresar_numero(4'd2, 4'd5, 4'd1);   // N1 = 251
        ingresar_numero(4'd3, 4'd0, 4'd2);   // N2 = 302
        verificar("251 + 302 = 553", 4'd0, 4'd5, 4'd5, 4'd3);
        send_key(4'hF);   // avanzar MOSTRAR_SUMA -> INGRESO_N1
        repeat(5) @(posedge clk);
 
        // =====================================================================
        // CASO 2: 526 + 67 = 593
        // =====================================================================
        $display("\n[CASO 2]  526 + 67 = 593");
        ingresar_numero(4'd5, 4'd2, 4'd6);   // N1 = 526
        ingresar_numero(4'd0, 4'd6, 4'd7);   // N2 = 067
        verificar("526 + 67 = 593", 4'd0, 4'd5, 4'd9, 4'd3);
        send_key(4'hF);
        repeat(5) @(posedge clk);
 
        // =====================================================================
        // CASO 3: 150 + 750 = 900
        // =====================================================================
        $display("\n[CASO 3]  150 + 750 = 900");
        ingresar_numero(4'd1, 4'd5, 4'd0);   // N1 = 150
        ingresar_numero(4'd7, 4'd5, 4'd0);   // N2 = 750
        verificar("150 + 750 = 900", 4'd0, 4'd9, 4'd0, 4'd0);
        send_key(4'hF);
        repeat(5) @(posedge clk);
 
        // =====================================================================
        // CASO 4: 320 + 640 = 960
        // =====================================================================
        $display("\n[CASO 4]  320 + 640 = 960");
        ingresar_numero(4'd3, 4'd2, 4'd0);   // N1 = 320
        ingresar_numero(4'd6, 4'd4, 4'd0);   // N2 = 640
        verificar("320 + 640 = 960", 4'd0, 4'd9, 4'd6, 4'd0);
        send_key(4'hF);
        repeat(5) @(posedge clk);
 
        $display("\n============================================================");
        $display("  FIN DE SIMULACION");
        $display("============================================================");
        $finish;
    end
 
    // Timeout de seguridad
    initial begin
        #10_000_000;
        $display("ERROR: Timeout de simulacion.");
        $finish;
    end
 
endmodule
 
 
// =============================================================================
// top_tb_wrap
// Wrapper que replica la lógica de top.sv recibiendo key_valid/key_code
// directamente (sin pasar por keypad_scanner). Permite simulación eficiente.
// =============================================================================
module top_tb_wrap (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [3:0] key_code,
    input  logic       key_valid,
    output logic [6:0] seg_7,
    output logic [3:0] AN,
    output logic [3:0] en_mask
);
 
    // Registros de operandos y resultado (visibles desde el testbench)
    logic [3:0] n1_d2, n1_d1, n1_d0;
    logic [3:0] n2_d2, n2_d1, n2_d0;
    logic [3:0] res_d3, res_d2, res_d1, res_d0;
    logic [3:0] d3, d2, d1, d0;
 
    // FSM
    typedef enum logic [1:0] {
        INGRESO_N1,
        INGRESO_N2,
        MOSTRAR_SUMA
    } state_t;
    state_t state;
 
    // --- Control (idéntico a top.sv) ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= INGRESO_N1;
            en_mask <= 4'b0000;
            {n1_d2, n1_d1, n1_d0} <= '0;
            {n2_d2, n2_d1, n2_d0} <= '0;
        end else if (key_valid) begin
            case (key_code)
                4'hE: begin
                    state   <= INGRESO_N1;
                    en_mask <= 4'b0000;
                    {n1_d2, n1_d1, n1_d0} <= '0;
                    {n2_d2, n2_d1, n2_d0} <= '0;
                end
                4'hF: begin
                    case (state)
                        INGRESO_N1: begin
                            state   <= INGRESO_N2;
                            en_mask <= 4'b0000;
                        end
                        INGRESO_N2: begin
                            state   <= MOSTRAR_SUMA;
                            en_mask <= 4'b1111;
                        end
                        MOSTRAR_SUMA: begin
                            state   <= INGRESO_N1;
                            en_mask <= 4'b0000;
                            {n1_d2, n1_d1, n1_d0} <= '0;
                            {n2_d2, n2_d1, n2_d0} <= '0;
                        end
                    endcase
                end
                4'h0, 4'h1, 4'h2, 4'h3, 4'h4,
                4'h5, 4'h6, 4'h7, 4'h8, 4'h9: begin
                    if (state != MOSTRAR_SUMA) begin
                        en_mask <= {en_mask[2:0], 1'b1};
                        if (state == INGRESO_N1) begin
                            n1_d2 <= n1_d1; n1_d1 <= n1_d0; n1_d0 <= key_code;
                        end else begin
                            n2_d2 <= n2_d1; n2_d1 <= n2_d0; n2_d0 <= key_code;
                        end
                    end
                end
                default: ;
            endcase
        end
    end
 
    // --- Sumador BCD (idéntico a top.sv) ---
    logic [4:0] s0, s1, s2;
    always_comb begin
        s0 = n1_d0 + n2_d0;
        if (s0 > 9) begin res_d0 = s0 - 10; s1 = n1_d1 + n2_d1 + 1; end
        else        begin res_d0 = s0[3:0];  s1 = n1_d1 + n2_d1;     end
        if (s1 > 9) begin res_d1 = s1 - 10; s2 = n1_d2 + n2_d2 + 1; end
        else        begin res_d1 = s1[3:0];  s2 = n1_d2 + n2_d2;     end
        if (s2 > 9) begin res_d2 = s2 - 10; res_d3 = 4'd1; end
        else        begin res_d2 = s2[3:0];  res_d3 = 4'd0; end
    end
 
    // --- Multiplexor de pantalla (idéntico a top.sv) ---
    always_comb begin
        case (state)
            INGRESO_N1:   {d3, d2, d1, d0} = {4'h0, n1_d2, n1_d1, n1_d0};
            INGRESO_N2:   {d3, d2, d1, d0} = {4'h0, n2_d2, n2_d1, n2_d0};
            MOSTRAR_SUMA: {d3, d2, d1, d0} = {res_d3, res_d2, res_d1, res_d0};
            default:      {d3, d2, d1, d0} = '0;
        endcase
    end
 
    // --- Display ---
    seven_seg_display u_display (
        .clk    (clk),
        .rst_n  (rst_n),
        .digit0 (d0),
        .digit1 (d1),
        .digit2 (d2),
        .digit3 (d3),
        .en_mask(en_mask),
        .seg_7  (seg_7),
        .AN     (AN)
    );
 
endmodule