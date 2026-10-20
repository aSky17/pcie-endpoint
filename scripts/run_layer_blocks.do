transcript on
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vlog -sv -timescale 1ns/1ps rtl/pcie_tlp_header_check.sv rtl/pcie_dllp_codec.sv rtl/pcie_dll_rx_seq.sv tb/tests/pcie_layer_blocks_tb.sv
vsim -c work.pcie_layer_blocks_tb
run -all
quit -f
