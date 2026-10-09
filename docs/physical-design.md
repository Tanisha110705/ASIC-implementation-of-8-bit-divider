# Physical Design (Cadence Innovus 21.15)

The captures in this document come from the author's ASIC Design Lab Task 4 ("Physical Design up to Routing"). The Innovus database path in the window titles is `asiclab/pd_final/DBS/…`. The Task-5 timing work ([timing-analysis.md](timing-analysis.md)) used a **separate** Innovus run (`asiclab/pd_divider`) with a slightly different die. Both runs implement `eight_bit_divider`.

## 1. MMMC setup — [`mmmc.tcl`](../physical-design/scripts/mmmc.tcl)

| Object | Definition |
| ------ | ---------- |
| Library set `max_timing` | `slow_vdd1v0_basicCells{,_hvt,_lvt}.lib`, `slow_vdd1v2_basicCells{,_hvt,_lvt}.lib` |
| Library set `min_timing` | the matching `fast_*` libraries |
| RC corner `rccorners` | cap table `cln28hpl_1p10m+alrdl_5x2yu2yz_typical.capTbl`, QRC tech `gpdk045.tch`, all scale factors 1 |
| Delay corners | `max_delay` (slow), `min_delay` (fast) |
| Constraint mode `sdc_cons` | `./divider_sdc.sdc` (written by Genus) |
| Analysis views | setup: `wc` (max_delay); hold: `bc` (min_delay) |

Note: the cap table file name refers to a 28 nm process (`cln28hpl`), while the QRC tech file, LEFs and libraries are 45 nm GPDK. The file is preserved as used. Post-route extraction relies on the QRC tech file.

## 2. Floorplan and power plan — [`floorplan_CUI.tcl`](../physical-design/scripts/floorplan_CUI.tcl)

- `create_floorplan -site CoreSite -core_density_size 1 0.6 8.0 8 8.0 8`: aspect ratio 1, target density 0.6, 8 µm core-to-boundary margins.
- Core rings on VDD/VSS: Metal11 top/bottom, Metal10 left/right, 1.8 µm wide, 0.5 µm spacing and offset.
- Metal10 vertical stripes, 1.8 µm wide, 18 µm set-to-set pitch.
- `connect_global_net` for VDD/VSS pins and tie-high/tie-low, then `route_special` for the follow-pin rails.
- `check_drc`, `write_db DBS/init.dat`.

Evidence: [floorplan layout](../physical-design/layout/01_floorplan.png). The [check_design capture](../physical-design/reports/floorplan/check_design_help.png) shows only the `check_design -help` usage text, not a design check result.

## 3. Placement — [`place_CUI.tcl`](../physical-design/scripts/place_CUI.tcl)

Settings: `design_process_node 45`, OCV analysis with CPPR, `opt_useful_skew true`, `opt_fix_fanout_load true`, I/O pins not moved. Then `place_opt_design`, tie-cell insertion (`TIEHI`/`TIELO`), `write_db DBS/place.dat`.

| Check | Result | Evidence |
| ----- | ------ | -------- |
| `check_place` | 304 placed, 0 unplaced; density 47.33 % (812/1715) | [capture](../physical-design/reports/place/check_place.png) |
| `time_design -pre_cts` setup (view `wc`) | WNS −0.206 ns, TNS −1.573 ns, 9 violating of 115 paths (all reg2reg); no DRV violations | [capture](../physical-design/reports/place/time_design_setup.png) |
| `time_design -pre_cts -hold` (view `bc`) | WNS −0.241 ns, TNS −21.588 ns, 115 violating of 115 | [capture](../physical-design/reports/place/time_design_hold.png) |

Pre-CTS timing uses ideal clocks, so the hold numbers here are expected to change after CTS.

## 4. Clock tree synthesis — [`cts_CUI.tcl`](../physical-design/scripts/cts_CUI.tcl)

- Non-default clock route rule `2w2s` (double width, double spacing), preferred layers Metal5–Metal6, shielded with VSS.
- CTS cells: `CLKBUFX4/8/12/16`, `CLKINVX4/8/12/16`, inverters enabled. Clock gates: `TLATNTSCA*`.
- `create_clock_tree_spec`, `ccopt_design`, `opt_design -post_cts`, then `opt_design -post_cts -hold`. Clock-tree and skew-group reports are written to `rclk_full.rpt` / `rskg_full.rpt` (not preserved).
- The script opens with `extract_rc` and `write_parasitics -spef_file divider.spef`. The uploaded copy said `i2c.spef`; it was corrected to `divider.spef` to match the Task-4 capture of the script that was run ([capture](../physical-design/reports/cts/cts_CUI_script_capture.png)). No other line differs.

| Stage | Setup (wc) | Hold (bc) | Density | Evidence |
| ----- | ---------- | --------- | ------: | -------- |
| Post-CTS, before opt | WNS +0.007 ns, 0 violating | WNS −0.101 ns, TNS −5.972 ns, 113 violating | 48.444 % | [setup](../physical-design/reports/cts/before_optimisation_time_design_setup.png), [hold](../physical-design/reports/cts/before_optimisation_time_design_hold.png) |
| `opt_design -post_cts` summary | WNS −0.000 ns, 1 violating (default group) | WNS −0.009 ns, TNS −0.015 ns, 3 violating | 61.767 % | [capture](../physical-design/reports/cts/optimisation.png) |
| Post-CTS, after opt (`time_design`) | WNS −0.000 ns, 1 violating | WNS −0.009 ns, 3 violating | 61.767 % | [setup](../physical-design/reports/cts/after_optimisation_time_design_setup.png), [hold](../physical-design/reports/cts/after_optimisation_time_design_hold.png) |

Clock tree: [Clock Tree Debugger view](../physical-design/reports/cts/clock_tree_synthesis.png) (insertion delays about 0.48–0.66 ns on the `max_delay` corner) and the [post-CTS layout](../physical-design/layout/02_post_cts.png).

## 5. Routing

[`route_CUI.tcl`](../physical-design/scripts/route_CUI.tcl), **recovered from the Task-4 lab report.** The uploaded `physical design/route/route_CUI.tcl` was byte-for-byte identical to `cts_CUI.tcl` (checked with `cmp`) and contained no routing commands. The real script appears, fully legible, in a gedit capture in the Task-4 report (page 9, `~/asiclab/pd_divider/route_CUI.tcl`, 14 Oct 13:21). It was transcribed line by line, including commented-out lines ([capture](../physical-design/reports/route/route_CUI_script_capture.png)).

- Signal-integrity-aware delay calculation on (`delaycal_enable_si true`).
- Multi-cut via effort high; antenna fixing with `ANTENNA` cells and diode insertion.
- Filler insertion is present but commented out, so the routed database has no filler cells.
- `route_design`, then post-route RC extraction at high effort, `write_db DBS/route.dat`.
- `time_design -post_route` (setup and hold), `opt_design -post_route -setup -hold`, `write_db DBS/postroute.dat`.
- `check_connectivity -type all`, `check_drc`.

| Stage | Setup (wc) | Hold (bc) | Density | Evidence |
| ----- | ---------- | --------- | ------: | -------- |
| Post-route, before opt (SI on for hold) | WNS −0.039 ns, TNS −0.170 ns, 8 violating | WNS −0.030 ns, TNS −0.439 ns, 26 violating | 61.767 % | [setup](../physical-design/reports/route/before_optimisation_time_design_setup.png), [hold](../physical-design/reports/route/before_optimisation_time_design_hold.png) |
| `opt_design` summary | WNS −0.006 ns, 5 violating | WNS −0.010 ns, 2 violating | 62.325 % | [capture](../physical-design/reports/route/optimisation.png) |
| Post-route, after opt (`time_design`) | WNS −0.044 ns, TNS −0.207 ns, 9 violating | WNS −0.030 ns, TNS −0.443 ns, 25 violating | 62.325 % | [setup](../physical-design/reports/route/after_optimisation_time_design_setup.png), [hold](../physical-design/reports/route/after_optimisation_time_design_hold.png) |
| `check_drc` | 0 violations (sub-area 0,0 – 59.600,55.670) | | | [capture](../physical-design/reports/route/check_drc.png) |
| `check_connectivity -type all` | 0 violations, 0 warnings; design boundary 59.6 × 55.67 µm | | | [capture](../physical-design/reports/route/check_connectivity.png) |

The `opt_design` summary is better than the `time_design` run after it. The `time_design` hold run shows SI analysis enabled; the optimiser's internal summary may use different settings. All setup violations are in the `default` (I/O) path group; reg2reg setup slack is positive (+0.052 ns). Hold violations include 8 reg2reg paths (WNS −0.010 ns) as well as 17 in the `default` group. **Timing was not closed in Innovus.** It was taken to Tempus for ECO-based closure.

Layout: [post-route](../physical-design/layout/03_post_route.png).

## 6. Final database (Task 5 run, `pd_divider`)

The database used for Tempus STA ([timing-analysis.md](timing-analysis.md)):

| Check | Result | Evidence |
| ----- | ------ | -------- |
| `check_drc` | 0 violations (sub-area 0,0 – 57.600,57.380) | [capture](../physical-design/reports/final_db/check_drc.png) |
| `check_connectivity` | 0 violations, 0 warnings; boundary 57.6 × 57.38 µm | [capture](../physical-design/reports/final_db/check_connectivity.png) |
| Layout | post-route view of `DBS/postroute.dat` | [capture](../physical-design/layout/04_post_route_final_db.png) |

The Task-5 report shows `check_drc` and `check_connectivity` with 0 violations again after the ECOs (22:03 on 7 Nov). Those two captures are in the lab report but not stored separately here.

## 7. What these checks do and do not cover

`check_drc` and `check_connectivity` are Innovus routing-level checks against LEF rules. They are **not** sign-off physical verification. No foundry-deck DRC, LVS, antenna, density/fill, IR-drop or electromigration results exist, and no GDSII was written.
