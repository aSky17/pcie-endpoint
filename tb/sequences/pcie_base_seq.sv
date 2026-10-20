class pcie_base_seq extends uvm_sequence #(pcie_tlp_item);
    `uvm_object_utils(pcie_base_seq)

    function new(string name = "pcie_base_seq");
        super.new(name);
    endfunction

    task send_tx(pcie_op_e op, bit [31:0] addr, bit [31:0] data = 0,
                 bit [3:0] be = 4'hF, bit [7:0] tag = 0, int unsigned stall = 0);
        pcie_tlp_item tr = pcie_tlp_item::type_id::create("tr");

        start_item(tr);
        tr.op             = op;
        tr.addr           = addr;
        tr.wdata          = data;
        tr.byte_enable    = be;
        tr.tag            = tag;
        tr.requester_id   = 16'h0100;
        tr.response_stall = stall;
        finish_item(tr);

        `uvm_info("PCIE_SEQ",
            $sformatf("op=%0d addr=%08x data=%08x rdata=%08x status=%0d",
                      op, addr, data, tr.rdata, tr.status),
            UVM_MEDIUM)
    endtask

endclass
