class pcie_base_test extends uvm_test;
    `uvm_component_utils(pcie_base_test)

    pcie_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = pcie_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        pcie_smoke_seq seq;

        phase.raise_objection(this);
        seq = pcie_smoke_seq::type_id::create("seq");
        seq.start(env.agent.sequencer);
        #100ns;
        phase.drop_objection(this);
    endtask

endclass
