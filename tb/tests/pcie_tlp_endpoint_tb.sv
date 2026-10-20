module pcie_tlp_endpoint_tb;
    logic clk = 0;

    always #5ns clk = ~clk;

    logic        rst_n, rx_valid, rx_ready, rx_payload_valid;
    logic        tx_valid, tx_ready, tx_has_payload, error_event;
    logic [95:0] rx_header, tx_header;
    logic [31:0] rx_payload, tx_payload;

    pcie_endpoint_tlp #(
        .COMPLETER_ID(16'h0200)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx_valid(rx_valid),
        .rx_ready(rx_ready),
        .rx_header(rx_header),
        .rx_payload_valid(rx_payload_valid),
        .rx_payload(rx_payload),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .tx_header(tx_header),
        .tx_has_payload(tx_has_payload),
        .tx_payload(tx_payload),
        .error_event(error_event)
    );

    task automatic make_mem_header(
        input bit is_write,
        input logic [7:0] tag,
        input logic [31:0] address,
        input logic [3:0] first_be
    );
        logic [31:0] dw0, dw1, dw2;
        begin
            dw0 = 32'h0;
            dw1 = 32'h0;
            dw2 = 32'h0;
            dw0[31:29] = is_write ? 3'b010 : 3'b000;
            dw0[28:24] = 5'b00000;
            dw0[9:0]   = 10'd1;
            dw1[31:16] = 16'h0100;
            dw1[15:8]  = tag;
            dw1[7:4]   = 4'h0;
            dw1[3:0]   = first_be;
            dw2[31:2]  = address[31:2];
            rx_header  = {dw0, dw1, dw2};
        end
    endtask

    task automatic make_cfg_header(
        input bit is_write,
        input logic [7:0] tag,
        input logic [11:0] offset,
        input logic [3:0] first_be
    );
        logic [31:0] dw0, dw1, dw2;
        begin
            dw0 = 32'h0;
            dw1 = 32'h0;
            dw2 = 32'h0;
            dw0[31:29] = is_write ? 3'b010 : 3'b000;
            dw0[28:24] = is_write ? 5'b00101 : 5'b00100;
            dw0[9:0]   = 10'd1;
            dw1[31:16] = 16'h0100;
            dw1[15:8]  = tag;
            dw1[7:4]   = 4'h0;
            dw1[3:0]   = first_be;
            dw2[31:16] = 16'h0200;
            dw2[11:2]  = offset[11:2];
            rx_header  = {dw0, dw1, dw2};
        end
    endtask

    task automatic send_cfg(
        input bit is_write,
        input logic [7:0] tag,
        input logic [11:0] offset,
        input logic [3:0] be,
        input logic [31:0] payload
    );
        begin
            while (!rx_ready)
                @(negedge clk);
            @(negedge clk);
            make_cfg_header(is_write, tag, offset, be);
            rx_payload       = payload;
            rx_payload_valid = is_write;
            rx_valid         = 1;
            do @(posedge clk); while (!rx_ready);
            @(negedge clk);
            rx_valid         = 0;
            rx_payload_valid = 0;
            rx_header        = '0;
            rx_payload       = '0;
        end
    endtask

    task automatic send_request(
        input bit is_write,
        input logic [7:0] tag,
        input logic [31:0] address,
        input logic [3:0] be,
        input logic [31:0] payload
    );
        begin
            while (!rx_ready)
                @(negedge clk);
            @(negedge clk);
            make_mem_header(is_write, tag, address, be);
            rx_payload       = payload;
            rx_payload_valid = is_write;
            rx_valid         = 1;
            do @(posedge clk); while (!rx_ready);
            @(negedge clk);
            rx_valid         = 0;
            rx_payload_valid = 0;
            rx_header        = '0;
            rx_payload       = '0;
        end
    endtask

    initial begin
        rst_n            = 0;
        rx_valid         = 0;
        rx_header        = '0;
        rx_payload_valid = 0;
        rx_payload       = '0;
        tx_ready         = 0;

        repeat (3) @(negedge clk);
        rst_n = 1;

        // Configuration Type 0 Read of Vendor ID / Device ID.
        send_cfg(0, 8'h20, 12'h000, 4'hF, 32'h0);
        wait (tx_valid);
        #1ns;
        if (!tx_has_payload || tx_payload !== 32'hF001_1D0F || tx_header[15:8] !== 8'h20)
            $fatal(1, "Configuration Read Completion is incorrect");
        @(negedge clk);
        tx_ready = 1;
        @(posedge clk);
        @(negedge clk);
        tx_ready = 0;

        // Configuration Write returns a Completion without data; then read back.
        send_cfg(1, 8'h21, 12'h004, 4'b0011, 32'h0000_0007);
        wait (tx_valid);
        #1ns;
        if (tx_has_payload || tx_header[47:45] !== 3'b000 || tx_header[15:8] !== 8'h21)
            $fatal(1, "Configuration Write Completion is incorrect");
        @(negedge clk);
        tx_ready = 1;
        @(posedge clk);
        @(negedge clk);
        tx_ready = 0;

        send_cfg(0, 8'h26, 12'h004, 4'hF, 32'h0);
        wait (tx_valid);
        #1ns;
        if (!tx_has_payload || tx_payload !== 32'h0010_0007 || tx_header[15:8] !== 8'h26)
            $fatal(1, "Configuration Command/Status readback is incorrect");
        @(negedge clk);
        tx_ready = 1;
        @(posedge clk);
        @(negedge clk);
        tx_ready = 0;

        // Posted Memory Write: must update BAR0 and must not emit a Completion.
        send_request(1, 8'h22, 32'h0000_1000, 4'hF, 32'hA1B2_C3D4);
        repeat (5) @(negedge clk);
        if (tx_valid)
            $fatal(1, "Posted Memory Write incorrectly emitted a Completion");

        // Memory Read: should return a Completion-with-Data with matching Tag and data.
        send_request(0, 8'h23, 32'h0000_1000, 4'hF, 32'h0);
        wait (tx_valid);
        #1ns;
        if (!tx_has_payload)
            $fatal(1, "Successful Memory Read Completion has no payload");
        if (tx_payload !== 32'hA1B2_C3D4)
            $fatal(1, "Read payload mismatch: %08x", tx_payload);
        if (tx_header[95:93] !== 3'b010 || tx_header[92:88] !== 5'b01010)
            $fatal(1, "Incorrect Completion-with-Data Fmt/Type");
        if (tx_header[47:45] !== 3'b000)
            $fatal(1, "Completion status is not Successful Completion");
        if (tx_header[43:32] !== 12'd4)
            $fatal(1, "Incorrect Completion Byte Count");
        if (tx_header[31:16] !== 16'h0100 || tx_header[15:8] !== 8'h23)
            $fatal(1, "Requester ID or Tag was not preserved");
        if (tx_header[6:0] !== 7'h00)
            $fatal(1, "Incorrect Completion Lower Address");
        @(negedge clk);
        tx_ready = 1;
        @(posedge clk);
        @(negedge clk);
        tx_ready = 0;
        repeat (2) @(negedge clk);
        if (tx_valid)
            $fatal(1, "Completion remained valid after handshake");

        // A two-byte read checks Byte Count and the first enabled byte's address.
        send_request(0, 8'h24, 32'h0000_1000, 4'b1100, 32'h0);
        wait (tx_valid);
        #1ns;
        if (!tx_has_payload || tx_header[43:32] !== 12'd2 || tx_header[6:0] !== 7'h02)
            $fatal(1, "Partial-byte Completion metadata is incorrect");
        @(negedge clk);
        tx_ready = 1;
        @(posedge clk);
        @(negedge clk);
        tx_ready = 0;

        // Unsupported non-posted request must return an Unsupported Request status.
        send_request(0, 8'h25, 32'h0000_2000, 4'hF, 32'h0);
        wait (tx_valid);
        #1ns;
        if (tx_header[47:45] !== 3'b001 || tx_has_payload || tx_header[15:8] !== 8'h25)
            $fatal(1, "Unsupported Request Completion is incorrect");
        @(negedge clk);
        tx_ready = 1;
        @(posedge clk);
        @(negedge clk);
        tx_ready = 0;
        repeat (2) @(negedge clk);
        if (tx_valid)
            $fatal(1, "Completion remained valid after handshake");
        if (error_event)
            $fatal(1, "Unexpected posted-write error event");

        $display("TLP_ENDPOINT_PASS: config, posted write, read, byte-count, and UR checks passed");
        $finish;
    end

endmodule
