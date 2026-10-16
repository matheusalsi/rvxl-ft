set_messages -log out_data/santiago_atpg.log -replace -level expert

read_netlist $STD_VERILOG_PATH_SETUP
read_netlist inp_data/santiago_cpu.v

run_build_model top_santiago_cpu

run_drc ./inp_data/santiago_cpu.spf

add_faults -all
run_atpg -auto

set_faults -fault_coverage
set_faults -atpg_effectiveness

write_patterns ./out_data/santiago_pats.stil -format stil -replace
write_faults   ./out_data/santiago.faults -all -replace

report_faults -all                                              > ./out_data/faults_all.rpt
report_patterns -all -internal                                  > ./out_data/patterns.rpt
report_summaries faults patterns primitives sequential_depths   > ./out_data/summaries.rpt
report_faults -all -collapsed -verbose                          > ./out_data/faults_collapsed.rpt
report_faults -summary -collapsed                               > ./out_data/faults_summary.rpt
report_faults -class UD -uncollapsed                            > ./out_data/faults_UD.rpt
