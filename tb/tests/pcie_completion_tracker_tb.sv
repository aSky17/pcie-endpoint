`timescale 1ns/1ps

module pcie_completion_tracker_tb;
    localparam int TAG_COUNT = 8, TAG_WIDTH = 3;

    logic clk = 0, rst_n = 0;

    always #5 clk = ~clk;

    logic        req_valid, req_ready;
    logic [TAG_WIDTH-1:0] req_tag;
    logic [15:0] req_requester_id;
    logic [11:0] req_expected_bytes;
    logic [6:0]  req_lower_address;
    logic        cpl_valid;
    logic [TAG_WIDTH-1:0] cpl_tag;
    logic [15:0] cpl_requester_id;
    logic [2:0]  cpl_status;
    logic [11:0] cpl_byte_count;
    logic [6:0]  cpl_lower_address;
    logic        cpl_match, cpl_error;
    logic [3:0]  cpl_error_code;
    logic [TAG_COUNT-1:0] outstanding_bitmap;
    logic [$clog2(TAG_COUNT+1)-1:0] outstanding_count;

    pcie_completion_tracker #(
        .TAG_COUNT(TAG_COUNT)
    ) dut (
        .*
    );

    task automatic tick;
        @(posedge clk);
        #1;
    endtask

    task automatic allocate(
        input [2:0] tag,
        input [15:0] rid,
        input [11:0] bytes,
        input [6:0] lowaddr
    );
        @(negedge clk);
        req_valid          = 1;
        req_tag            = tag;
        req_requester_id   = rid;
        req_expected_bytes = bytes;
        req_lower_address  = lowaddr;
        #1;
        if (!req_ready)
            $fatal(1, "Expected Tag allocation ready");
        tick();
        @(negedge clk);
        req_valid = 0;
    endtask

    initial begin
        req_valid          = 0;
        req_tag            = 0;
        req_requester_id   = 0;
        req_expected_bytes = 0;
        req_lower_address  = 0;
        cpl_valid          = 0;
        cpl_tag            = 0;
        cpl_requester_id   = 0;
        cpl_status         = 0;
        cpl_byte_count     = 0;
        cpl_lower_address  = 0;

        repeat (2) tick();
        rst_n = 1;
        tick();

        allocate(3'd2, 16'h1234, 12'd16, 7'h20);
        allocate(3'd5, 16'h1234, 12'd8,  7'h40);

        if (outstanding_count != 2)
            $fatal(1, "Outstanding count should be 2");

        @(negedge clk);
        cpl_valid          = 1;
        cpl_tag            = 2;
        cpl_requester_id   = 16'h1234;
        cpl_status         = 0;
        cpl_byte_count     = 16;
        cpl_lower_address  = 7'h20;
        #1;
        if (!cpl_match || cpl_error)
            $fatal(1, "Valid Completion rejected");
        tick();
        @(negedge clk);
        cpl_valid = 0;

        if (outstanding_count != 1 || outstanding_bitmap[2])
            $fatal(1, "Completion did not free Tag");

        @(negedge clk);
        cpl_valid          = 1;
        cpl_tag            = 5;
        cpl_requester_id   = 16'h9999;
        cpl_status         = 0;
        cpl_byte_count     = 8;
        cpl_lower_address  = 7'h40;
        #1;
        if (!cpl_error || cpl_error_code != 3)
            $fatal(1, "Requester ID mismatch not detected");
        tick();
        @(negedge clk);
        cpl_valid = 0;

        if (outstanding_count != 1)
            $fatal(1, "Invalid Completion must not free Tag");

        @(negedge clk);
        cpl_valid          = 1;
        cpl_tag            = 5;
        cpl_requester_id   = 16'h1234;
        cpl_status         = 0;
        cpl_byte_count     = 7;
        cpl_lower_address  = 7'h40;
        #1;
        if (!cpl_error || cpl_error_code != 4)
            $fatal(1, "Byte Count mismatch not detected");
        tick();
        @(negedge clk);
        cpl_valid = 0;

        @(negedge clk);
        cpl_valid          = 1;
        cpl_tag            = 5;
        cpl_requester_id   = 16'h1234;
        cpl_status         = 0;
        cpl_byte_count     = 8;
        cpl_lower_address  = 7'h40;
        #1;
        if (!cpl_match)
            $fatal(1, "Corrected Completion rejected");
        tick();
        @(negedge clk);
        cpl_valid = 0;

        if (outstanding_count != 0)
            $fatal(1, "Outstanding table should be empty");

        $display("COMPLETION_TRACKER_PASS");
        $finish;
    end

endmodule
