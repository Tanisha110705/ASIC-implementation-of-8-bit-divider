# Results

Every number in this repository is listed here with the file it comes from. If a value is not in this document, the repository has no evidence for it.

Two design names appear in the evidence:

| Module | Where it appears | Evidence in this repository |
| ------ | ---------------- | --------------------------- |
| `divider_registers_8bit` | Genus synthesis study (`elaborate divider_registers_8bit`, read from `divider1.v`) | Timing, area, power, QoR and clock-gating reports for three synthesis runs |
| `eight_bit_divider` | Gate-level simulation and Conformal LEC | GLS testbench, waveforms, LEC compare report |

Their flip-flop counts differ (38 vs 47), so they are **different netlists**. Numbers from one are never applied to the other below. The netlist used for GLS/LEC came from a Genus run whose reports are not in this repository.

---

## 1. Synthesis: `divider_registers_8bit` (Cadence Genus 21.14-s082_1)

Common conditions for all three runs (from report headers):

| Item | Value | Source |
| ---- | ----- | ------ |
| Tool | Genus(TM) Synthesis Solution 21.14-s082_1 | all report headers |
| Clock period | 650 ps (clock `clock`) | `report_qor.png` (all runs) |
| Operating conditions | `PVT_1P1V_0C` | all report headers |
| Input delay | 500 ps (`constraints_file.sdc`, line 56) | `01_baseline/report_timing.png` |
| Clock source latency / network latency | 250 ps / 250 ps (ideal) | `report_timing.png` (all runs) |
| Clock uncertainty (setup) | 100 ps | `report_timing.png` (all runs) |
| Effort | `syn_generic`, `syn_map`, `syn_opt` at medium effort | Genus script excerpt (see [rtl-to-gds-flow.md](rtl-to-gds-flow.md)) |

### 1.1 Area, cell count and power

| Metric | Baseline | + Clock gating | PLE (physical-aware) | Source |
| ------ | -------: | -------------: | -------------------: | ------ |
| Leaf cell count | 99 | 91 | 106 | `report_area.png`, `report_qor.png` |
| Sequential instances | 38 | 39 | 39 | `report_qor.png` |
| Combinational instances | 61 | 52 | 67 | `report_qor.png` |
| Cell area | 300.960 | 305.406 | 259.493 | `report_area.png` |
| Net area | 0.000 | 0.000 | 76.205 | `report_area.png` |
| **Total area** | **300.960** | **305.406** | **335.698** | `report_area.png` |
| Leakage power (µW) | 0.1407 | 0.1289 | 0.1174 | `report_power.png` |
| Internal power (µW) | 195.268 | 195.111 | 196.348 | `report_power.png` |
| Switching power (µW) | 32.934 | 31.879 | 43.644 | `report_power.png` |
| **Total power (µW)** | **228.343** | **227.119** | **240.109** | `report_power.png` |

Area is in the library's area unit. The author's lab report states it as µm². Power is converted from the reports' Watt values (for example, 2.28343e-04 W = 228.343 µW).

Report folders: [`reports/synthesis/01_baseline/`](../reports/synthesis/01_baseline/), [`02_clock_gating/`](../reports/synthesis/02_clock_gating/), [`03_ple/`](../reports/synthesis/03_ple/).

### 1.2 Timing (setup, 650 ps clock)

| Metric | Baseline | + Clock gating | PLE | Source |
| ------ | -------: | -------------: | --: | ------ |
| Worst path slack (`report_timing`) | 0 ps | 1 ps | 3 ps | `report_timing.png` |
| Worst path | `load` → `count_reg[3]/D` | `rst` → `A_reg[10]/D` | `load` → `Q_reg[0]/D` | `report_timing.png` |
| Data-path delay of worst path | 37 ps | 36 ps | 34 ps | `report_timing.png` |
| QoR slack: CLOCK group | 0.0 ps | 0.8 ps | no paths | `report_qor.png` |
| QoR slack: OUTPUTS group | 10.6 ps | 9.5 ps | 8.7 ps | `report_qor.png` |
| QoR slack: INPUTS group | (not a group) | (not a group) | 3.2 ps | `report_qor.png` |
| QoR slack: `cg_enable_group_clock` | (no ICG) | 1.0 ps | 8.4 ps | `report_qor.png` |
| TNS / violating paths | 0.0 / 0 | 0.0 / 0 | 0.0 / 0 | `report_qor.png` |
| Timing met at 650 ps | Yes (slack 0) | Yes | Yes | |

The author's lab report calls the 0 / 10.6 / 9.5 / 3.2 / 8.7 ps values "Performance (input/output/clock delay)". In the Genus QoR report they are **critical-path slack per cost group**, and this repository labels them that way.

**Budget breakdown of the worst baseline path** (all values from `01_baseline/report_timing.png`):

```text
clock period 650 ps = input delay 500 + data path 37 + setup 13 + uncertainty 100   → slack 0
```

Source and network latency (250 + 250 ps) appear on both launch and capture, so they cancel. The path that sets the 650 ps limit is an **input-to-register** path, and 500 ps of the budget is the SDC input delay. Only 37 ps is cell delay inside the design. The reports do not show register-to-register slack separately.

Equivalent frequency of the 650 ps constraint: 1 / 650 ps ≈ **1.54 GHz**. This is a synthesis constraint with zero or positive slack in Genus's pre-layout timing. It is not a post-layout or silicon result.

### 1.3 Clock gating

| Metric | Baseline | + Clock gating | PLE | Source |
| ------ | -------: | -------------: | --: | ------ |
| Clock-gating instances | 0 | 1 | 1 | `report_clock_gating.png` |
| Gated flip-flops | 0 / 38 | 8 / 38 (21.05 %) | 8 / 38 (21.05 %) | `report_clock_gating.png` |
| Average toggle saving | n/a | 25.00 % | 25.00 % | `report_clock_gating.png` |
| Ungated: "Enable not found" | 38 | 28 | 28 | `report_clock_gating.png` |
| Ungated: "Register bank width too small" | n/a | 2 | 2 | `report_clock_gating.png` |

### 1.4 Run-to-run comparison (derived)

| Change | Clock gating vs baseline | PLE vs clock gating |
| ------ | -----------------------: | ------------------: |
| Total power | −1.224 µW (−0.54 %) | +12.990 µW (+5.72 %) |
| Switching power | −1.056 µW (−3.21 %) | +11.765 µW (+36.91 %) |
| Leakage power | −8.43 % | −8.88 % |
| Total area | +4.446 (+1.48 %) | +30.292 (+9.92 %) |

How to read these:
- **Clock gating** placed one integrated clock-gating cell over 8 flip-flops. Total power fell by about 0.5 %. Area grew by about 1.5 % even though the leaf cell count dropped from 99 to 91. Gain is small because register internal power (about 172–180 µW) dominates and only 21 % of the flops could be gated.
- **PLE** (physical layout estimation, `Interconnect mode: spatial`, `Area mode: physical library`) replaces the zero-net-area wireload estimate with spatial net estimates. The 76.205 net-area term and the 37 % rise in switching power are mostly better wire modelling, not a worse design. Treat PLE as the more realistic pre-layout estimate. It is still not a post-route result.

---

## 2. Gate-level simulation: `eight_bit_divider`

Tool: Cadence Xcelium (`xrun`) with SimVision. The testbench clock period is 10 ns (`always #5 clk = ~clk`, `-timescale 1ns/10ps`). Waveform evidence is in [`assets/gls-waveform-overview.png`](../assets/gls-waveform-overview.png).

| Test | x (dividend) | y (divisor) | q observed | p observed | Expected q, r | Match |
| ---- | -----------: | ----------: | ---------: | ---------: | ------------: | :---: |
| 1 | 13 (0x0D) | 3 (0x03) | 0x04 = 4 | 0x01 = 1 | 4, 1 | ✔ |
| 2 | 100 (0x64) | 7 (0x07) | 0x0E = 14 | 0x02 = 2 | 14, 2 | ✔ |
| 3 | 50 (0x32) | 5 (0x05) | 0x0A = 10 | 0x00 = 0 | 10, 0 | ✔ |
| 4 | 200 (0xC8) | 15 (0x0F) | 0x0D = 13 | 0x05 = 5 | 13, 5 | ✔ |
| 5 | 77 (0x4D) | 1 (0x01) | 0x4D = 77 | 0x00 = 0 | 77, 0 | ✔ |
| 6 | 55 (0x37) | 0 (0x00) | 0x00 | 0x37 = 55 | undefined | see note |

Note on test 6: the netlist returns q = 0 and p = x for a zero divisor. The result appears on the clock edge that samples `start`, and `done` stays asserted. This is behaviour seen in the waveform; the RTL that implements it is not in the repository.

| Metric | Value | Source |
| ------ | ----- | ------ |
| Latency, `start` sampled → `done`/`q`/`p` valid | **9 rising clock edges** (55 ns → 145 ns; 165 ns → 255 ns) | `gls-waveform-overview.png`, cross-checked against total simulation time of 665 ns |
| Clock edge → `done` rise | 47 ps (145,047 ps − 145,000 ps) | [`gls-clk-to-done.png`](../assets/gls-clk-to-done.png) |
| Clock edge → `q`/`p` update | 125 ps (145,125 ps − 145,000 ps) | [`gls-clk-to-output.png`](../assets/gls-clk-to-output.png) |
| Total simulated time | 665,000 ps | SimVision time range |

The project description calls the divider an "8-cycle" design. The gate-level waveform shows 9 rising edges from the edge that samples `start` to the edge where `done` rises. The likely reading is 8 iteration cycles plus one cycle of load or result registration, but that split needs the RTL to confirm.

---

## 3. Logical equivalence check: `eight_bit_divider` (Cadence Conformal)

| Metric | Value | Source |
| ------ | ----- | ------ |
| Golden design | `fv/eight_bit_divider/fv_map.v.gz` (Genus intermediate netlist) | [`scripts/lec/divider_lec.do`](../scripts/lec/divider_lec.do) |
| Revised design | `divider_netlist.v` | `divider_lec.do` |
| Compare points | 64 = 17 primary outputs + 47 DFF | [`reports/verification/lec_compare.png`](../reports/verification/lec_compare.png) |
| Equivalent | 64 | `lec_compare.png` |
| Non-equivalent / aborted / not compared | 0 / 0 / 0 | `lec_verification_report.png` |
| Overall | **PASS** | [`lec_verification_report.png`](../reports/verification/lec_verification_report.png) |

The 17 primary outputs match the interface: `q[7:0]` (8) + `p[7:0]` (8) + `done` (1).

---

## 4. Not available in the current repository

| Metric | Status |
| ------ | ------ |
| RTL source (`eight_bit_divider`, `divider1.v`) | Not available in the current repository. |
| SDC file (`constraints_file.sdc`) | Not available. Only the values quoted in the timing reports are known. |
| 1 ns timing target | Not available in the current repository. The only clock constraint in evidence is 650 ps. |
| Synthesis reports for the `eight_bit_divider` netlist used in GLS/LEC | Not available in the current repository. |
| Hold timing | Not available in the current repository. |
| Floorplan, placement, CTS, routing, utilisation (Innovus) | Not available in the current repository. |
| Signoff STA, WNS/TNS, post-route slack (Tempus) | Not available in the current repository. |
| Post-layout power, IR drop, DRC/LVS | Not available in the current repository. |
| Layout / GDS image | Not available in the current repository. |
| Functional coverage | Not measured. |
