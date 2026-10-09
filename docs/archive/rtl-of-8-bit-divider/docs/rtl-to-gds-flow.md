# RTL-to-GDS Flow

This document shows which stages of the ASIC flow are backed by evidence in this repository, and records the tool settings visible in that evidence.

![Implementation flow and evidence status](../assets/rtl-to-gds-flow.svg)

| Stage | Tool | Status in this repository | Evidence |
| ----- | ---- | ------------------------- | -------- |
| RTL design | Verilog | Performed, source **not included** | Module names in Genus/LEC reports |
| Timing constraints | SDC | Performed, file **not included** | Values in Genus timing reports |
| Logic synthesis | Cadence Genus 21.14 | **Evidenced** (3 runs) | [`reports/synthesis/`](../reports/synthesis/) |
| Low-power synthesis (clock gating) | Cadence Genus | **Evidenced** | `reports/synthesis/02_clock_gating/` |
| Physical-aware synthesis (PLE) | Cadence Genus | **Evidenced** | `reports/synthesis/03_ple/` |
| Gate-level simulation with SDF | Cadence Xcelium (`xrun`), SimVision | **Evidenced** | [`tb/`](../tb/), [`scripts/gls/`](../scripts/gls/), `assets/gls-*.png` |
| Logical equivalence check | Cadence Conformal LEC | **Evidenced** | [`scripts/lec/`](../scripts/lec/), [`reports/verification/`](../reports/verification/) |
| Floorplan, power plan, placement, CTS, routing | Cadence Innovus | Not available in the current repository | none |
| Signoff static timing analysis | Cadence Tempus | Not available in the current repository | none |
| Physical verification, GDS export | none | Not available in the current repository | none |

---

## 1. Synthesis (Cadence Genus)

### 1.1 Script

The Genus script (`genus_script_new.tcl`) is not in the repository. Part of it is visible in the synthesis screenshots. That **excerpt** follows. Lines cut off at the screenshot edge are marked `…`, and commented-out lines are kept because they show which options were available. It is not a runnable script.

```tcl
set_db init_lib_search_path ./lib/…
set_db init_hdl_search_path ./rtl…

read_libs {fast_vdd1v0_basicCells… fast_vdd1v2_basicCells_hvt.lib …}

read_hdl "divider1.v"
elaborate divider_registers_8bit
read_sdc ./constraints_file.sdc

#set_db lp_insert_clock_gating tru…
#set_db / .lp_insert_clock_gating …
#set_db tns_opto true
## Power root attributes
#set_db / .lp_clock_gating_prefix …
#set_db / .lp_power_analysis_effo…
#set_db / .lp_power_unit mW
#set_db / .lp_toggle_rate_unit /ns…
#set_db degin_power_effort high
#set_db / .leakage_power_effort me…

set_db syn_generic_effort medium
set_db syn_map_effort medium
set_db syn_opt_effort medium

syn_generic
syn_map
syn_opt

report_timing > ./report_timing.rpt
report_power  > ./report_power.rpt
report_area   > ./report_area.rpt
report_qor    > ./report_qor.rpt

write_hdl > ./i2c_netlist.v
write_sdc > ./i2c_sdc.sdc
write_sdf -timescale ns -nonegchec…
```

Notes:
- The screenshot shows the clock-gating attributes commented out. The second run reports one RC clock-gating instance, so clock gating was turned on for that run. The exact attribute setting used is not visible.
- The output netlist/SDC file names (`i2c_*`) appear to be left over from a script template. They are reproduced as shown.
- The PLE run used a separate script (`genus_ple_script.tcl`, not in the repository). Its reports show `Interconnect mode: spatial` and `Area mode: physical library`, which means Genus used physical (LEF-based) data to estimate wire load instead of a wireload model.

### 1.2 Libraries and operating point

- Multi-Vt standard-cell libraries. The visible file names include `fast_vdd1v0_basicCells…` and `fast_vdd1v2_basicCells_hvt.lib`, and the full list is cut off. Mapped cells in the timing reports include LVT variants (`DFFQXLLVT`, `NOR2X4LVT`, `OAI21XLLVT`, `MXI2X1LVT`) and standard-Vt cells (`INVX2`).
- Operating conditions: `PVT_1P1V_0C`.
- The technology node is not stated in any report, and this repository does not claim one.

### 1.3 Constraints (from the timing reports)

| Constraint | Value |
| ---------- | ----- |
| Clock | `clock`, period 650 ps |
| Clock source latency | 250 ps |
| Clock network latency | 250 ps, ideal |
| Setup uncertainty | 100 ps |
| Input delay | 500 ps (`constraints_file.sdc`, line 56) |

The lab report gives 650 ps as the clock period at which worst slack reaches 0 ps, and calls it "Tmax". As [results.md](results.md#12-timing-setup-650-ps-clock) shows, the limiting path is input-to-register:

```text
650 ps = 500 (input delay) + 37 (cell delay) + 13 (setup) + 100 (uncertainty)
```

So the minimum period reported here is set mostly by the SDC I/O budget, not by internal logic depth.

### 1.4 Results

| Run | Area | Total power | Worst slack | Cells |
| --- | ---: | ----------: | ----------: | ----: |
| Baseline | 300.960 | 228.343 µW | 0 ps | 99 |
| + Clock gating | 305.406 | 227.119 µW | 1 ps | 91 |
| PLE (spatial) | 335.698 | 240.109 µW | 3 ps | 106 |

Full breakdown and interpretation: [results.md](results.md#1-synthesis-divider_registers_8bit-cadence-genus-2114-s082_1).

---

## 2. Gate-level simulation

The netlist and SDF that Genus wrote for `eight_bit_divider` were simulated with Xcelium using SDF back-annotation (MAXIMUM corner). See [verification.md](verification.md#1-gate-level-simulation).

## 3. Logical equivalence checking

Conformal LEC compared Genus's `fv_map` netlist against the final netlist: 64/64 points equivalent, PASS. See [verification.md](verification.md#2-logical-equivalence-check).

## 4. Physical implementation (Innovus) and signoff STA (Tempus)

The project description says the divider was taken through Cadence Innovus and Tempus. **This repository has no scripts, logs, reports or screenshots from either tool**, so it makes no claims about floorplan, utilisation, CTS, routing, post-route timing, hold timing or layout.

To document these stages, add:

| Stage | Files to add | Where |
| ----- | ------------ | ----- |
| Innovus flow | Flow script, floorplan settings, `report_area`, `checkPlace`, CTS summary, `verify_drc`/`verify_connectivity` | `scripts/innovus/`, `reports/physical_design/` |
| Post-route timing | `timeDesign -postRoute` (setup and hold) summaries | `reports/physical_design/` |
| Tempus signoff | Script, `report_timing` (setup/hold), constraint/SDC used | `scripts/tempus/`, `reports/timing/` |
| Layout | Screenshot of the routed design from Innovus | `assets/layout.png` |

Then update the status table above, [`assets/rtl-to-gds-flow.svg`](../assets/rtl-to-gds-flow.svg) and [results.md](results.md).
