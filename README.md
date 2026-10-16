# PCIe Endpoint RTL + UVM Project

This repository is a starting scaffold for a simulation-based PCIe 4.0 Endpoint project.

## Project boundaries

- Baseline: PCI Express Base Specification, Revision 4.0, Version 1.0.
- First target: Endpoint protocol logic using an abstract packet-level link boundary.
- Simulator target: QuestaSim / Questa, subject to the installed edition's SystemVerilog and UVM support.
- Not a complete PCIe compliance implementation; the implemented subset will be documented as we study the specification.

## Initial setup

1. Extract this repository to a development folder, for example `C:\dev\pcie-endpoint-project`.
2. Open **QuestaSim/Questa Command Prompt** or a terminal where `vlib`, `vlog`, and `vsim` are on `PATH`.
3. From the project root, run:

   ```powershell
   vsim -version
   vlog -version
   ```

4. Run the smoke test:

   ```powershell
   vsim -c -do scripts/run_smoke.do
   ```

   If your installation does not expose the executables on `PATH`, launch Questa from its installation directory or configure `PATH` for that terminal. Do not guess the installation path; use the actual path on your machine.

## Current smoke test

The smoke test only checks that Questa can compile and run a SystemVerilog testbench. It intentionally contains no PCIe protocol behavior and no UVM dependency yet.

## Planned implementation workflow

For each phase:
1. Read the relevant sections of `PCIE_V4.0.pdf`.
2. Record exact specification rules and the project subset in `docs/specification_traceability.md`.
3. Add directed tests and expected outcomes.
4. Implement the RTL feature.
5. Run directed, negative, then randomized tests.
6. Record results and known limitations before moving to the next phase.

## Repository map

- `rtl/`: synthesizable design code, added phase by phase.
- `tb/`: testbench, agents, sequences, scoreboard, reference model, and tests.
- `assertions/`: protocol and design invariants.
- `docs/`: architecture, specification notes, decisions, coverage, and phase logs.
- `scripts/`: simulator scripts.
- `sim/`: file lists and simulation configurations.
- `results/`: local simulation outputs; normally do not commit large generated logs.

## Next step

Confirm the simulator smoke test passes. Then begin Chapter 2, Sections 2.1–2.1.2 of the supplied PCIe 4.0 specification and define the first supported TLP subset before writing protocol RTL.
