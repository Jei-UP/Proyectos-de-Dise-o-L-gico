// TOP TESTBENCH: Complete Hamming System Test
// Encoder -> Error Injector -> Corrector

`timescale 1ns/1ps

module top_tb();

    // Test signals
    reg [3:0] original_data;      // Original 4-bit data
    reg [2:0] error_switch;       // Error position switch (3 bits)
    wire [6:0] encoded_code;      // Output from encoder
    wire [6:0] corrupted_code;    // Output from error injector
    wire [3:0] corrected_data;    // Output from corrector
    
    // Internal signals for syndrome (if needed by your corrector)
    wire [2:0] syndrome;          // Calculated from corrupted code
    
    // Test tracking
    integer test_number;
    integer pass_count;
    integer fail_count;
    integer total_tests;
    
    // Instantiate Encoder
    hamm_encoder encoder (
        .data_in(original_data),
        .data_out(encoded_code)
    );
    
    // Instantiate Error Injector
    inyector_error injector (
        .msj_puro(encoded_code),
        .sw_error(error_switch),
        .msj_con_error(corrupted_code)
    );
    
    // Syndrome Calculator (needed for the corrector)
    // This calculates syndrome from the received code
    syndrome_calculator syndrome_calc (
        .recibido(corrupted_code),
        .sindrome(syndrome)
    );
    
    // Instantiate Error Corrector
    corrector_error corrector (
        .recibido(corrupted_code),
        .sindrome(syndrome),
        .dato_corregido(corrected_data)
    );
    
    // Syndrome Calculator Module
    module syndrome_calculator (
        input wire [6:0] recibido,
        output wire [2:0] sindrome
    );
        // Hamming(7,4) syndrome calculation
        assign sindrome[0] = recibido[0] ^ recibido[2] ^ recibido[4] ^ recibido[6];
        assign sindrome[1] = recibido[1] ^ recibido[2] ^ recibido[5] ^ recibido[6];
        assign sindrome[2] = recibido[3] ^ recibido[4] ^ recibido[5] ^ recibido[6];
    endmodule
    
    // Main test procedure
    initial begin
        // Initialize
        $display("============================================================");
        $display("COMPLETE HAMMING CODE SYSTEM VERIFICATION");
        $display("Encoder -> Error Injector -> Corrector");
        $display("============================================================");
        $display("");
        
        pass_count = 0;
        fail_count = 0;
        test_number = 0;
        
        // Test all 16 possible data combinations
        for (int data = 0; data < 16; data++) begin
            original_data = data;
            
            // Test with NO error (switch position 0)
            test_number = test_number + 1;
            error_switch = 3'b000;
            #10;
            verify_test(test_number, original_data, error_switch, corrected_data, original_data);
            
            // Test with error in each of the 7 bit positions (1 to 7)
            for (int error_pos = 1; error_pos <= 7; error_pos++) begin
                test_number = test_number + 1;
                error_switch = error_pos;
                #10;
                verify_test(test_number, original_data, error_switch, corrected_data, original_data);
            end
        end
        
        // Additional specific test cases
        test_number = test_number + 1;
        original_data = 4'b1010;
        error_switch = 3'b000;
        #10;
        verify_test(test_number, original_data, error_switch, corrected_data, original_data);
        
        test_number = test_number + 1;
        original_data = 4'b0101;
        error_switch = 3'b101;
        #10;
        verify_test(test_number, original_data, error_switch, corrected_data, original_data);
        
        test_number = test_number + 1;
        original_data = 4'b1111;
        error_switch = 3'b111;
        #10;
        verify_test(test_number, original_data, error_switch, corrected_data, original_data);
        
        test_number = test_number + 1;
        original_data = 4'b0000;
        error_switch = 3'b011;
        #10;
        verify_test(test_number, original_data, error_switch, corrected_data, original_data);
        
        // Final summary
        total_tests = pass_count + fail_count;
        $display("");
        $display("============================================================");
        $display("FINAL TEST SUMMARY");
        $display("============================================================");
        $display("Total tests run: %0d", total_tests);
        $display("Tests PASSED: %0d", pass_count);
        $display("Tests FAILED: %0d", fail_count);
        $display("");
        
        if (fail_count == 0) begin
            $display("✓✓✓ EXCELLENT! ALL %0d TESTS PASSED! ✓✓✓", total_tests);
            $display("Your Hamming code system works perfectly!");
        end else begin
            $display("✗✗✗ WARNING! %0d TESTS FAILED! ✗✗✗", fail_count);
            $display("Please check your encoder, injector, or corrector modules.");
        end
        
        $display("============================================================");
        $finish;
    end
    
    // Task to verify each test
    task verify_test;
        input integer test_num;
        input [3:0] original;
        input [2:0] error_sw;
        input [3:0] actual;
        input [3:0] expected;
        
        reg [6:0] encoded;
        reg [6:0] corrupted;
        
        begin
            encoded = encoder.data_out;
            corrupted = injector.msj_con_error;
            
            $display("Test %0d:", test_num);
            $display("  Original data: %b (0x%0h)", original, original);
            $display("  Error switch: 3'b%03b (%0d)", error_sw, error_sw);
            
            if (error_sw == 3'b000) 
                $display("  Error injected: NO ERROR");
            else
                $display("  Error injected: BIT %0d", error_sw - 1);
            
            $display("  Encoded code: %b", encoded);
            $display("  Corrupted code: %b", corrupted);
            $display("  Syndrome: %b", syndrome_calc.sindrome);
            $display("  Corrected data: %b", actual);
            $display("  Expected data: %b", expected);
            
            if (actual === expected) begin
                $display("  Result: ✓ PASSED");
                pass_count = pass_count + 1;
            end else begin
                $display("  Result: ✗ FAILED");
                fail_count = fail_count + 1;
            end
            $display("");
        end
    endtask
    
    // Optional: Waveform dumping for visualization
    initial begin
        $dumpfile("hamming_system.vcd");
        $dumpvars(0, top_testbench_hamming);
    end
    
    // Monitor changes in real-time
    initial begin
        $monitor("Time=%0t | Data=%b | Error=%b | Encoded=%b | Corrupted=%b | Corrected=%b", 
                 $time, original_data, error_switch, encoded_code, corrupted_code, corrected_data);
    end
    
endmodule
