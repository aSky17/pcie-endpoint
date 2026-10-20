 do scripts/compile.do
 vsim -L mtiUvm work.pcie_tb_top +UVM_TESTNAME=pcie_backpressure_test
 run -all
 quit -f
