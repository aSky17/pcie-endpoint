.PHONY: rtl-smoke dll-smoke aux-smoke layer-blocks-smoke tlp-endpoint-smoke advanced-tlp-smoke uvm-smoke random regression directed
rtl-smoke:
	vsim -c -do scripts/run_rtl_smoke.do
dll-smoke:
	vsim -c -do scripts/run_dll_smoke.do
aux-smoke:
	vsim -c -do scripts/run_aux_smoke.do
layer-blocks-smoke:
	vsim -c -do scripts/run_layer_blocks.do
tlp-endpoint-smoke:
	vsim -c -do scripts/run_tlp_endpoint.do
advanced-tlp-smoke:
	vsim -c -do scripts/run_advanced_tlp.do
uvm-smoke:
	vsim -c -do scripts/run.do
random:
	vsim -c -do scripts/run_random.do
directed:
	python scripts/regress.py --tests rtl_smoke dll_smoke aux_smoke layer_blocks_smoke tlp_endpoint_smoke pcie_smoke_test pcie_config_test pcie_byte_enable_test pcie_error_test pcie_backpressure_test pcie_reset_test
regression:
	python scripts/regress.py
