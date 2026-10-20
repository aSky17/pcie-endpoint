 do scripts/compile.do
 vsim -L mtiUvm work.pcie_tb_top +UVM_TESTNAME=pcie_error_test
 run -all
 quit -f
