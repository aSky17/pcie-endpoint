transcript on
do scripts/compile.do
vsim -coverage -voptargs=+acc -L mtiUvm work.pcie_tb_top +UVM_TESTNAME=pcie_coverage_regression_test
run -all
coverage report -details
coverage save sim/coverage/pcie_coverage_regression.ucdb
quit -f
