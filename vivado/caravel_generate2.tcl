# vivado tcl script that will generate a project in 
# the project folder with all of our junk in it 

set project_name "caravel_kria"
set part "xc7a100tcsg324-1"
set board "digilentinc.com:nexys-a7-100t:part0:1.2"
set rtl_dir "./rtl"
set constr_dir "./vivado/constraints/"
set constr_name "caravel_nexys"
set ip_dir "./vivado/ip"

create_project -force $project_name ./project -part $part
set_property BOARD_PART board [current_project]

import_ip [glob $ip_dir]

add_files [glob $src_dir/*.v]
add_files -fileset constrs_1 [glob $constr_dir/$constr_name.xdc]

update_compile_order -fileset sources_1