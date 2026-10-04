# CLAUDED
# Run one simulation suite from the generated project.
#   vivado -mode batch -source vivado/run_suite.tcl -tclargs <suite> [top_module]
# e.g. vivado -mode batch -source vivado/run_suite.tcl -tclargs synaptic_module tb_SM_g_accumulator
set script_dir [file dirname [file normalize [info script]]]
if {$argc < 1} { error "usage: -tclargs <suite> [top_module]" }
set suite [lindex $argv 0]

open_project [file join $script_dir project caravel_kria.xpr]
set fs [get_filesets sim_$suite]
if {$argc > 1} { set_property top [lindex $argv 1] $fs }
update_compile_order -fileset $fs
launch_simulation -simset $fs -mode behavioral
close_project