module pcie_layer_blocks_tb;
    bit clk = 0;

    always #5ns clk = ~clk;

    logic [95:0] header;
    logic        tlp_supported, tlp_write;
    logic [3:0]  tlp_error;
    logic        enc_valid, enc_nak, enc_supported;
    logic [11:0] enc_seq;
    logic [47:0] encoded;
    logic        dec_valid, dec_nak, integrity_ok;
    logic [11:0] dec_seq;
    logic        rst_n, rx_valid, rx_integrity_ok, rx_accept, rx_duplicate, rx_nak;
    logic [11:0] rx_sequence, expected_sequence;

    pcie_tlp_header_check hc (
        .header(header),
        .supported(tlp_supported),
        .is_write(tlp_write),
        .error_code(tlp_error)
    );

    pcie_dllp_codec dc (
        .encode_valid(enc_valid),
        .encode_nak(enc_nak),
        .encode_sequence(enc_seq),
        .encode_supported(enc_supported),
        .encoded_dllp(encoded),
        .decode_dllp(encoded),
        .decode_valid(dec_valid),
        .decode_nak(dec_nak),
        .decode_sequence(dec_seq),
        .decode_integrity_ok(integrity_ok)
    );

    pcie_dll_rx_seq rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx_valid(rx_valid),
        .rx_sequence(rx_sequence),
        .rx_integrity_ok(rx_integrity_ok),
        .rx_accept(rx_accept),
        .rx_duplicate(rx_duplicate),
        .rx_nak(rx_nak),
        .expected_sequence(expected_sequence)
    );

    initial begin
        header = {32'h00000001, 32'h1234000F, 32'h00001000};
        #1;
        if (!tlp_supported || tlp_write)
            $fatal(1, "Valid one-DW Memory Read rejected");

        header[95:64] = 32'h20000001;
        #1;
        if (tlp_supported || tlp_error != 1)
            $fatal(1, "Unsupported TLP format not rejected");

        enc_valid = 1;
        enc_nak   = 0;
        enc_seq   = 12'h123;
        #1;
        if (!enc_supported || !dec_valid || dec_nak ||
            dec_seq != 12'h123 || !integrity_ok)
            $fatal(1, "ACK DLLP round trip failed");

        enc_nak = 1;
        #1;
        if (!dec_valid || !dec_nak || dec_seq != 12'h123)
            $fatal(1, "NAK DLLP round trip failed");

        rst_n            = 0;
        rx_valid         = 0;
        rx_sequence      = 0;
        rx_integrity_ok  = 1;
        repeat (2) @(negedge clk);
        rst_n = 1;

        @(negedge clk);
        rx_valid    = 1;
        rx_sequence = 0;
        #1;
        if (!rx_accept || rx_nak)
            $fatal(1, "Expected sequence not accepted");

        @(posedge clk);
        @(negedge clk);
        rx_sequence = 0;
        #1;
        if (!rx_duplicate || rx_accept || rx_nak)
            $fatal(1, "Duplicate packet not suppressed");

        rx_sequence = 2;
        #1;
        if (!rx_nak)
            $fatal(1, "Out-of-order packet not NAKed");

        rx_sequence     = 1;
        rx_integrity_ok = 0;
        #1;
        if (!rx_nak)
            $fatal(1, "Bad-integrity packet not NAKed");

        $display("PCIE_LAYER_BLOCKS_PASS");
        $finish;
    end

endmodule
