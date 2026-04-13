`timescale 1ns / 1ps

module hamm_encoder_tb();

    // Señales del test bench
    reg [3:0] data_in;
    wire [6:0] data_out;
    
    // Instancia del módulo a probar
    hamm_encoder uut (
        .data_in(data_in),
        .data_out(data_out)
    );
    
    // Procedimiento de prueba
    initial begin
        $display("==================================================");
        $display("        TEST BENCH - HAMMING (7,4) ENCODER");
        $display("==================================================");
        $display("Data_in (D3 D2 D1 D0) | Data_out (D3 D2 D1 P3 D0 P2 P1)");
        $display("--------------------------------------------------");
        
        // Caso de prueba 1: data_in = 0000
        data_in = 4'b0000;
        #10;
        $display("    %b              |    %b", data_in, data_out);
        
        // Caso de prueba 2: data_in = 0001
        data_in = 4'b0001;
        #10;
        $display("    %b              |    %b", data_in, data_out);
        
        // Caso de prueba 3: data_in = 0010
        data_in = 4'b0010;
        #10;
        $display("    %b              |    %b", data_in, data_out);
        
        // Caso de prueba 4: data_in = 0011
        data_in = 4'b0011;
        #10;
        $display("    %b              |    %b", data_in, data_out);
        
        // Caso de prueba 5: data_in = 0100
        data_in = 4'b0100;
        #10;
        $display("    %b              |    %b", data_in, data_out);
        
        // Caso de prueba 6: data_in = 0101
        data_in = 4'b0101;
        #10;
        $display("    %b              |    %b", data_in, data_out);
        
        // Caso de prueba 7: data_in = 0110
        data_in = 4'b0110;
        #10;
        $display("    %b              |    %b", data_in, data_out);
        
        // Caso de prueba 8: data_in = 0111
        data_in = 4'b0111;
        #10;
        $display("    %b              |    %b", data_in, data_out);
        
        // Caso de prueba 9: data_in = 1000
        data_in = 4'b1000;
        #10;
        $display("    %b              |    %b", data_in, data_out);
        
        // Caso de prueba 10: data_in = 1001
        data_in = 4'b1001;
        #10;
        $display("    %b              |    %b", data_in, data_out);
        
        // Caso de prueba 11: data_in = 1010
        data_in = 4'b1010;
        #10;
        $display("    %b              |    %b", data_in, data_out);
        
        // Caso de prueba 12: data_in = 1011
        data_in = 4'b1011;
        #10;
        $display("    %b              |    %b", data_in, data_out);
        
        // Caso de prueba 13: data_in = 1100
        data_in = 4'b1100;
        #10;
        $display("    %b              |    %b", data_in, data_out);
        
        // Caso de prueba 14: data_in = 1101
        data_in = 4'b1101;
        #10;
        $display("    %b              |    %b", data_in, data_out);
        
        // Caso de prueba 15: data_in = 1110
        data_in = 4'b1110;
        #10;
        $display("    %b              |    %b", data_in, data_out);
        
        // Caso de prueba 16: data_in = 1111
        data_in = 4'b1111;
        #10;
        $display("    %b              |    %b", data_in, data_out);
        
        $display("--------------------------------------------------");
        $display("              SIMULACION COMPLETADA");
        $display("==================================================");
        
        #10;
        $finish;
    end
    
    // Monitor automático para verificar resultados (opcional)
    initial begin
        $monitor("Time = %0t ns: data_in = %b, data_out = %b", $time, data_in, data_out);
    end
    
    // Generación de forma de onda (para quienes usen GTKWave o similar)
    initial begin
        $dumpfile("hamm_encoder_tb.vcd");
        $dumpvars(0, hamm_encoder_tb);
    end

endmodule