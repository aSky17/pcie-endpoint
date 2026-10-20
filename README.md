# PCIe Endpoint RTL Design and UVM Verification

SystemVerilog project using the PCI Express Base Specification, Revision 4.0, Version 1.0 as its reference. The RTL uses an explicitly abstracted packet-level request/response boundary; it does not claim a physical-wire TLP implementation or full PCIe compliance.

## Current executable feature set

- Packet-level Configuration Read/Write and Memory Read/Write request interface.
- Configuration register readback for Vendor ID, Device ID, Revision/Class Code, Header Type, BAR0, capability-list pointer, and a basic PCI Express capability header.
- BAR0 sizing-probe behavior for a 256-byte memory window and a fixed model of writable Command/Device Control fields.
- A 256-byte BAR0 memory window with DWORD addressing and per-byte write enables.
- One-entry response buffering with response backpressure.
- Requester ID and Tag propagation into the response model.
- Completion status for supported accesses, unsupported addresses/operations, and a write to the modeled Vendor/Device ID register.
- RTL assertions for response stability under backpressure and unaligned-request reporting.
- UVM active agent, sequence item, sequencer, driver, monitor, reference-model scoreboard, functional coverage subscriber, directed smoke/configuration/byte-enable/error/backpressure/reset/boundary sequences, and constrained-random memory sequence. Coverage is scoped to observed packet-level endpoint transactions; standalone block tests are tracked separately.
- A non-UVM self-checking RTL smoke test, including a bounded 3-DW Memory Request header codec check and CRC-32 known-answer test.
- Standalone bounded 3-DW Memory Request and Completion header codecs, plus a CRC-32 known-answer test.
- Integrated bounded TLP-to-Endpoint adapter (`pcie_tlp_bridge.sv` + `pcie_endpoint_tlp.sv`) for one-DWORD, 3-DW Memory Read/Write and Configuration Type 0 Read/Write TLPs; successful posted Memory Writes are suppressed from Completion output, successful reads return Completion-with-Data, Configuration Writes return Completion without Data, and unsupported non-posted requests return Unsupported Request Completions.
- Standalone bounded Data Link replay controller with sequence tracking, LCRC attachment, ACK/NAK/replay-timeout handling, plus a dedicated replay smoke test.
- Standalone Tag allocator and flow-control credit accounting blocks; these are reusable building blocks, not yet integrated into the Endpoint datapath.

## Important protocol boundary

The internal request/response interface is a project abstraction, but the added `pcie_endpoint_tlp` top accepts a bounded 96-bit 3-DW TLP header plus an optional one-DWORD payload. This is not a serialized PCIe link. The design does not currently implement a PCIe PHY, LTSSM, lane training, Gen4 electrical behavior, complete Configuration Space semantics, all TLP encodings, DLLP wire encoding/decoding, a fully integrated PCIe Data Link Layer, full multi-packet replay buffering, per-VC flow control, MSI/MSI-X, or a complete DMA requester. The TLP codec, integrated bounded Memory/Configuration Request bridge, LCRC helper, replay controller, Tag allocator, and credit manager are bounded modules and are not evidence of complete PCIe layer compliance. Those features are described in the specification documents as desired engineering scope, but are not to be represented as implemented until corresponding RTL and passing verification evidence exist.

## Repository layout

- `rtl/`: synthesizable packet-level Endpoint logic and protocol package.
- `tb/interface/`: packet-level interface.
- `tb/`: UVM items, sequences, active agent, monitor, driver, scoreboard, coverage, tests, and top.
- `docs/`: feature specification, architecture, test plan, feature-status matrix, assertions, coverage, traceability, and signoff templates.
- `scripts/`: Questa compile/run scripts and regression runner.
- `sim/logs/`: simulator output logs.

## Run with Questa

Open a Questa-enabled terminal in the repository root.

Run the non-UVM RTL smoke test:

```tcl
vsim -c -do scripts/run_rtl_smoke.do
```

Run the integrated bounded TLP Endpoint test (new packet-level TLP ingress/egress path):

```tcl
vsim -c -do scripts/run_tlp_endpoint.do
```

Run the standalone Data Link replay smoke test:

```tcl
vsim -c -do scripts/run_dll_smoke.do
```

Compile and run the UVM directed smoke test:

```tcl
vsim -c -do scripts/run.do
```

Run the standalone Data Link replay and auxiliary block tests:

```tcl
vsim -c -do scripts/run_dll_smoke.do
vsim -c -do scripts/run_aux_smoke.do
```

Run the BAR boundary and byte-enable directed test:

```tcl
vsim -c -do scripts/run_boundary.do
```

Run the constrained-random UVM test:

```tcl
vsim -c -do scripts/run_random.do
```

If the local Questa distribution uses a different precompiled UVM library name or setup, update the `-L mtiUvm` option in the scripts to match the installed simulator. The RTL smoke test does not depend on UVM.

## Regression

```bash
python scripts/regress.py
```

The runner writes logs under `sim/logs/`. A successful process exit alone is not signoff: inspect the UVM summary and log for errors, fatals, assertion failures, and scoreboard mismatches. Coverage and test counts must be recorded from actual runs.

## Status policy

`docs/feature_specification.md` and `docs/known_limitations.md` distinguish the currently implemented subset from planned protocol functionality. The verification plan and test matrix are requirements, not evidence that every listed feature already exists. Do not claim full PCIe 4.0 compliance or full three-layer implementation based on this packet-level model.

## Combined packet-level coverage regression

Run the combined endpoint sequence set in one simulation so functional coverage accumulates across smoke, configuration, byte-enable, error, backpressure, boundary, mixed-operation, and constrained-random traffic:

```tcl
vsim -c -do scripts/run_coverage_regression.do
```

The script requests a detailed simulator coverage report and saves a UCDB under `sim/coverage/` when supported by the local Questa configuration. Run reset and standalone RTL block tests separately. A coverage percentage is meaningful only after reviewing the uncovered bins and confirming that the run has no scoreboard mismatches, UVM errors/fatals, or assertion failures. No coverage percentage is claimed in this repository without a simulator-generated report.
