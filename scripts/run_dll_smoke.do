transcript on
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vlog -sv -timescale 1ns/1ps rtl/pcie_lcrc32.sv rtl/pcie_dll_replay.sv tb/tests/pcie_dll_replay_tb.sv
vsim -c work.pcie_dll_replay_tb
run -all
quit -f
