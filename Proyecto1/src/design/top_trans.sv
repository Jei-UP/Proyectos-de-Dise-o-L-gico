module top_trans (
    input wire [2:0] sw_error,
    input wire [3:0] data_in,
    output wire [6:0] seg_7
);

    wire [6:0] ham_msg;
    wire [6:0] ham_msg_error;

    hamm_encoder encoder (
        .data_in(data_in),
        .data_out(ham_msg)
    );

    inyector_error inyector (
        .msj_puro(ham_msg),
        .sw_error(sw_error),
        .msj_con_error(ham_msg_error)
    );

    trans_7_seg decodificador (
        .datos(data_in[3:0]),
        .seg_7(seg_7)
    );

// assign seg_7 = 7'b111111;

endmodule