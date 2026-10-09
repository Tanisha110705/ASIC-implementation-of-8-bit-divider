# Archive (historical, superseded)

> **Do not use these files as the current documentation.** They are kept so that nothing from the earlier repositories is lost. The current, verified documentation is the [root README](../../README.md) and the pages in [`docs/`](../).

| Path | What it is |
| ---- | ---------- |
| [`rtl-of-8-bit-divider/`](rtl-of-8-bit-divider/) | Complete snapshot of `Tanisha110705/RTL-of-8-bit-Divider` at commit `103cc38` (all files, without `.git`). Internal links inside it still resolve, except in `fsm-divider-rtl/README.md`: that file is a duplicate of the snapshot's root README one folder too deep, and its links were already broken in the source repository. |
| [`original-destination-README.md`](original-destination-README.md) | The two-line README this repository had before consolidation (commit `c55a134`). |

## Why the snapshot is superseded

The snapshot was written **before** the RTL, SDC and Innovus/Tempus evidence were known. As a result:

- It says the RTL and SDC are "not available". Both are now in [`rtl/`](../../rtl/) and [`constraints/`](../../constraints/).
- It says Innovus and Tempus results are "not available". They are now documented in [physical-design.md](../physical-design.md) and [timing-analysis.md](../timing-analysis.md).
- It says there is "no evidence" for the 1 ns target. [`constraints/divider_1000ps.sdc`](../../constraints/divider_1000ps.sdc) and the 1000 ps Genus reports now confirm it.
- Its FSM page has no state names. The real states (`IDLE`, `DIVIDE`, `DONE`) are in [rtl-design.md](../rtl-design.md).

Its synthesis numbers describe the legacy module `divider_registers_8bit`, not `eight_bit_divider`. Its gate-level simulation and LEC numbers (9-edge latency, 47 ps / 125 ps, 64/64 EQ) agree with the current docs.

## Where its useful content went

| Snapshot file(s) | Merged into |
| ---------------- | ----------- |
| `tb/tb_eight_bit_divider.v`, `scripts/gls/run_gls`, `scripts/lec/divider_lec.do` | [`verification/gls/`](../../verification/gls/), [`verification/lec/`](../../verification/lec/) |
| `reports/synthesis/` | [`synthesis/reports/legacy_divider_registers_8bit/`](../../synthesis/reports/legacy_divider_registers_8bit/README.md) |
| `reports/verification/lec_*.png`, `assets/gls-*.png` | cropped duplicates of [`verification/lec/reports/`](../../verification/lec/reports/) and [`verification/gls/reports/`](../../verification/gls/reports/) |
| `assets/cycle-operation.svg` | [`assets/cycle-operation.svg`](../../assets/cycle-operation.svg) |
| `.gitignore` | root [`.gitignore`](../../.gitignore) |
| `README.md`, `docs/*.md` | rewritten into the root README and [`docs/`](../) |
| `assets/architecture.svg`, `rtl-to-gds-flow.svg`, `verification-flow.svg` | replaced by [`divider-architecture.svg`](../../assets/divider-architecture.svg) and [`rtl-to-gds-flow.svg`](../../assets/rtl-to-gds-flow.svg) |
