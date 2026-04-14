`timescale 1ns / 1ps
module top_trans_tb;

    // Parámetros
    parameter NUM_PRUEBAS = 16;  // 16 combinaciones posibles de datos de 4 bits
    parameter NUM_ERRORES = 8;   // 8 posiciones posibles para inyectar error (0-7)
    
    // Señales para el encoder
    reg [3:0] data_in;
    wire [6:0] msj_puro;
    
    // Señales para el inyector de error
    reg [2:0] sw_error;
    wire [6:0] msj_con_error;
    
    // Variables para el test
    integer i, j;
    reg [6:0] msj_esperado;
    reg [6:0] msj_con_error_esperado;
    reg error_detectado;
    
    // Instanciar el encoder
    hamm_encoder uut_encoder (
        .data_in(data_in),
        .data_out(msj_puro)
    );
    
    // Instanciar el inyector de error
    inyector_error uut_inyector (
        .msj_puro(msj_puro),
        .sw_error(sw_error),
        .msj_con_error(msj_con_error)
    );
    
    // Monitoreo de señales
    initial begin
        $display("==========================================================");
        $display("INICIANDO TEST BENCH DEL INYECTOR DE ERROR HAMMING (7,4)");
        $display("==========================================================");
        $display(" ");
        
        // Archivo de resultados
        $dumpfile("top_trans_tb.vcd");
        $dumpvars(0, tb_inyector_error);
        
        // Prueba para cada posible mensaje de entrada (4 bits = 16 combinaciones)
        for (i = 0; i < NUM_PRUEBAS; i = i + 1) begin
            data_in = i;
            #10;  // Esperar a que se estabilice el encoder
            
            $display("==========================================================");
            $display("DATOS DE ENTRADA: data_in = %b (%0d)", data_in, data_in);
            $display("CÓDIGO HAMMING ORIGINAL: msj_puro = %b", msj_puro);
            $display(" ");
            
            // Probar cada posible posición de error (0-7)
            for (j = 0; j < NUM_ERRORES; j = j + 1) begin
                sw_error = j;
                #10;  // Esperar a que se aplique el error
                
                // Calcular mensaje esperado con error
                if (j == 0) begin
                    // Sin error (y0 no está implementado)
                    msj_con_error_esperado = msj_puro;
                    $display("  Caso %0d: SIN ERROR (sw_error=%b)", j, sw_error);
                end else begin
                    msj_con_error_esperado = msj_puro;
                    // Invertir el bit correspondiente según el switch
                    case (j)
                        1: msj_con_error_esperado[0] = ~msj_puro[0];  // y1
                        2: msj_con_error_esperado[1] = ~msj_puro[1];  // y2
                        3: msj_con_error_esperado[2] = ~msj_puro[2];  // y3
                        4: msj_con_error_esperado[3] = ~msj_puro[3];  // y4
                        5: msj_con_error_esperado[4] = ~msj_puro[4];  // y5
                        6: msj_con_error_esperado[5] = ~msj_puro[5];  // y6
                        7: msj_con_error_esperado[6] = ~msj_puro[6];  // y7
                    endcase
                    $display("  Caso %0d: ERROR en posición %0d (sw_error=%b)", j, j-1, sw_error);
                end
                
                // Mostrar resultados
                $display("    msj_con_error = %b", msj_con_error);
                $display("    Esperado      = %b", msj_con_error_esperado);
                
                // Verificar si hay error
                if (msj_con_error !== msj_con_error_esperado) begin
                    $display("    ❌ ERROR: Salida incorrecta!");
                    error_detectado = 1;
                end else begin
                    $display("    ✅ Correcto");
                end
                
                // Mostrar comparación bit a bit
                $display("    Comparación: %b vs %b", msj_con_error, msj_con_error_esperado);
                
                // Mostrar qué bits cambiaron respecto al original
                if (j != 0) begin
                    if (msj_con_error == msj_puro) begin
                        $display("    ⚠️  ADVERTENCIA: No se inyectó error (bit %0d no cambió)", j-1);
                    end else if (msj_con_error == msj_con_error_esperado) begin
                        $display("    ✓ Error inyectado correctamente en bit %0d", j-1);
                    end
                end else begin
                    if (msj_con_error == msj_puro) begin
                        $display("    ✓ Mensaje sin alteraciones");
                    end else begin
                        $display("    ❌ ERROR: Mensaje alterado cuando no debía");
                    end
                end
                $display(" ");
            end
            
            $display(" ");
        end
        
        // Pruebas adicionales: verificar independencia de bits
        $display("==========================================================");
        $display("PRUEBAS ADICIONALES - VERIFICACIÓN DE INDEPENDENCIA");
        $display("==========================================================");
        
        // Probar con un mensaje específico
        data_in = 4'b1010;
        #10;
        $display("Mensaje original: data_in = 1010");
        $display("Código Hamming: msj_puro = %b", msj_puro);
        
        // Probar múltiples errores simultáneos (aunque el diseño no lo soporta oficialmente)
        $display(" ");
        $display("Probando múltiples errores (simultáneos):");
        sw_error = 3'b001;  // Error en bit 0
        #10;
        $display("  Error solo en bit 0: %b", msj_con_error);
        
        sw_error = 3'b010;  // Error en bit 1
        #10;
        $display("  Error solo en bit 1: %b", msj_con_error);
        
        sw_error = 3'b011;  // Error en bits 0 y 1 (y3 activa ambos)
        #10;
        $display("  Error en bits 0 y 1: %b (Nota: y3 activa bit 2, no ambos)", msj_con_error);
        $display("  ⚠️  El decoder 3-to-8 solo activa una salida a la vez");
        
        // Probar todos los switches en secuencia rápida
        $display(" ");
        $display("Prueba de secuencia rápida de errores:");
        for (j = 0; j < 8; j = j + 1) begin
            sw_error = j;
            #5;
            $display("  sw_error=%b -> msj_con_error=%b (original=%b)", 
                     sw_error, msj_con_error, msj_puro);
        end
        
        // Resultado final
        $display(" ");
        $display("==========================================================");
        if (error_detectado) begin
            $display("❌ TEST BENCH COMPLETADO CON ERRORES");
        end else begin
            $display("✅ TEST BENCH COMPLETADO EXITOSAMENTE");
        end
        $display("==========================================================");
        
        #20;
        $finish;
    end
    
    // Monitoreo continuo de cambios importantes
    always @(msj_con_error) begin
        if (sw_error != 0) begin
            $display("[%0t] Bit cambiado en posición %0d: %b -> %b", 
                     $time, sw_error - 1, msj_puro[sw_error-1], msj_con_error[sw_error-1]);
        end
    end
    
endmodule

