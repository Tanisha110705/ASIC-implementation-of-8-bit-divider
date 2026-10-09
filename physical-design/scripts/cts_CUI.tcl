
#read_db DBS/place.dat
extract_rc
write_parasitics -spef_file divider.spef -rc_corner rccorners

set_db route_design_detail_use_multi_cut_via_effort high

create_route_rule -width {Metal1 0.12 Metal2 0.14 Metal3 0.14 Metal4 0.14 Metal5 0.14 Metal6 0.14 Metal7 0.14 Metal8 0.14 Metal9 0.14 } \
		-spacing {Metal1 0.12 Metal2 0.14 Metal3 0.14 Metal4 0.14 Metal5 0.14 Metal6 0.14 Metal7 0.14 Metal8 0.14 Metal9 0.14 } -name 2w2s

create_route_type -name clkroute -route_rule 2w2s -bottom_preferred_layer Metal5 -top_preferred_layer Metal6 -shield_net VSS

set_db cts_route_type_top clkroute
set_db cts_route_type_trunk clkroute
set_db cts_route_type_leaf clkroute

get_db route_design_with_litho_driven

set_db opt_useful_skew_ccopt medium

set_db cts_buffer_cells "CLKBUFX12 CLKBUFX16 CLKBUFX4 CLKBUFX8"

set_db cts_inverter_cells "CLKINVX12 CLKINVX16 CLKINVX4 CLKINVX8" 

set_db cts_use_inverters true

set_db cts_clock_gating_cells TLATNTSCA*

create_clock_tree_spec -out_file ccopt_cui.spec

source  ccopt_cui.spec

ccopt_design

write_db DBS/cts.dat

time_design -post_cts
opt_design -post_cts

report_clock_trees -out_file ./rclk_full.rpt 
report_skew_groups -out_file ./rskg_full.rpt

report_timing -late
report_timing -early

set_db opt_fix_hold_allow_setup_tns_degradation false
set_db opt_fix_hold_ignore_path_groups default
opt_design -post_cts -hold -report_dir RPT -report_prefix postcts_hold

write_db DBS/postcts_hold.dat
