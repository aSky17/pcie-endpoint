transcript on
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vlog -sv -timescale 1ns/1ps rtl/pcie_completion_tracker.sv tb/tests/pcie_completion_tracker_tb.sv
vsim -c work.pcie_completion_tracker_tb
run -all
quit -f
