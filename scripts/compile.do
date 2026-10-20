transcript on
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
set inc_opts "+incdir+tb"
if {[info exists ::env(UVM_HOME)]} {
  if {[file exists "$::env(UVM_HOME)/uvm_macros.svh"]} {
    append inc_opts " +incdir+$::env(UVM_HOME)"
  } elseif {[file exists "$::env(UVM_HOME)/src/uvm_macros.svh"]} {
    append inc_opts " +incdir+$::env(UVM_HOME)/src"
  }
} elseif {[info exists ::env(QUESTA_HOME)]} {
  if {[file exists "$::env(QUESTA_HOME)/verilog_src/uvm-1.2/src/uvm_macros.svh"]} {
    append inc_opts " +incdir+$::env(QUESTA_HOME)/verilog_src/uvm-1.2/src"
  } elseif {[file exists "$::env(QUESTA_HOME)/verilog_src/uvm-1.1d/src/uvm_macros.svh"]} {
    append inc_opts " +incdir+$::env(QUESTA_HOME)/verilog_src/uvm-1.1d/src"
  }
}
eval vlog -sv -timescale 1ns/1ps -L mtiUvm $inc_opts rtl/pcie_pkg.sv rtl/pcie_tlp_codec.sv rtl/pcie_completion_codec.sv rtl/pcie_lcrc32.sv rtl/pcie_dll_replay.sv rtl/pcie_tag_tracker.sv rtl/pcie_fc_credit_mgr.sv tb/interface/pcie_packet_if.sv rtl/pcie_endpoint.sv tb/pkg/pcie_tb_pkg.sv tb/top/pcie_tb_top.sv
