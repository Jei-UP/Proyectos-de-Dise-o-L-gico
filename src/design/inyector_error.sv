// Se le "inyecta" un error al código de Hamming para probar la detección de errores del receptor de otro grupo

module inyector_error (
    input wire [6:0] msj_puro, //Código generado en hamm_encoder
    input wire [2:0] sw_error, //switches de posición (S2, S1 o S0)
    output wire [6:0] msj_con_error);


    //Definimos s2, s1 y s0 desde switches
    wire s2 = sw_error[2];
    wire s1 = sw_error[1];
    wire s0 = sw_error[0];


    //Decoder 3 a 8 que activa 1 de las 8 salidas
   // wire y0 = !s2 & !s1 & !s0 no se añade porque no inyecta ningún error
    wire y1 = !s2 & !s1 & s0; 
    wire y2 = !s2 & s1 & !s0;
    wire y3 = !s2 & s1 & s0;
    wire y4 = s2 & !s1 & !s0;
    wire y5 = s2 & !s1 & s0;
    wire y6 = s2 & s1 & !s0;
    wire y7 = s2 & s1 & s0;

    //Ahora, se inyecta el error con un los XOR en la posición respectiva del mensaje recibido
    assign msj_con_error[0] = msj_puro[0] ^ y1;
    assign msj_con_error[1] = msj_puro[1] ^ y2;
    assign msj_con_error[2] = msj_puro[2] ^ y3;
    assign msj_con_error[3] = msj_puro[3] ^ y4;
    assign msj_con_error[4] = msj_puro[4] ^ y5;
    assign msj_con_error[5] = msj_puro[5] ^ y6;
    assign msj_con_error[6] = msj_puro[6] ^ y7;

endmodule

    
/*module top_trans_tb();

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
        $dumpfile("top_trans_tb.vcd");
        $dumpvars(0, top_trans_tb);
    end

endmodule /*