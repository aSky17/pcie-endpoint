transcript on
do scripts/compile.do
vsim -voptargs=+acc -L mtiUvm work.pcie_tb_top +UVM_TESTNAME=pcie_boundary_test
run -all
quit -f
