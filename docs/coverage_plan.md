# Functional and Code Coverage Plan

## 1. Principles

Coverage is sampled from observed accepted packets, observed responses, and actual state transitions. Sequence intent alone is not coverage. Coverage goals apply to implemented features and must include documented exclusions with technical justification.

## 2. Transaction Layer covergroups

### Packet format and type
- Supported Fmt encodings.
- Supported Type encodings.
- Header size: 3-DW/4-DW where applicable.
- Payload present/absent.
- Supported request classes: Memory Read, Memory Write, Configuration Read/Write, Completion, and any implemented Message/Atomic operation.
- Unsupported/malformed categories in negative coverage.

### Address and BAR
- Every implemented BAR/region.
- First/last legal DWORD and selected interior locations.
- Boundary crossing, alignment, unmapped address, and out-of-range access.
- Operation type × address region.

### Length and byte enables
- Minimum, typical, maximum supported, and invalid lengths.
- Single-DWORD and multi-DWORD transactions.
- First DW BE and Last DW BE legal patterns for each supported request length class.
- Full, sparse, leading/trailing, and zero-enable cases where legal.
- Length × request type; byte-enable class × write type; length × boundary condition.

### Completion
- Completion with/without Data as applicable.
- Success and each implemented unsuccessful status.
- Tag, Requester ID, Completer ID matching classes.
- Byte Count and Lower Address boundary classes.
- Completion payload length and split-completion index if supported.
- Request type × Completion status; length × Completion form.

### Configuration
- Each implemented register and field class: writable, read-only, reserved, W1C/special semantics if present.
- Read/write operation × register class.
- Capability structure × access type.
- Reset value observation and write mask behavior.

### Requester/outstanding traffic
- Active outstanding request count: zero, one, intermediate, configured maximum.
- Tag allocation/release and wrap/reuse boundary.
- Completion arrival order: in-order and permitted out-of-order.
- Completion size/count progression for split Completion support.
- Timeout, unexpected, duplicate, and mismatched Completion cases.

### Errors/reset/backpressure
- Each implemented error category.
- Reset from idle, request reception, response transmission, outstanding requester state, replay, and flow-control initialization.
- Stall duration classes: none, short, medium, long/boundary.
- Stall × request type and stall × response type.
- Error category × packet type; reset state × outstanding work.

## 3. Data Link covergroups

- DLL state transitions and link-up/down.
- DLLP type, valid/corrupt, and control outcome.
- Sequence number: initial, normal increment, wraparound, mismatch, duplicate.
- LCRC: valid, injected corruption, boundary vectors.
- ACK/NAK: normal acknowledgement, negative acknowledgement, delayed/lost acknowledgement, acknowledgement of outstanding buffered TLPs.
- Replay: no replay, single replay, repeated replay, timer expiry, buffer boundary/full condition, reset during replay.
- Flow control: initialization states, credit class, available/consumed/returned credit buckets, exhausted/replenished, invalid update.
- Crosses: packet integrity outcome × ACK/NAK outcome; replay cause × buffer occupancy; credit state × packet class; link state × TLP transmission attempt.

## 4. Behavioral Physical Layer/link-model coverage

- Link state: down, initializing, active, retraining/recovery, failed, as implemented.
- Packet delivery outcome: normal, delayed, blocked, dropped, corrupted, duplicated (in fault tests only).
- Error injection point × packet class.
- Link event × outstanding request/replay state.
- Successful link recovery and failure-to-recover scenarios for the modelled subset.

## 5. Code and assertion coverage

Collect statement/branch/toggle/FSM coverage supported by the simulator. Assertion coverage must show required properties were enabled and exercised. For critical assertions, add checker-negative tests to validate detection. Do not equate assertion pass count with full assertion coverage.

## 6. Cross-coverage controls

- Define legal bins from the supported feature contract.
- Use `ignore_bins` only for combinations proven illegal or not part of the supported subset, and document the reason.
- Avoid exploding unhelpful Cartesian products; select crosses tied to protocol risks.
- Do not exclude a bin solely because it is difficult to hit.
- Review uncovered bins and determine whether the cause is missing stimulus, unreachable behavior, a design defect, an overbroad bin, or a justified exclusion.

## 7. Goals

Target at least 95% of applicable functional coverage, above 95% statement, above 90% branch and toggle, and 100% of defined legal FSM states/transitions. These are goals, not guarantees. Any exclusions or shortfalls must be reported; metrics must come from actual simulation databases.


## Implemented UVM coverage boundary

The current UVM coverage subscriber samples observed packet-level transactions and covers operation, response status, byte-enable pattern, response stall, Tag subset, address region, and selected crosses. It does not currently sample the standalone TLP codecs, Data Link replay controller, Tag tracker, or credit manager. Their standalone smoke tests are directed checks, not functional coverage closure. Add transaction-level analysis ports/coverage models before treating Data Link or requester coverage as closed.


## Supported-subset closure boundary (v7)

The UVM subscriber samples completed transactions observed on the abstract endpoint interface. Bins cover the four packet-level operations, four modeled completion statuses, byte-enable classes, response-stall duration, Tag ranges, configuration/BAR0/outside address regions, requester-ID class, and selected operation/status/address/stall crosses. These are closure targets for the bounded endpoint, not PCIe-wide coverage.

The `pcie_boundary_seq` directed sequence targets first/interior/last BAR0 DWORDs, read-after-write, sparse and zero byte enables, response stalls, and the first DWORD beyond BAR0. Existing sequences target configuration readback and BAR sizing probe, byte enables, unsupported accesses, backpressure, reset, and constrained-random memory traffic.

Standalone codec, DLL/replay, Tag, credit, header-check, packet-buffer, and completion tracker/assembler blocks are not all sampled by this UVM covergroup. Their self-checking tests must be tracked separately. The v7 coverage model defines intended bins; actual coverage percentages require simulator-generated coverage data.

## Coverage execution and closure workflow

Use `vsim -c -do scripts/run_coverage_regression.do` to run the combined packet-level coverage regression. It runs smoke, configuration, byte-enable, error, backpressure, boundary, mixed-operation, and constrained-random sequences in one simulation so the endpoint covergroup can accumulate across these scenarios. The script requests a coverage report and saves `sim/coverage/pcie_coverage_regression.ucdb` when supported by the installed Questa setup.

Run `vsim -c -do scripts/run_reset.do` separately because reset deliberately clears DUT state and the scoreboard reference model. Run standalone block tests separately; the endpoint subscriber does not sample internal activity in those modules.

Coverage is considered closed only for the documented implemented subset when the regression has no scoreboard mismatches, UVM errors/fatals, assertion failures, and the actual simulator report shows all applicable bins hit or individually justified exclusions. Do not substitute a covergroup percentage, a sequence being present, or a successful process exit for this review. Statement/branch/toggle/FSM coverage and assertion coverage must be collected separately using the simulator's supported options.
