class pcie_coverage extends uvm_subscriber #(pcie_tlp_item);
    `uvm_component_utils(pcie_coverage)

    pcie_tlp_item sample_item;

    covergroup pcie_cg;
        option.per_instance = 1;

        cp_op: coverpoint sample_item.op {
            bins cfg_read  = {PCIE_OP_CFG_READ};
            bins cfg_write = {PCIE_OP_CFG_WRITE};
            bins mem_read  = {PCIE_OP_MEM_READ};
            bins mem_write = {PCIE_OP_MEM_WRITE};
        }

        cp_status: coverpoint sample_item.status {
            bins success   = {PCIE_CPL_SUCCESS};
            bins ur        = {PCIE_CPL_UR};
            bins ca        = {PCIE_CPL_CA};
            bins malformed = {PCIE_CPL_MALFORMED};
        }

        cp_be: coverpoint sample_item.byte_enable {
            bins zero         = {4'h0};
            bins single_byte[] = {4'h1, 4'h2, 4'h4, 4'h8};
            bins lower_half   = {4'h3};
            bins upper_half   = {4'hC};
            bins sparse[]     = {4'h5, 4'h6, 4'h9, 4'hA};
            bins three_bytes[] = {4'h7, 4'hB, 4'hD, 4'hE};
            bins full         = {4'hF};
        }

        cp_stall: coverpoint sample_item.response_stall {
            bins none         = {0};
            bins short_stall  = {[1:2]};
            bins medium_stall = {[3:5]};
            bins long_stall   = {[6:8]};
        }

        cp_tag: coverpoint sample_item.tag {
            bins low    = {[0:15]};
            bins middle = {[16:127]};
            bins high   = {[128:255]};
        }

        cp_region: coverpoint sample_item.addr {
            bins cfg_space    = {[32'h0000_0000:32'h0000_00FC]};
            bins bar_first    = {32'h0000_1000};
            bins bar_interior = {[32'h0000_1004:32'h0000_10F8]};
            bins bar_last     = {32'h0000_10FC};
            bins outside_bar  = default;
        }

        cp_requester: coverpoint sample_item.requester_id {
            bins default_requester = {16'h0100};
            bins other_requester   = default;
        }

        cp_is_read: coverpoint (sample_item.op inside {PCIE_OP_CFG_READ, PCIE_OP_MEM_READ}) {
            bins read  = {1};
            bins write = {0};
        }

        op_x_status:        cross cp_op, cp_status;
        op_x_be:            cross cp_op, cp_be;
        op_x_stall:         cross cp_op, cp_stall;
        region_x_op:        cross cp_region, cp_op;
        readwrite_x_region: cross cp_is_read, cp_region;
    endgroup

    int unsigned observed_transactions;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        pcie_cg = new();
        observed_transactions = 0;
    endfunction

    function void write(pcie_tlp_item t);
        sample_item = t;
        pcie_cg.sample();
        observed_transactions++;
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("COVERAGE",
            $sformatf("Observed packet transactions=%0d; packet functional coverage=%0.2f%% (abstract endpoint subscriber only)",
                      observed_transactions, pcie_cg.get_coverage()),
            UVM_LOW)
    endfunction

endclass
