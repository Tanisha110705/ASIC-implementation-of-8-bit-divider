#read_db DBS/init.dat
connect_global_net VDD -type pg_pin -pin VDD -inst *
connect_global_net VSS -type pg_pin -pin VSS -inst *
connect_global_net VDD -type tie_hi 
connect_global_net VSS -type tie_lo 
connect_global_net VDD -type tie_hi -pin VDD -inst *
connect_global_net VSS -type tie_lo -pin VSS -inst *


set_db design_process_node 45
set_db timing_analysis_type ocv
set_db timing_analysis_cppr both

set_db place_global_place_io_pins false
set_db opt_useful_skew true
set_db opt_fix_fanout_load true


place_opt_design


get_db base_cells TIE* 
set_db add_tieoffs_cells {TIELO TIEHI}



set_db [get_db base_cells TIE*] .dont_use false
add_tieoffs
set_db [get_db base_cells TIE*] .dont_use true

write_db DBS/place.dat

report_timing

set_db timing_analysis_check_type hold

report_timing -check_type hold
