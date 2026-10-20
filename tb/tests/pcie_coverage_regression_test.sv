// One-run directed regression so packet-level functional coverage accumulates
// across the supported endpoint scenarios in a single simulation database.
class pcie_coverage_regression_test extends pcie_base_test;
    `uvm_component_utils(pcie_coverage_regression_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        pcie_smoke_seq           smoke;
        pcie_config_seq          cfg;
        pcie_byte_enable_seq     be_seq;
        pcie_error_seq           err_seq;
        pcie_backpressure_seq    bp_seq;
        pcie_boundary_seq        boundary;
        pcie_random_seq          rand_seq;
        pcie_mixed_traffic_seq   mixed_seq;

        phase.raise_objection(this);

        smoke     = pcie_smoke_seq::type_id::create("smoke");
        cfg       = pcie_config_seq::type_id::create("cfg");
        be_seq    = pcie_byte_enable_seq::type_id::create("be_seq");
        err_seq   = pcie_error_seq::type_id::create("err_seq");
        bp_seq    = pcie_backpressure_seq::type_id::create("bp_seq");
        boundary  = pcie_boundary_seq::type_id::create("boundary");
        rand_seq  = pcie_random_seq::type_id::create("rand_seq");
        mixed_seq = pcie_mixed_traffic_seq::type_id::create("mixed_seq");

        smoke.start(env.agent.sequencer);
        cfg.start(env.agent.sequencer);
        be_seq.start(env.agent.sequencer);
        err_seq.start(env.agent.sequencer);
        bp_seq.start(env.agent.sequencer);
        boundary.start(env.agent.sequencer);
        mixed_seq.start(env.agent.sequencer);
        rand_seq.start(env.agent.sequencer);

        // Allow monitor analysis writes and scoreboard reporting to settle.
        #100ns;
        phase.drop_objection(this);
    endtask

endclass
