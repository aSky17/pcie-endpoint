module pcie_dll_replay_tb;
    bit clk = 0;

    always #5ns clk = ~clk;

    logic        rst_n, tlp_valid, tlp_ready, link_valid, link_ready;
    logic [127:0] tlp_data, link_data;
    logic [4:0]  tlp_bytes, link_bytes;
    logic [11:0] link_seq, ack_seq, nak_seq;
    logic [31:0] link_lcrc;
    logic        ack_valid, nak_valid, replay_timeout, outstanding;

    pcie_dll_replay dut (
        .*
    );

    initial begin
        rst_n          = 0;
        tlp_valid      = 0;
        tlp_data       = '0;
        tlp_bytes      = 0;
        link_ready     = 0;
        ack_valid      = 0;
        ack_seq        = 0;
        nak_valid      = 0;
        nak_seq        = 0;
        replay_timeout = 0;

        repeat (3) @(negedge clk);
        rst_n = 1;

        @(negedge clk);
        tlp_valid = 1;
        tlp_data  = 128'h0000000000000000000000393837363534333231;
        tlp_bytes = 9;
        do @(posedge clk); while (!tlp_ready);
        @(negedge clk);
        tlp_valid = 0;

        wait (link_valid);
        if (link_seq != 0 || link_bytes != 9 || link_lcrc != 32'hCBF4_3926)
            $fatal(1, "Initial DLL transmit fields incorrect");
        if (link_data !== 128'h0000000000000000000000393837363534333231)
            $fatal(1, "Initial DLL packet data incorrect");

        @(negedge clk);
        link_ready = 1;
        @(posedge clk);
        @(negedge clk);
        link_ready = 0;

        if (!outstanding || link_valid)
            $fatal(1, "DLL did not wait for ACK after transmit");

        @(negedge clk);
        nak_valid = 1;
        nak_seq   = 0;
        @(posedge clk);
        @(negedge clk);
        nak_valid = 0;

        wait (link_valid);
        if (link_seq != 0 || link_lcrc != 32'hCBF4_3926)
            $fatal(1, "Replay packet changed");

        @(negedge clk);
        link_ready = 1;
        @(posedge clk);
        @(negedge clk);
        link_ready = 0;

        @(negedge clk);
        ack_valid = 1;
        ack_seq   = 0;
        @(posedge clk);
        @(negedge clk);
        ack_valid = 0;

        wait (!outstanding);

        @(negedge clk);
        tlp_valid = 1;
        tlp_data  = 128'h000000000000000000000000DEADBEEF;
        tlp_bytes = 4;
        do @(posedge clk); while (!tlp_ready);
        @(negedge clk);
        tlp_valid = 0;

        wait (link_valid);
        if (link_seq != 1 || link_data[31:0] != 32'hDEAD_BEEF)
            $fatal(1, "Sequence number did not advance after ACK");

        $display("DLL_REPLAY_SMOKE_PASS");
        $finish;
    end

endmodule
