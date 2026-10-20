transcript on
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vlog -sv -timescale 1ns/1ps rtl/pcie_tag_tracker.sv rtl/pcie_fc_credit_mgr.sv tb/tests/pcie_aux_blocks_tb.sv
vsim -c work.pcie_aux_blocks_tb
run -all
quit -f
