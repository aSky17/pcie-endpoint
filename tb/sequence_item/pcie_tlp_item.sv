class pcie_tlp_item extends uvm_sequence_item;
    rand pcie_op_e     op;
    rand bit [31:0]    addr;
    rand bit [31:0]    wdata;
    rand bit [3:0]     byte_enable;
    rand bit [7:0]     tag;
    rand bit [15:0]    requester_id;
    rand int unsigned  response_stall;
    bit [31:0]         rdata;
    bit [15:0]         completer_id;
    pcie_cpl_status_e  status;
    bit [3:0]          byte_count;

    constraint c_aligned {
        addr[1:0] == 2'b00;
    }

    constraint c_supported_op {
        op inside {PCIE_OP_CFG_READ, PCIE_OP_CFG_WRITE,
                   PCIE_OP_MEM_READ, PCIE_OP_MEM_WRITE};
    }

    constraint c_be {
        byte_enable inside {[4'b0000:4'b1111]};
    }

    constraint c_stall {
        response_stall inside {[0:8]};
    }

    `uvm_object_utils_begin(pcie_tlp_item)
        `uvm_field_enum(pcie_op_e, op, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(wdata, UVM_ALL_ON)
        `uvm_field_int(byte_enable, UVM_ALL_ON)
        `uvm_field_int(tag, UVM_ALL_ON)
        `uvm_field_int(requester_id, UVM_ALL_ON)
        `uvm_field_int(response_stall, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
        `uvm_field_int(completer_id, UVM_ALL_ON)
        `uvm_field_enum(pcie_cpl_status_e, status, UVM_ALL_ON)
        `uvm_field_int(byte_count, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "pcie_tlp_item");
        super.new(name);
    endfunction

endclass
