module pcie_aux_blocks_tb;
    bit clk = 0;

    always #5ns clk = ~clk;

    logic        rst_n;
    logic        alloc_valid, alloc_ready, free_valid, free_error;
    logic [1:0]  alloc_tag, free_tag, allocated_tag;
    logic [2:0]  active_count;
    logic        init_valid, update_valid, tx_valid, tx_allowed, credit_error;
    logic [7:0]  init_ph, init_pd, init_nph, init_npd, init_cplh, init_cpld;
    logic [2:0]  update_class, tx_class;
    logic [7:0]  update_header_credits, update_data_credits, tx_data_dwords;
    logic [7:0]  ph_credits, pd_credits, nph_credits, npd_credits, cplh_credits, cpld_credits;

    pcie_tag_tracker #(
        .TAG_COUNT(4),
        .TAG_WIDTH(2)
    ) tags (
        .clk(clk),
        .rst_n(rst_n),
        .alloc_valid(alloc_valid),
        .alloc_ready(alloc_ready),
        .alloc_tag(alloc_tag),
        .free_valid(free_valid),
        .free_tag(free_tag),
        .free_error(free_error),
        .active_count(active_count)
    );

    pcie_fc_credit_mgr credits (
        .clk(clk),
        .rst_n(rst_n),
        .init_valid(init_valid),
        .init_ph(init_ph),
        .init_pd(init_pd),
        .init_nph(init_nph),
        .init_npd(init_npd),
        .init_cplh(init_cplh),
        .init_cpld(init_cpld),
        .update_valid(update_valid),
        .update_class(update_class),
        .update_header_credits(update_header_credits),
        .update_data_credits(update_data_credits),
        .tx_valid(tx_valid),
        .tx_class(tx_class),
        .tx_data_dwords(tx_data_dwords),
        .tx_allowed(tx_allowed),
        .ph_credits(ph_credits),
        .pd_credits(pd_credits),
        .nph_credits(nph_credits),
        .npd_credits(npd_credits),
        .cplh_credits(cplh_credits),
        .cpld_credits(cpld_credits),
        .credit_error(credit_error)
    );

    initial begin
        rst_n       = 0;
        alloc_valid = 0;
        free_valid  = 0;
        free_tag    = 0;
        init_valid  = 0;
        update_valid = 0;
        tx_valid    = 0;
        update_class = 0;
        tx_class    = 0;
        update_header_credits = 0;
        update_data_credits   = 0;
        tx_data_dwords        = 0;
        init_ph   = 2;
        init_pd   = 8;
        init_nph  = 2;
        init_npd  = 8;
        init_cplh = 2;
        init_cpld = 8;

        repeat (2) @(negedge clk);
        rst_n = 1;

        @(negedge clk);
        init_valid = 1;
        @(posedge clk);
        @(negedge clk);
        init_valid = 0;

        if (ph_credits != 2 || pd_credits != 8)
            $fatal(1, "Flow-control initialization failed");

        tx_class       = 3'd0;
        tx_data_dwords = 2;
        tx_valid       = 1;
        #1ns;
        if (!tx_allowed || credit_error)
            $fatal(1, "Expected posted transmission to be allowed");
        @(posedge clk);
        @(negedge clk);
        tx_valid = 0;

        if (ph_credits != 1 || pd_credits != 6)
            $fatal(1, "Credit consumption failed");

        tx_data_dwords = 7;
        #1ns;
        if (tx_allowed)
            $fatal(1, "Transmission allowed without enough data credits");

        @(negedge clk);
        alloc_valid    = 1;
        allocated_tag  = alloc_tag;
        @(posedge clk);
        @(negedge clk);
        alloc_valid = 0;

        if (allocated_tag != 0 || active_count != 1)
            $fatal(1, "First Tag allocation failed");

        free_valid = 1;
        free_tag   = 0;
        #1ns;
        if (free_error)
            $fatal(1, "Valid Tag free flagged as an error");
        @(posedge clk);
        @(negedge clk);
        free_valid = 0;

        if (active_count != 0)
            $fatal(1, "Tag free failed");

        $display("AUX_BLOCKS_SMOKE_PASS");
        $finish;
    end

endmodule
