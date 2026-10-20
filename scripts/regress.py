#!/usr/bin/env python3
"""Run the available RTL and UVM tests with retained logs."""
import argparse
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
TEST_SCRIPTS = {
    "rtl_smoke": "scripts/run_rtl_smoke.do",
    "dll_smoke": "scripts/run_dll_smoke.do",
    "aux_smoke": "scripts/run_aux_smoke.do",
    "layer_blocks_smoke": "scripts/run_layer_blocks.do",
    "tlp_endpoint_smoke": "scripts/run_tlp_endpoint.do",
    "advanced_tlp_smoke": "scripts/run_advanced_tlp.do",
    "pcie_config_test": "scripts/run_config.do",
    "pcie_byte_enable_test": "scripts/run_byte_enable.do",
    "pcie_error_test": "scripts/run_error.do",
    "pcie_backpressure_test": "scripts/run_backpressure.do",
    "pcie_reset_test": "scripts/run_reset.do",
    "pcie_boundary_test": "scripts/run_boundary.do",
    "pcie_coverage_regression": "scripts/run_coverage_regression.do",
    "pcie_smoke_test": "scripts/run.do",
    "pcie_random_test": "scripts/run_random.do",
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--vsim", default="vsim", help="Questa vsim executable")
    parser.add_argument("--tests", nargs="*", default=list(TEST_SCRIPTS), choices=list(TEST_SCRIPTS))
    args = parser.parse_args()
    log_dir = ROOT / "sim" / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    failures = []
    for test in args.tests:
        log_path = log_dir / f"{test}.log"
        cmd = [args.vsim, "-c", "-do", TEST_SCRIPTS[test]]
        print(f"RUN {test}")
        with log_path.open("w", encoding="utf-8") as log:
            proc = subprocess.run(cmd, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, text=True)
        contents = log_path.read_text(encoding="utf-8", errors="replace")
        if test in {"rtl_smoke", "dll_smoke", "aux_smoke", "layer_blocks_smoke", "tlp_endpoint_smoke", "advanced_tlp_smoke"}:
            marker = {"rtl_smoke": "RTL_SMOKE_PASS", "dll_smoke": "DLL_REPLAY_SMOKE_PASS", "aux_smoke": "AUX_BLOCKS_SMOKE_PASS", "layer_blocks_smoke": "PCIE_LAYER_BLOCKS_PASS", "tlp_endpoint_smoke": "TLP_ENDPOINT_PASS", "advanced_tlp_smoke": "PCIE_ADVANCED_TLP_PASS"}[test]
            passed = proc.returncode == 0 and marker in contents
        else:
            passed = (proc.returncode == 0
                      and re.search(r"UVM_FATAL\s*:\s*0", contents) is not None
                      and re.search(r"UVM_ERROR\s*:\s*0", contents) is not None)
        print(f"{'PASS' if passed else 'FAIL'} {test} (exit={proc.returncode}; log={log_path.relative_to(ROOT)})")
        if not passed:
            failures.append(test)
    print(f"SUMMARY passed={len(args.tests)-len(failures)} failed={len(failures)}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
