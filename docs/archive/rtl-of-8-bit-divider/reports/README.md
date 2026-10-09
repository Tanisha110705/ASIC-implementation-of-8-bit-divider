# reports/

Cropped screenshots of the original tool output. Window chrome (host names, user paths, session tabs) was cropped away, and the report content itself is unchanged. Values transcribed from these images, with interpretation, are in [docs/results.md](../docs/results.md).

## synthesis/: Cadence Genus 21.14, module `divider_registers_8bit`, 650 ps clock

| Run | Folder | What changed |
| --- | ------ | ------------ |
| Baseline | [`01_baseline/`](synthesis/01_baseline/) | Generic → map → opt at medium effort, no clock gating |
| Clock gating | [`02_clock_gating/`](synthesis/02_clock_gating/) | Clock-gating insertion enabled (1 ICG, 8 of 38 flops gated) |
| PLE | [`03_ple/`](synthesis/03_ple/) | Physical layout estimation (`Interconnect mode: spatial`, `Area mode: physical library`) |

Each folder holds the same five reports:

| File | Shows |
| ---- | ----- |
| `report_timing.png` | Worst setup path: launch/capture clock, latency, uncertainty, input delay, cell-by-cell arrival, slack |
| `report_area.png` | Cell count, cell area, net area, total area |
| `report_power.png` | Leakage / internal / switching power by category (register, logic, clock), in W |
| `report_qor.png` | Clock period, slack per cost group, instance counts, area (and power for runs 02 and 03) |
| `report_clock_gating.png` | Clock-gating summary: gated vs ungated flops and reasons |

## verification/: Cadence Conformal LEC, module `eight_bit_divider`

| File | Shows |
| ---- | ----- |
| [`lec_compare.png`](verification/lec_compare.png) | `add compared point -all` and `compare`: 64 points (17 PO + 47 DFF) equivalent; verification report sections 1–5 |
| [`lec_verification_report.png`](verification/lec_verification_report.png) | Remainder of `report verification -verbose`, ending in **Compare Results: PASS** (64 EQ, 0 non-EQ, 0 aborted, 0 uncompared) |
