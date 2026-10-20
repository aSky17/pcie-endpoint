class pcie_driver extends uvm_driver #(pcie_tlp_item);
    `uvm_component_utils(pcie_driver)

    virtual pcie_packet_if vif;

    // Prevent a handshake from waiting forever.
    localparam int MAX_HANDSHAKE_CYCLES = 1000;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual pcie_packet_if)::get(
              this, "", "vif", vif
            )) begin
            `uvm_fatal("NOVIF",
                "pcie_driver did not receive virtual interface")
        end
    endfunction

    task automatic wait_for_reset_release();
        wait (vif.rst_n === 1'b1);
        @(negedge vif.clk);
    endtask

    task automatic wait_for_req_ready();
        int cycles = 0;

        while (vif.req_ready !== 1'b1) begin
            @(posedge vif.clk);
            cycles++;

            if (cycles >= MAX_HANDSHAKE_CYCLES) begin
                `uvm_fatal("REQ_TIMEOUT",
                    "Timed out waiting for req_ready")
            end
        end
    endtask

    task automatic wait_for_rsp_valid();
        int cycles = 0;

        while (vif.rsp_valid !== 1'b1) begin
            @(posedge vif.clk);
            cycles++;

            if (cycles >= MAX_HANDSHAKE_CYCLES) begin
                `uvm_fatal("RSP_TIMEOUT",
                    "Timed out waiting for rsp_valid")
            end
        end
    endtask

    task run_phase(uvm_phase phase);
        pcie_tlp_item tr;

        // Keep the interface idle until reset has been released.
        vif.req_valid <= 1'b0;
        vif.rsp_ready <= 1'b0;

        wait_for_reset_release();

        forever begin
            seq_item_port.get_next_item(tr);

            // Drive request on the falling edge.
            @(negedge vif.clk);
            vif.req_op           <= tr.op;
            vif.req_addr         <= tr.addr;
            vif.req_wdata        <= tr.wdata;
            vif.req_be           <= tr.byte_enable;
            vif.req_tag          <= tr.tag;
            vif.req_requester_id <= tr.requester_id;
            vif.req_valid        <= 1'b1;

            // Wait for request acceptance.
            wait_for_req_ready();

            // Deassert request after the accepting edge.
            @(negedge vif.clk);
            vif.req_valid <= 1'b0;

            // Allow the requested response stall.
            repeat (tr.response_stall)
                @(negedge vif.clk);

            vif.rsp_ready <= 1'b1;

            // Wait for the endpoint's response.
            wait_for_rsp_valid();

            // Capture response fields while valid is asserted.
            tr.rdata        = vif.rsp_rdata;
            tr.completer_id = vif.rsp_completer_id;
            tr.status       = vif.rsp_status;
            tr.byte_count   = vif.rsp_byte_count;

            if (vif.rsp_tag !== tr.tag)
                `uvm_error("TAG",
                    "Response Tag mismatch in driver")

            if (vif.rsp_requester_id !== tr.requester_id)
                `uvm_error("RID",
                    "Response Requester ID mismatch in driver")

            // Complete the response handshake.
            @(negedge vif.clk);
            vif.rsp_ready <= 1'b0;

            seq_item_port.item_done();
        end
    endtask

endclass
