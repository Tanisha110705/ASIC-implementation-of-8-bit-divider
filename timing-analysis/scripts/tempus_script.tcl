set_db init_lib_search_path ./lib/timing

read_libs {fast_vdd1v0_basicCells_hvt.lib  slow_vdd1v0_basicCells_hvt.lib fast_vdd1v0_basicCells.lib      slow_vdd1v0_basicCells.lib fast_vdd1v0_basicCells_lvt.lib  slow_vdd1v0_basicCells_lvt.lib fast_vdd1v2_basicCells_hvt.lib  slow_vdd1v2_basicCells_hvt.lib fast_vdd1v2_basicCells.lib      slow_vdd1v2_basicCells.lib fast_vdd1v2_basicCells_lvt.lib  slow_vdd1v2_basicCells_lvt.lib }

read_physical -lef {./lib/lef/gsclib045_tech.lef ./lib/lef/gsclib045_hvt_macro.lef ./lib/lef/gsclib045_macro.lef ./lib/lef/gsclib045_lvt_macro.lef}

read_netlist ./divider_netlist.v
init_design

read_def ./divider_def.def

read_sdc ./divider_sdc.sdc
read_spef ./divider_spef.spef

set_db timing_analysis_type ocv
set_db timing_analysis_cppr both

################################
# Turn on SI
################################
set_db delaycal_enable_si false
set_db si_glitch_enable_report true 
set_db si_delay_separate_on_data true
set_db si_delay_enable_double_clocking_check true
set_db si_delay_enable_report true


###################################
# Run timing
###################################
update_timing -full


set_multi_cpu_usage -remote_host 1 -cpu_per_remote_host 16 
set_db opt_hold_target_slack 0
opt_signoff -hold

###################################
# Run reports
###################################
report_timing -split_delay -fields {instance cell arc transition load delay incr_delay }

report_noise -txtfile ./reports/glitch.txt

#check_design -type all -out_file design.rpt

report_annotated_parasitics 
report_analysis_coverage 
report_clocks 
report_case_analysis 
report_inactive_arcs 
report_constraint -all_violators 
report_analysis_summary 
report_timing -late -max_paths 1 -nworst 1 
report_timing -early -max_paths 1 -nworst 1



###################################
# Run a whole list of common reports
###################################
file mkdir reports
source ./reports.tcl










