# ASIC Design Lab Reports (original submissions)

These are the author's original course submissions for BEVD301P ASIC Design Lab (Fall Semester 2025-26). They are the primary record of the Cadence runs whose screenshots appear throughout this repository. They are committed unchanged and are summarised here. Where a report's wording differs from what its own screenshots show, the docs follow the screenshots; the notes below point out each case.

| Report | Task | Date | Design | Tools | Where its evidence lives in the repo |
| ------ | ---- | ---- | ------ | ----- | ------------------------------------ |
| [`task2_logic_synthesis.docx`](task2_logic_synthesis.docx) | Task 2: Logic Synthesis and Optimisation | 29 Aug 2025 | `divider_registers_8bit` (**legacy RTL**) | Genus | [`synthesis/reports/legacy_divider_registers_8bit/`](../../synthesis/reports/legacy_divider_registers_8bit/README.md) |
| [`task3_gls_lec.docx`](task3_gls_lec.docx) | Task 3: Gate Level Simulation and Logical Equivalence Check | 12 Sep 2025 | `eight_bit_divider` | Xcelium, SimVision, Conformal | [`verification/gls/`](../../verification/gls/), [`verification/lec/`](../../verification/lec/) |
| [`task4_physical_design.pdf`](task4_physical_design.pdf) | Task 4: Physical Design up to Routing | 14 Oct 2025 | `eight_bit_divider` | Innovus | [`physical-design/`](../../physical-design/) |
| [`task5_sta_rc_extraction.pdf`](task5_sta_rc_extraction.pdf) | Task 5: Physical Verification and RC Extraction | 7 Nov 2025 | `eight_bit_divider` | Innovus, Tempus | [`timing-analysis/`](../../timing-analysis/), [`physical-design/reports/final_db/`](../../physical-design/reports/final_db/) |

Task 1 (RTL design and functional simulation) is not among the uploaded reports. Its evidence is the RTL, testbench and simulation captures in [`rtl/`](../../rtl/) and [`verification/`](../../verification/).

---

## Task 2: Logic Synthesis and Optimisation

**Aim.** Synthesise and optimise an 8-bit unsigned divider in Genus: (1) find Tmin; (2) compare performance, area and power of the traditional flow before and after power optimisation; (3) compare the traditional flow with the PLE (physical layout estimation) flow after power optimisation.

**Reported results** (module `divider_registers_8bit`, 650 ps; "Tmax = 650 ps, the time at which slack = 0" before power optimisation):

| Flow | Leakage (µW) | Internal (µW) | Switching (µW) | Total (µW) | "Input" (ps) | "Output" (ps) | "Clock" (ps) | Area (µm²) |
| ---- | -----------: | ------------: | -------------: | ---------: | -----------: | ------------: | -----------: | ---------: |
| Traditional, before power opt. | 0.1407 | 195.268 | 32.934 | 228.343 | 0 | 10.6 | 0 | 300.96 |
| Traditional, after power opt. (clock gating) | 0.1288 | 195.111 | 31.878 | 227.119 | 0 | 9.5 | 0.8 | 305.406 |
| PLE, after power opt. | 0.1174 | 196.348 | 43.643 | 240.109 | 3.2 | 8.7 | 0 | 335.698 |

Notes:
- The "Input / Output / Clock (ps)" columns are Genus QoR **critical-path slacks per cost group**, not delays.
- This task used a different RTL module from the rest of the project. Its RTL (`divider1.v`) is not available, so these results are kept apart as a legacy study.

**Report's conclusion.** Power optimisation (clock gating) lowered total, leakage and switching power at a small area cost. PLE gave a more realistic, layout-aware estimate with higher power and area. The traditional optimised flow gives a good PPA balance, and PLE better predicts post-layout behaviour.

## Task 3: Gate Level Simulation and Logical Equivalence Check

**Aim.** (a) Simulate the synthesised gate-level netlist in the Cadence environment to confirm functional accuracy and measure clock-to-output delay. (b) Run a Conformal LEC between the pre- and post-synthesis designs.

**Reported results:**
- GLS testbench (transcribed into [`tb_eight_bit_divider_gls.v`](../../verification/gls/tb_eight_bit_divider_gls.v), with the fixes `End` → `end` and `.DUT` → `.dut`), `run_gls` command, and waveforms for the six directed cases.
- Clock → `done` delay = 145,047 − 145,000 = **47 ps**. Clock → output delay = 145,125 − 145,000 = **125 ps**.
- LEC dofile and output: 64 compare points (17 PO + 47 DFF) equivalent, **PASS**.

Notes:
- The report's aim mentions "the 16-bit subtractor", which is a copy-paste slip; the run is on `eight_bit_divider`.
- It also describes the check as RTL vs netlist. The dofile actually compares Genus's `fv_map` intermediate netlist with the final netlist.

## Task 4: Physical Design up to Routing

**Aim.** Floorplan, place, run CTS on and route the 8-bit divider, with 0 errors and as few DRC violations as possible.

**Contents.** It has `mmmc_new.tcl` and the floorplan, placement, CTS and routing scripts, with `time_design` setup/hold before and after each optimisation, `opt_design` summaries, layout views, the clock-tree debugger, `check_drc` and `check_connectivity`. The per-step screenshots in [`physical-design/reports/`](../../physical-design/reports/) are crops of this report.

**Recovered from this report.** Page 9 has a fully legible capture of the real `route_CUI.tcl`. It was transcribed into [`physical-design/scripts/route_CUI.tcl`](../../physical-design/scripts/route_CUI.tcl), replacing an uploaded file that was a copy of the CTS script. Page 5 confirms that `cts_CUI.tcl` writes `divider.spef`.

**Reported results:** see [physical-design.md](../physical-design.md). In summary: placement density 47.33 %; post-route `check_drc` 0 and `check_connectivity` 0; post-route optimisation left setup WNS −0.044 ns and hold WNS −0.030 ns.

## Task 5: Physical Verification and RC Extraction

**Aim.** Run STA on the post-layout design with Innovus and Tempus: extract SPEF, apply SDC, analyse setup and hold, fix violations (buffer insertion, cell sizing, constraint refinement) and reach timing closure.

**Contents.** Post-route layout, `check_drc`, `check_connectivity`, RC extraction log, SPEF header, `tempus_script.tcl`, Tempus schematic, `report_analysis_coverage`, answers to the lab questions, and two ECO iterations (`tempuszero.tcl`, `tempuszero2.tcl`) with `place_eco` / `route_eco`.

**Answers given in the report:**

| Question | Answer |
| -------- | ------ |
| Was the SPEF complete? | Yes; SPEF generated and RC extraction completed |
| Were the constraints complete? | Yes |
| How many clocks? | One |
| Paths impacted by constants? | Some |
| Setup violations? | 0 |
| Worst timing in inputs or reg-reg? | Worst path `a_reg[1]/CK → q_reg[1]/D`, hold slack −0.013 |
| Single startpoint causing issues? | No |
| Worst setup / hold violation | none / −0.013 |
| Iterations | 33 hold-violating paths → ECO 1 → 14 → ECO 2 → 0 (by adding repeaters) |

**Report's conclusion.** Zero setup and hold violations were achieved after re-analysis.

**Note.** The final hold screenshot still shows WNS −0.013 ns and TNS −0.074 ns, with the same timestamp as the ECO-1 screenshot. The repository therefore treats hold closure as **not demonstrated**. See [timing-analysis.md](../timing-analysis.md#is-hold-closed).
