`timescale 1ns / 1ps

module top_recep_tb();

    // Señales del test bench
    reg [6:0] recibido;
    wire [2:0] pos_error;
    
    // Instancia del módulo a probar
    decoder_paridad uut (
        .recibido(recibido),
        .pos_error(pos_error)
    );
    
    // Procedimiento de prueba
    initial begin
        // Mostrar resultados en formato legible
        $display("=== INICIANDO TEST BENCH ===");
        $display("R7 R6 R5 R4 R3 R2 R1 | S2 S1 S0 | Pos_error");
        $display("----------------------------------------");
        
        // Caso 1: Sin error (paridad correcta)
        // Para un código Hamming(7,4), si no hay error, todos los síndromes deben ser 0
        recibido = 7'b0000000; // Todos ceros
        #10;
        $display("%b | %b | %d", recibido, pos_error, pos_error);
        
        // Caso 2: Sin error - otro ejemplo con datos válidos
        // Suponiendo bits de datos válidos (por ejemplo, palabra código correcta)
        recibido = 7'b1101001; // Ejemplo de palabra código válida
        #10;
        $display("%b | %b | %d", recibido, pos_error, pos_error);
        
        // Caso 3: Error en bit r1 (posición 0)
        recibido = 7'b0000001; // Solo r1=1
        #10;
        $display("%b | %b | %d (Error en bit 0 - r1)", recibido, pos_error, pos_error);
        
        // Caso 4: Error en bit r2 (posición 1)
        recibido = 7'b0000010; // Solo r2=1
        #10;
        $display("%b | %b | %d (Error en bit 1 - r2)", recibido, pos_error, pos_error);
        
        // Caso 5: Error en bit r3 (posición 2)
        recibido = 7'b0000100; // Solo r3=1
        #10;
        $display("%b | %b | %d (Error en bit 2 - r3)", recibido, pos_error, pos_error);
        
        // Caso 6: Error en bit r4 (posición 3)
        recibido = 7'b0001000; // Solo r4=1
        #10;
        $display("%b | %b | %d (Error en bit 3 - r4)", recibido, pos_error, pos_error);
        
        // Caso 7: Error en bit r5 (posición 4)
        recibido = 7'b0010000; // Solo r5=1
        #10;
        $display("%b | %b | %d (Error en bit 4 - r5)", recibido, pos_error, pos_error);
        
        // Caso 8: Error en bit r6 (posición 5)
        recibido = 7'b0100000; // Solo r6=1
        #10;
        $display("%b | %b | %d (Error en bit 5 - r6)", recibido, pos_error, pos_error);
        
        // Caso 9: Error en bit r7 (posición 6)
        recibido = 7'b1000000; // Solo r7=1
        #10;
        $display("%b | %b | %d (Error en bit 6 - r7)", recibido, pos_error, pos_error);
        
        // Caso 10: Múltiples errores (detección pero no corrección)
        recibido = 7'b1010101; // Múltiples bits en 1
        #10;
        $display("%b | %b | %d (Múltiples errores)", recibido, pos_error, pos_error);
        
        // Caso 11: Error en r1 y r3
        recibido = 7'b0000101; // r1=1, r3=1
        #10;
        $display("%b | %b | %d (Doble error)", recibido, pos_error, pos_error);
        
        // Finalizar simulación
        #20;
        $display("=== FIN DEL TEST BENCH ===");
        $finish;
    end
    
    // Monitor automático (opcional, muestra cambios en tiempo real)
    initial begin
        $monitor("Time=%0t | Recibido=%b | Pos_error=%b (%0d)", 
                  $time, recibido, pos_error, pos_error);
    end
    
    // Generar archivo VCD para波形 (opcional)
    initial begin
        $dumpfile("top_recep_tb.vcd");
        $dumpvars(0, top_recep_tb);
    end

endmodule