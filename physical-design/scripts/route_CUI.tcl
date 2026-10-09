#read_db DBS/postcts_hold.dat

connect_global_net VDD -type tie_hi -pin VDD -inst *
connect_global_net VSS -type tie_lo -pin VSS -inst *

set_db delaycal_enable_si true

set_db route_design_detail_use_multi_cut_via_effort high
set_db route_design_antenna_cell_name ANTENNA
set_db route_design_antenna_diode_insertion true

# set_db route_design_with_litho_driven false

#set_db add_fillers_cells "FILL64 FILL32 FILL16 FILL8 FILL4 \ FILL2 FILL1"
#set_db add_fillers_prefix FILL

#addFiller
#add_fillers

#set_db route_design_detail_post_route_spread_wire false

#set_db delaycal_equivalent_waveform_model propagation
#set_db delaycal_ewm_type simulation

#eval_legacy {setNanoRouteMode -routeSelectedNetOnly false}

route_design

set_db extract_rc_engine post_route
set_db extract_rc_effort_level high

write_db DBS/route.dat

time_design -post_route
time_design -post_route -hold

opt_design -post_route -setup -hold

write_db DBS/postroute.dat

check_connectivity -type all

check_drc
