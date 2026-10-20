class pcie_monitor extends uvm_component;
    `uvm_component_utils(pcie_monitor)

    virtual pcie_packet_if vif;
    uvm_analysis_port #(pcie_tlp_item) ap;
    pcie_tlp_item pending;
    bit have_request;
    int unsigned observed_stall;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual pcie_packet_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "pcie_monitor did not receive virtual interface")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            @(posedge vif.clk);

            if (!vif.rst_n) begin
                have_request    = 0;
                pending         = null;
                observed_stall  = 0;
            end else begin
                if (vif.rsp_valid && !vif.rsp_ready)
                    observed_stall++;

                if (vif.req_valid && vif.req_ready) begin
                    pending = pcie_tlp_item::type_id::create("observed_request");
                    pending.op           = vif.req_op;
                    pending.addr         = vif.req_addr;
                    pending.wdata        = vif.req_wdata;
                    pending.byte_enable  = vif.req_be;
                    pending.tag          = vif.req_tag;
                    pending.requester_id = vif.req_requester_id;
                    have_request         = 1;
                end

                if (vif.rsp_valid && vif.rsp_ready) begin
                    if (!have_request || pending == null)
                        `uvm_error("ORPHAN_RSP", "Response observed without a request")
                    else begin
                        pending.rdata          = vif.rsp_rdata;
                        pending.completer_id   = vif.rsp_completer_id;
                        pending.status         = vif.rsp_status;
                        pending.byte_count     = vif.rsp_byte_count;
                        pending.response_stall = observed_stall;
                        ap.write(pending);
                        pending        = null;
                        have_request   = 0;
                        observed_stall = 0;
                    end
                end
            end
        end
    endtask

endclass
