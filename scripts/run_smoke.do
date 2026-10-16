transcript on

if {![file exists work]} {
  vlib work
}

vlog -sv tb/tests/smoke_tb.sv
vsim -c work.smoke_tb
run -all
quit -f
