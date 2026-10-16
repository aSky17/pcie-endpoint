# Verification Plan

## Principles
- Monitor observed DUT-boundary traffic; do not rely only on driver intent.
- Keep the reference model independent of RTL implementation details.
- Start with directed tests, then negative tests, then constrained-random tests.
- Use assertions for invariants and scoreboards for end-to-end correctness.
- Record random seeds and make failures reproducible.
- Track implemented, simplified, deferred, and out-of-scope features separately.

## Initial milestones
1. Simulator smoke test.
2. Reset and interface smoke test.
3. Supported packet-format tests after Phase 1 spec study.
4. Configuration/BAR tests after Phase 2 spec study.
5. Memory request/completion tests after Phase 3 spec study.
