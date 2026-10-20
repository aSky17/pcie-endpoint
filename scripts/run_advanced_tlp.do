transcript on
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vlog -sv -timescale 1ns/1ps rtl/pcie_completion_assembler.sv rtl/pcie_tlp_packet_buffer.sv tb/tests/pcie_advanced_tlp_tb.sv
vsim -c work.pcie_advanced_tlp_tb
run -all
quit -f
