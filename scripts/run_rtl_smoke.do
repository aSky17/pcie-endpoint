transcript on
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vlog -sv -timescale 1ns/1ps rtl/pcie_pkg.sv rtl/pcie_tlp_codec.sv rtl/pcie_completion_codec.sv rtl/pcie_lcrc32.sv rtl/pcie_dll_replay.sv rtl/pcie_tag_tracker.sv rtl/pcie_fc_credit_mgr.sv tb/interface/pcie_packet_if.sv rtl/pcie_endpoint.sv tb/tests/pcie_rtl_smoke_tb.sv
vsim -c work.pcie_rtl_smoke_tb
run -all
quit -f
