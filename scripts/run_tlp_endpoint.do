transcript on
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vlog -sv -timescale 1ns/1ps rtl/pcie_pkg.sv tb/interface/pcie_packet_if.sv rtl/pcie_endpoint.sv rtl/pcie_tlp_codec.sv rtl/pcie_config_tlp_decoder.sv rtl/pcie_completion_codec.sv rtl/pcie_tlp_bridge.sv rtl/pcie_endpoint_tlp.sv tb/tests/pcie_tlp_endpoint_tb.sv
vsim -c work.pcie_tlp_endpoint_tb
run -all
quit -f
