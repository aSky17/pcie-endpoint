# PCI Express 4.0 Endpoint RTL and UVM Verification Project

**Status:** Working project plan --- intentionally adjustable as the
specification is studied  
**Specification baseline:** PCI Express Base Specification, Revision
4.0, Version 1.0 (2017-10-05), supplied as `PCIE_V4.0.pdf`  
**Primary goal:** Build a substantial PCIe Endpoint RTL design and a UVM
verification environment from scratch, using the specification alongside
implementation rather than reading the entire specification before
beginning.

---

## 1. Project goal

Develop a simulation-based PCIe Endpoint project that demonstrates
practical understanding of transaction processing, configuration, packet
integrity, link-level reliability, flow control, error handling, and
verification methodology.

The project should be challenging enough to discuss in entry-level RTL
design or design-verification interviews. It is not intended to be a
production PCIe IP core, a complete PCIe 4.0 implementation, or an
electrical PHY implementation.

### Final deliverables

1. Synthesizable SystemVerilog RTL for the agreed Endpoint
  functionality.
2. A documented packet-level interface to a **simplified PHY/link
  partner model**.
3. A UVM environment with sequencer, driver, monitor,
  scoreboard/reference model, agents, assertions, and functional
    coverage.
4. Directed, negative, constrained-random, concurrency, reset, and
  error-injection tests.
5. Regression scripts, reproducible simulator instructions, and useful
  logs.
6. A specification-to-implementation traceability matrix listing
  implemented, simplified, and deferred requirements.
7. Architecture diagrams, packet-format notes, design decisions, known
  limitations, and a final project report.



## 2. Scope and design boundaries



### In scope

- One PCIe Endpoint DUT.
- PCIe 4.0 as the reference specification.
- Transaction Layer Packet (TLP) creation, decoding, routing decisions
appropriate to an Endpoint, and request/completion handling.
- A minimal but meaningful configuration space and Base Address
Register (BAR) behavior.
- Memory Read and Memory Write transactions in the selected supported
forms.
- Completion generation and tracking of outstanding requests where
included in the agreed scope.
- Data Link Layer mechanisms added incrementally, including packet
sequence/integrity and reliable delivery behavior.
- Flow-control behavior for the implemented packet classes.
- Error detection and defined responses for selected invalid or
unsupported requests.
- UVM verification built alongside each RTL phase.



### Explicitly out of scope initially

- A production-grade PCIe Gen4 electrical PHY, analog front end,
SerDes, equalization, clock recovery, or board-level
signal-integrity implementation.
- Full compliance with every optional PCIe 4.0 feature.
- A complete PCIe switch, multi-function device, SR-IOV, Advanced
Error Reporting, ATS, PASID, IDE, or other advanced optional
features unless deliberately added later.
- Physical hardware bring-up or PCI-SIG compliance certification.
- Claiming that a simulation project is fully PCIe-compliant merely
because selected features pass tests.



### Key abstraction

Begin with a **packet-level interface** between the Endpoint protocol
logic and a simulated link partner. The interface will stand in for the
lower physical signaling functions while allowing protocol logic to be
exercised. The exact boundary, signals, packet representation, and
handshake must be documented before implementation. Do not assume that a
convenient internal packet bus is itself a standardized PCIe interface.

## 3. Working method: specification and implementation together

For each phase, follow this cycle:

1. **Read the relevant specification sections.** Read a manageable
  portion rather than trying to memorize the entire PDF.
2. **Extract requirements.** Record packet fields, state transitions,
  constraints, ordering rules, reset behavior, and error cases that
    apply to the planned feature.
3. **Classify each requirement.** Mark it as:
  - Implement in this project;
  - Implement in a simplified form, with the simplification
  documented;
  - Study but defer; or
  - Out of scope.
4. **Write a phase design note.** Define the supported subset,
  interfaces, assumptions, and expected behavior.
5. **Write tests before or alongside RTL.** Add test scenarios and
  scoreboard expectations before relying on a passing simulation.
6. **Implement RTL incrementally.** Keep modules small and run
  lint/compile checks often.
7. **Verify the phase.** Run directed and negative tests first, then
  constrained-random tests and assertions where appropriate.
8. **Review failures against the specification.** Do not alter the
  reference model simply to make the DUT pass; confirm which behavior
    the specification and agreed subset require.
9. **Close the phase.** Record test results, coverage, known gaps, and
  the next phase's dependencies.

The roadmap below is a starting plan, not a frozen feature list.
Finalize detailed feature choices only after reading the relevant
sections.

---



## 4. Provisional phase roadmap



## Phase 0 --- Project definition and simulation foundation

**Purpose:** Establish a clear target without committing prematurely to
every protocol feature.

**Study** - PCIe Base Specification Chapter 1: overview, terminology,
topology, software/hardware model, and layered architecture. - Review
the project-relevant sections of the specification's contents to
understand where configuration, TLPs, Data Link Layer, flow control, and
errors are defined.

**Design decisions** - Endpoint-only DUT for the first complete
implementation. - Packet-level lower-layer boundary and link-partner
model. - Clock/reset conventions and simulation timing. - Initial
supported TLP types and the exact completion behavior to target. -
Simulator and supported SystemVerilog/UVM version. - Coding, lint,
assertion, coverage, and regression conventions.

**Tasks** - Create repository structure, build/run scripts, compile
target, and basic testbench. - Define RTL hierarchy and module
ownership. - Define a specification/feature tracking table. - Create a
minimal smoke test and a reset test.

**Exit criteria** - Clean compile and repeatable simulation. - Reset
behavior is defined and tested. - Architecture and initial interfaces
are documented. - No PCIe packet behavior is claimed yet beyond what the
testbench intentionally models.

## Phase 1 --- Transaction Layer foundations and TLP representation

**Specification focus** - Chapter 2, especially §§2.1, 2.1.1, 2.1.2, and
2.2. - Read the relevant TLP packet-definition subsections as each
packet field is introduced.

**Learn** - Transaction Layer responsibilities. - Transaction types and
address spaces. - TLP header structure and format/type distinction. -
Header fields, payload presence, Length, byte enables,
requester/completer identifiers, tags, and attributes as relevant to the
selected packets. - The distinction between a request, a completion, and
a message.

**Implementation candidates** - Packet type/format definitions and typed
helper structures or packed representations. - Header encode/decode
functions or modules. - Packet legality checks for the supported
subset. - A packet-level input/output handshake. - A simple link-partner
traffic source in the testbench.

**Verification** - Header field encode/decode tests. - Legal and illegal
field combinations. - Zero-length and boundary-length cases where
relevant to the selected packet formats. - Back-to-back packet and
backpressure tests. - Assertions for handshake stability and packet
acceptance.

**Exit criteria** - Every supported packet field has a documented
meaning. - The monitor can reconstruct the packet observed at the DUT
boundary. - Directed tests cover the supported packet formats and
invalid combinations.

**Do not yet** - Implement the full Data Link Layer or a physical PHY. -
Implement every TLP type simply because it appears in the specification.

## Phase 2 --- Endpoint configuration space and BAR behavior

**Specification focus** - The relevant configuration-space,
configuration request, and BAR sections, including applicable material
in Chapter 7 and Chapter 2. - Confirm exact section numbers and
applicability from the supplied PDF before freezing the design.

**Learn** - Configuration Read/Write transactions. - Type 0
configuration space for an Endpoint. - Vendor ID, Device ID,
Command/Status, BARs, and the minimum capability/configuration behavior
required by the chosen subset. - BAR sizing and address decoding
behavior required by the implementation.

**Implementation candidates** - Minimal Endpoint configuration register
block. - Config Read response generation. - Config Write handling for
supported writable fields. - Read-only and reserved-field behavior. -
BAR sizing-mask behavior and BAR assignment assumptions. - BAR address
decode to an internal register or small memory-mapped register bank.

**Verification** - Read all implemented configuration registers. - Check
reset values and read-only fields. - Write legal and illegal values. -
Exercise BAR sizing and assigned-address decoding. - Test accesses to
unimplemented/reserved locations and misaligned or unsupported accesses
according to the documented subset.

**Exit criteria** - Configuration behavior is checked against a register
reference model. - BAR mapping is deterministic and documented. - Tests
cover reset values, access permissions, and address-decode boundaries.

## Phase 3 --- Memory Requests and Endpoint Completer behavior

**Specification focus** - Chapter 2 request packet rules, byte enables,
routing/addressing, and handling received TLPs. - Read the precise rules
for each supported Memory Read/Write form before implementation.

**Learn** - Memory Read Requests versus Memory Write Requests. - Posted
versus non-posted requests and why a Memory Read normally requires a
Completion. - Payload sizing, byte enables, alignment, and supported
request lengths. - Request validation and how the Endpoint should
respond to unsupported or malformed requests.

**Implementation candidates** - BAR-mapped memory/register access. -
Memory Write processing for the supported payload sizes. - Memory Read
processing and Completion with Data generation. - Byte-enable
handling. - Internal request validation and response selection. - A
small internal RAM/register model for deterministic tests.

**Verification** - Single-DW and multi-DW accesses where supported. -
Byte-enable patterns. - Address boundary and BAR boundary cases. -
Read-after-write consistency. - Invalid address, unsupported size,
malformed request, and unsupported transaction tests. - Independent
reference model for memory/register contents.

**Exit criteria** - The scoreboard predicts memory/register state and
expected completions. - No unexplained mismatches remain in directed
tests. - All supported request formats and documented error cases have
tests.

## Phase 4 --- Completion tracking, tags, and outstanding transactions

**Specification focus** - Transaction Descriptor/tag rules, Completion
rules, received-TLP handling, and relevant ordering requirements in
Chapter 2.

**Learn** - Requester ID and Tag roles. - How completions are matched to
outstanding requests. - Completion status, byte count, lower address,
and split-completion concepts applicable to the selected requests. -
Limits on outstanding requests and completion behavior.

**Implementation candidates** - Outstanding-request table for
Endpoint-originated requests if requester functionality is included in
this phase. - Tag allocation/reuse rules for the supported subset. -
Completion matching and unexpected/duplicate completion detection. -
Multiple outstanding requests with controlled concurrency.

**Verification** - Multiple outstanding requests. - Completions returned
in different permitted orders. - Unknown, duplicate, stale, or
mismatched tags. - Boundary conditions around tag availability and
reuse. - Completion status and partial/split completion cases only where
supported by the implementation.

**Exit criteria** - No request is incorrectly completed or silently lost
in the supported scenarios. - Scoreboard tracks outstanding requests
independently. - Assertions and coverage exercise allocation, matching,
retirement, and error cases.

**Scope checkpoint** - Decide whether the first complete DUT is strictly
a Completer or also implements Endpoint Requester behavior. A
Completer-only baseline is simpler; adding DMA/requester functionality
is a meaningful later extension.

## Phase 5 --- Transaction ordering and traffic interactions

**Specification focus** - Chapter 2 transaction ordering and applicable
rules in request/completion handling.

**Learn** - The ordering model and which transactions may pass or must
remain ordered. - Effects of attributes and traffic class only to the
extent supported. - How posted writes, non-posted requests, and
completions interact.

**Implementation candidates** - Only the ordering rules needed for the
selected transaction subset. - Queues or arbitration policy that
preserves required ordering. - Explicit documentation of unsupported
attributes and ordering cases.

**Verification** - Mixed read/write sequences. - Back-to-back
transactions to the same and different regions. - Concurrent requests
with randomized stalls. - Tests that distinguish required ordering from
ordering that is permitted to vary. - Scoreboard checks that do not
incorrectly demand one order where the specification allows multiple
outcomes.

**Exit criteria** - The reference model reflects the agreed ordering
rules. - Randomized traffic does not reveal ordering violations in the
supported subset. - Coverage tracks key transaction combinations and
stall/interleaving conditions.

## Phase 6 --- Data Link Layer reliability

**Specification focus** - Chapter 3 Data Link Layer, including packet
sequencing, integrity checking, acknowledgments, negative
acknowledgments, replay, and initialization as applicable.

**Learn** - TLP sequence numbers and LCRC. - ACK/NAK DLLPs and replay
behavior. - Reliable transfer across one Link. - Link-level state and
buffering needed for the selected subset.

**Implementation candidates** - Data Link Layer transmit/receive control
around the existing TLP logic. - Sequence number assignment and
checking. - LCRC generation/checking. - ACK/NAK handling and replay
buffer. - A controlled link-partner model capable of injecting
loss/corruption/ACK delays.

**Verification** - Normal successful transfer and ACK handling. - LCRC
corruption. - Sequence-number mismatch. - NAK and replay. - Delayed or
missing ACK behavior within the chosen model. - Replay-buffer boundaries
and reset during outstanding link traffic, according to the defined
subset.

**Exit criteria** - Link-level integrity and replay tests pass. - Fault
injection is deterministic and reproducible. - Data Link Layer state and
replay decisions are observable in logs and coverage.

## Phase 7 --- Flow control and buffering

**Specification focus** - Chapter 2 flow-control material and Chapter 3
flow-control initialization/update procedures. Confirm dependencies and
exact sections while reading.

**Learn** - Credit-based flow control. - Posted, non-posted, and
Completion buffer classes as applicable. - Header and data credits. -
Credit initialization, updates, consumption, and return. - Why flow
control is distinct from packet-level ready/valid backpressure in a
local RTL interface.

**Implementation candidates** - Credit accounting for the implemented
packet classes. - Transmit gating when credits are unavailable. -
Receive-buffer capacity and credit return/update behavior. - Simplified
partner credit model consistent with the selected subset.

**Verification** - No transmission when required credits are
exhausted. - Credit consumption and return accounting. - Burst traffic,
backpressure, and buffer boundary cases. - No underflow/overflow or
double-crediting. - Assertions for credit invariants.

**Exit criteria** - Credit accounting matches the reference model under
directed and randomized traffic. - Buffer/credit limits and unsupported
cases are documented. - Tests demonstrate both stalled and progressing
traffic.

## Phase 8 --- Error handling, integrity, timeout, reset, and recovery boundaries

**Specification focus** - Relevant Chapter 2 data-integrity,
completion-timeout, and link-status dependency sections. - Relevant
Chapter 3 error and recovery procedures.

**Learn** - Malformed and unsupported TLP handling. - Poisoned or
integrity-error cases to the extent included. - Completion timeout
behavior. - Reset and link-down implications for in-flight
transactions. - Distinguish protocol-defined behavior from behavior
intentionally simplified by this project.

**Implementation candidates** - Error/status tracking and defined
responses for supported invalid inputs. - Timeout mechanism for
Endpoint-originated requests if that feature is included. - Reset
cleanup of outstanding requests, queues, credits, and replay state. -
Observable error counters or status registers if useful.

**Verification** - Invalid packet fields and unsupported request
types. - Integrity error injection. - Missing completion and timeout. -
Reset during idle and active traffic. - Link-down or partner reset
scenarios supported by the model. - Check that no stale completion or
transaction state leaks after reset.

**Exit criteria** - Every implemented error path has an expected outcome
and a test. - Reset and error recovery invariants are asserted. - Known
deviations from the full specification are listed explicitly.

## Phase 9 --- Optional Endpoint Requester, DMA, and interrupts

**Purpose:** Add a substantial system-level feature after the core
Endpoint Completer path and protocol infrastructure are stable.

**Study** - Requester-originated Memory Read/Write rules. - Completion
handling and tag tracking. - Message/interrupt mechanisms applicable to
the selected design, including MSI/MSI-X only if deliberately scoped.

**Implementation candidates** - DMA engine that reads/writes a
simplified host-memory model. - Descriptor-driven or register-programmed
transfers. - Interrupt/message generation if included. - Backpressure
and error handling during DMA.

**Verification** - DMA transfer correctness and address boundaries. -
Multiple requests and completion ordering. - Partial/error completions
and timeout where supported. - Randomized host-memory latency. -
Interrupt generation and clearing if included.

**Exit criteria** - End-to-end data movement is verified against a
host-memory reference model. - DMA is clearly marked as a project
extension, not a requirement for every Endpoint. - No advanced
capability is added at the cost of leaving core protocol behavior
unverified.

## Phase 10 --- Integration, regression, and verification closure

**Tasks** - Run all phase tests together as a regression. - Separate
smoke, directed, negative, random, stress, and fault-injection suites. -
Add assertions for handshake stability, queue bounds, tag lifecycle,
credit invariants, and reset cleanup. - Close functional coverage
against the agreed feature list. - Add useful cross coverage for packet
type × payload form × byte enable × backpressure × error response where
meaningful. - Seed and log random tests for reproducibility. - Track
code coverage if the simulator supports it, but do not use code coverage
as a substitute for functional coverage. - Run lint and review
synthesizability of the intended RTL subset. - Document limitations,
assumptions, spec sections implemented, and tests proving each behavior.

**Final exit criteria** - A clean, repeatable regression. - No
unexplained failures. - Coverage goals defined and justified, with
uncovered items classified. - A requirements-to-tests traceability
matrix. - README with architecture, build instructions, test commands,
diagrams, and known limitations. - Final report explaining what was
implemented, how it was verified, and what remains outside scope.

---

