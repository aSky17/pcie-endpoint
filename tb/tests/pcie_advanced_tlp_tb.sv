`timescale 1ns/1ps

module pcie_advanced_tlp_tb;
    localparam int TAG_COUNT = 8, TAG_WIDTH = 3, MAX_DWORDS = 8, CW = $clog2(MAX_DWORDS+1);

    logic clk = 0, rst_n = 0;

    always #5 clk = ~clk;

    logic        req_valid, req_ready;
    logic [TAG_WIDTH-1:0] req_tag;
    logic [15:0] req_requester_id;
    logic [11:0] req_total_bytes;
    logic [6:0]  req_lower_address;
    logic        cpl_valid;
    logic [TAG_WIDTH-1:0] cpl_tag;
    logic [15:0] cpl_requester_id;
    logic [2:0]  cpl_status;
    logic [11:0] cpl_byte_count;
    logic [6:0]  cpl_lower_address;
    logic [12:0] cpl_payload_bytes;
    logic        cpl_accept, cpl_error, request_done;
    logic [3:0]  cpl_error_code;
    logic [11:0] bytes_remaining;
    logic [TAG_COUNT-1:0] outstanding_bitmap;

    pcie_completion_assembler #(
        .TAG_COUNT(TAG_COUNT)
    ) cpl_dut (
        .*
    );

    logic        in_valid, in_ready, in_sop, in_eop;
    logic [31:0] in_data;
    logic        packet_valid, packet_ready, packet_overflow, framing_error;
    logic [MAX_DWORDS*32-1:0] packet_data;
    logic [CW-1:0] packet_dwords;

    pcie_tlp_packet_buffer #(
        .MAX_DWORDS(MAX_DWORDS)
    ) buf_dut (
        .*
    );

    task automatic tick;
        @(posedge clk);
        #1;
    endtask

    initial begin
        req_valid          = 0;
        req_tag            = 0;
        req_requester_id   = 0;
        req_total_bytes    = 0;
        req_lower_address  = 0;
        cpl_valid          = 0;
        cpl_tag            = 0;
        cpl_requester_id   = 0;
        cpl_status         = 0;
        cpl_byte_count     = 0;
        cpl_lower_address  = 0;
        cpl_payload_bytes  = 0;
        in_valid           = 0;
        in_sop             = 0;
        in_eop             = 0;
        in_data            = 0;
        packet_ready       = 0;

        repeat (2) tick();
        rst_n = 1;
        tick();

        // Two split Completions: byte count describes remaining bytes before each fragment.
        @(negedge clk);
        req_valid         = 1;
        req_tag           = 3;
        req_requester_id  = 16'h1234;
        req_total_bytes   = 12;
        req_lower_address = 7'h20;
        #1;
        if (!req_ready)
            $fatal(1, "request allocation not ready");
        tick();

        @(negedge clk);
        req_valid         = 0;
        cpl_valid         = 1;
        cpl_tag           = 3;
        cpl_requester_id  = 16'h1234;
        cpl_status        = 0;
        cpl_byte_count    = 12;
        cpl_lower_address = 7'h20;
        cpl_payload_bytes = 5;
        #1;
        if (!cpl_accept || request_done || bytes_remaining != 7)
            $fatal(1, "first split Completion rejected");
        tick();

        @(negedge clk);
        cpl_byte_count    = 7;
        cpl_lower_address = 7'h25;
        cpl_payload_bytes = 7;
        #1;
        if (!cpl_accept || !request_done)
            $fatal(1, "final split Completion rejected");
        tick();

        @(negedge clk);
        cpl_valid = 0;
        if (outstanding_bitmap[3])
            $fatal(1, "Tag not released after final fragment");

        // Assemble a 3-DWORD packet and check exact DWORD ordering.
        in_valid = 1;
        in_sop   = 1;
        in_eop   = 0;
        in_data  = 32'h01020304;
        tick();

        @(negedge clk);
        in_sop = 0;
        in_data = 32'h11121314;
        in_eop  = 0;
        tick();

        @(negedge clk);
        in_data = 32'hA1A2A3A4;
        in_eop  = 1;
        tick();

        @(negedge clk);
        in_valid = 0;
        in_eop   = 0;

        if (!packet_valid || packet_dwords != 3 ||
            packet_data[31:0] != 32'h01020304 ||
            packet_data[63:32] != 32'h11121314 ||
            packet_data[95:64] != 32'hA1A2A3A4)
            $fatal(1, "packet assembly/order mismatch");

        packet_ready = 1;
        tick();
        @(negedge clk);
        packet_ready = 0;

        if (packet_valid)
            $fatal(1, "packet valid did not clear on handshake");

        $display("PCIE_ADVANCED_TLP_PASS");
        $finish;
    end

endmodule
