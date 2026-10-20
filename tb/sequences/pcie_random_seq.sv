class pcie_random_seq extends pcie_base_seq;
    `uvm_object_utils(pcie_random_seq)

    function new(string name = "pcie_random_seq");
        super.new(name);
    endfunction

    task body();
        pcie_tlp_item tr;

        repeat (200) begin
            tr = pcie_tlp_item::type_id::create("random_tr");
            start_item(tr);

            if (!tr.randomize() with {
                op inside {PCIE_OP_MEM_READ, PCIE_OP_MEM_WRITE};
                addr inside {[32'h1000:32'h10FC]};
                addr[1:0] == 0;
                byte_enable inside {4'h0, 4'h1, 4'h2, 4'h4, 4'h8, 4'h3, 4'hC, 4'hF};
                response_stall inside {[0:8]};
            })
                `uvm_error("RAND", "Unable to randomize transaction")

            tr.requester_id = 16'h0100;
            finish_item(tr);
        end
    endtask

endclass
