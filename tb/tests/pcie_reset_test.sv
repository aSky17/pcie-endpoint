class pcie_reset_test extends pcie_base_test;
    `uvm_component_utils(pcie_reset_test)

    virtual pcie_packet_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual pcie_packet_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "pcie_reset_test did not receive virtual interface")
    endfunction

    task run_phase(uvm_phase phase);
        pcie_reset_prepare_seq prep;
        pcie_reset_check_seq   check_seq;

        phase.raise_objection(this);

        prep = pcie_reset_prepare_seq::type_id::create("prep");
        prep.start(env.agent.sequencer);

        @(negedge vif.clk);
        vif.rst_n = 0;
        repeat (3) @(negedge vif.clk);
        vif.rst_n = 1;

        env.scoreboard.model_mem.delete();
        env.scoreboard.model_cfg.delete();
        env.scoreboard.bar0_probe_model = 0;

        repeat (2) @(negedge vif.clk);

        check_seq = pcie_reset_check_seq::type_id::create("check_seq");
        check_seq.start(env.agent.sequencer);

        phase.drop_objection(this);
    endtask

endclass
