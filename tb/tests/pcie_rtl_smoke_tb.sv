module pcie_rtl_smoke_tb;
    import pcie_pkg::*;

    bit clk = 0;

    always #5ns clk = ~clk;

    pcie_packet_if pif(clk);
    pcie_endpoint dut(pif);

    logic        enc_valid, enc_write, enc_supported;
    logic [9:0]  enc_len, dec_len;
    logic [15:0] enc_rid, dec_rid;
    logic [7:0]  enc_tag, dec_tag;
    logic [3:0]  enc_fbe, enc_lbe, dec_fbe, dec_lbe;
    logic [31:0] enc_addr, dec_addr;
    logic [95:0] enc_header;
    logic        dec_supported, dec_write;
    logic [127:0] crc_data;
    logic [4:0]  crc_bytes;
    logic [31:0] crc_value;

    pcie_tlp_codec codec (
        .encode_valid(enc_valid),
        .encode_write(enc_write),
        .encode_length_dw(enc_len),
        .encode_requester_id(enc_rid),
        .encode_tag(enc_tag),
        .encode_first_be(enc_fbe),
        .encode_last_be(enc_lbe),
        .encode_address(enc_addr),
        .encode_supported(enc_supported),
        .encoded_header(enc_header),
        .decode_header(enc_header),
        .decode_supported(dec_supported),
        .decode_write(dec_write),
        .decode_length_dw(dec_len),
        .decode_requester_id(dec_rid),
        .decode_tag(dec_tag),
        .decode_first_be(dec_fbe),
        .decode_last_be(dec_lbe),
        .decode_address(dec_addr)
    );

    pcie_lcrc32 crc (
        .packet_data(crc_data),
        .packet_bytes(crc_bytes),
        .lcrc(crc_value)
    );

    logic        cpl_enc_valid, cpl_enc_data, cpl_enc_supported;
    logic        cpl_dec_supported, cpl_dec_data;
    logic [9:0]  cpl_enc_len, cpl_dec_len;
    logic [15:0] cpl_enc_cid, cpl_dec_cid, cpl_enc_rid, cpl_dec_rid;
    logic [2:0]  cpl_enc_status, cpl_dec_status;
    logic [11:0] cpl_enc_bc, cpl_dec_bc;
    logic [7:0]  cpl_enc_tag, cpl_dec_tag;
    logic [6:0]  cpl_enc_la, cpl_dec_la;
    logic [95:0] cpl_header;

    pcie_completion_codec cpl_codec (
        .encode_valid(cpl_enc_valid),
        .encode_has_data(cpl_enc_data),
        .encode_length_dw(cpl_enc_len),
        .encode_completer_id(cpl_enc_cid),
        .encode_status(cpl_enc_status),
        .encode_byte_count(cpl_enc_bc),
        .encode_requester_id(cpl_enc_rid),
        .encode_tag(cpl_enc_tag),
        .encode_lower_address(cpl_enc_la),
        .encode_supported(cpl_enc_supported),
        .encoded_header(cpl_header),
        .decode_header(cpl_header),
        .decode_supported(cpl_dec_supported),
        .decode_has_data(cpl_dec_data),
        .decode_length_dw(cpl_dec_len),
        .decode_completer_id(cpl_dec_cid),
        .decode_status(cpl_dec_status),
        .decode_byte_count(cpl_dec_bc),
        .decode_requester_id(cpl_dec_rid),
        .decode_tag(cpl_dec_tag),
        .decode_lower_address(cpl_dec_la)
    );

    task automatic transact(
        input pcie_op_e op,
        input logic [31:0] addr,
        input logic [31:0] data,
        input logic [3:0] be,
        input logic [7:0] tag,
        input logic [31:0] expected,
        input pcie_cpl_status_e status_expected
    );
        @(negedge clk);
        pif.req_op           = op;
        pif.req_addr         = addr;
        pif.req_wdata        = data;
        pif.req_be           = be;
        pif.req_tag          = tag;
        pif.req_requester_id = 16'h0100;
        pif.req_valid        = 1;
        do @(posedge clk); while (!pif.req_ready);
        @(negedge clk);
        pif.req_valid = 0;
        pif.rsp_ready = 1;
        do @(posedge clk); while (!pif.rsp_valid);

        if (pif.rsp_status !== status_expected)
            $fatal(1, "status mismatch op=%0d addr=%08x expected=%0d got=%0d",
                   op, addr, status_expected, pif.rsp_status);
        if (pif.rsp_rdata !== expected)
            $fatal(1, "data mismatch op=%0d addr=%08x expected=%08x got=%08x",
                   op, addr, expected, pif.rsp_rdata);
        if (pif.rsp_tag !== tag)
            $fatal(1, "tag mismatch");

        @(negedge clk);
        pif.rsp_ready = 0;
    endtask

    initial begin
        enc_valid = 1;
        enc_write = 1;
        enc_len   = 10'd1;
        enc_rid   = 16'h0100;
        enc_tag   = 8'hA5;
        enc_fbe   = 4'hF;
        enc_lbe   = 4'h0;
        enc_addr  = 32'h1234_5678;
        crc_data  = 128'h0000000000000000000000393837363534333231;
        crc_bytes = 5'd9;
        cpl_enc_valid  = 1;
        cpl_enc_data   = 1;
        cpl_enc_len    = 1;
        cpl_enc_cid    = 16'h0200;
        cpl_enc_status = 3'b000;
        cpl_enc_bc     = 12'd4;
        cpl_enc_rid    = 16'h0100;
        cpl_enc_tag    = 8'hA5;
        cpl_enc_la     = 7'h24;
        #1ns;

        if (!enc_supported || !dec_supported || !dec_write || dec_len != 1 ||
            dec_rid != 16'h0100 || dec_tag != 8'hA5 || dec_fbe != 4'hF ||
            dec_lbe != 4'h0 || dec_addr != 32'h1234_5678)
            $fatal(1, "TLP codec encode/decode check failed");

        if (crc_value != 32'hCBF4_3926)
            $fatal(1, "CRC32 known-vector mismatch got=%08x", crc_value);

        if (!cpl_enc_supported || !cpl_dec_supported || !cpl_dec_data ||
            cpl_dec_len != 1 || cpl_dec_cid != 16'h0200 || cpl_dec_status != 0 ||
            cpl_dec_bc != 4 || cpl_dec_rid != 16'h0100 || cpl_dec_tag != 8'hA5 ||
            cpl_dec_la != 7'h24)
            $fatal(1, "Completion header codec check failed");

        enc_write = 0;
        #1ns;
        if (enc_header[95:93] != 3'b000 || !dec_supported || dec_write)
            $fatal(1, "Memory Read header encoding failed");

        pif.rst_n            = 0;
        pif.req_valid        = 0;
        pif.req_op           = PCIE_OP_CFG_READ;
        pif.req_addr         = 0;
        pif.req_wdata        = 0;
        pif.req_be           = 4'hF;
        pif.req_tag          = 0;
        pif.req_requester_id = 0;
        pif.rsp_ready        = 0;

        repeat (3) @(negedge clk);
        pif.rst_n = 1;

        transact(PCIE_OP_CFG_READ,  32'h0,    0,               4'hF,    8'h01, 32'hF001_1D0F, PCIE_CPL_SUCCESS);
        transact(PCIE_OP_MEM_WRITE, 32'h1000, 32'hA5C3_7E19,   4'hF,    8'h02, 0,             PCIE_CPL_SUCCESS);
        transact(PCIE_OP_MEM_READ,  32'h1000, 0,               4'hF,    8'h03, 32'hA5C3_7E19, PCIE_CPL_SUCCESS);
        transact(PCIE_OP_MEM_WRITE, 32'h1000, 32'h0000_BB00,   4'b0010, 8'h04, 0,             PCIE_CPL_SUCCESS);
        transact(PCIE_OP_MEM_READ,  32'h1000, 0,               4'hF,    8'h05, 32'hA5C3_BB19, PCIE_CPL_SUCCESS);
        transact(PCIE_OP_MEM_READ,  32'h2000, 0,               4'hF,    8'h06, 0,             PCIE_CPL_UR);
        transact(PCIE_OP_CFG_WRITE, 32'h0,    0,               4'hF,    8'h07, 0,             PCIE_CPL_CA);
        transact(PCIE_OP_CFG_WRITE, 32'h10,   32'hFFFF_FFFF,   4'hF,    8'h09, 0,             PCIE_CPL_SUCCESS);
        transact(PCIE_OP_CFG_READ,  32'h10,   0,               4'hF,    8'h0A, 32'hFFFF_FF00, PCIE_CPL_SUCCESS);

        $display("RTL_SMOKE_PASS: all packet-level directed checks passed");
        $finish;
    end

endmodule
