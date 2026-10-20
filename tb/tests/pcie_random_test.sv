class pcie_random_test extends pcie_base_test;
    `uvm_component_utils(pcie_random_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        pcie_random_seq seq;

        phase.raise_objection(this);
        seq = pcie_random_seq::type_id::create("seq");
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass
