# =====================================================================
# GERAÇÃO DE NDM - IOCELLS IHP130 (lc_shell)
# =====================================================================
# Domínio de core 1.2V, I/O 3.3V (slow_1p08V_3p0V / typ_1p2V_3p3V / fast_1p32V_3p6V)
# Precisa do tech LEF da stdcell (o stack de metal é o mesmo chip).
# =====================================================================

set TECH_FILE "/home/gme/gustavo.platcheck/CI_EXPERT_II/iPDK/TSMC_digital_library/stclib/tcbn65gplus_200a/TSMCHOME/digital/Back_End/milkyway/tcbn65gplus_200a/techfiles/tsmcn65_9lmT2.tf"

#set STD_LEF_DIR "/home/gme/gustavo.platcheck/CI_EXPERT_II/iPDK/TSMC_digital_library/stclib/tcbn65gplus_200a/TSMCHOME/digital/Back_End/lef/tcbn65gplus_200a/lef"
#set TECH_LEF    "$STD_LEF_DIR/tcbn65gplus_9lmT2.lef"

set IO_LEF   "/home/gme/gustavo.platcheck/CI_EXPERT_II/iPDK/TSMC_digital_library/stclib/tphn65lpnv2od3_sl_200b/TSMCHOME/digital/Back_End/lef/tphn65lpnv2od3_sl_200b/mt_2/9lm/lef/tphn65lpnv2od3_sl_9lm.lef"

set DB_DIR   "/home/gme/gustavo.platcheck/CI_EXPERT_II/iPDK/TSMC_digital_library/stclib/tphn65lpnv2od3_sl_200b/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tphn65lpnv2od3_sl_200b"

# Atenção aos nomes: typ é "1p2V" (sem zero) e há campo de I/O (3p0V/3p3V/3p6V)
#compile_fusion_lib \
#    -dbs [glob ${DB_DIR}/*.db] \
#    -lefs [list $TECH_LEF $IO_LEF] \
#    -technology $TECH_FILE \
#    $LIB_NAME.ndm

set OUT_DIR "../libs"
set LOG_DIR "../libs/logs"
file mkdir $OUT_DIR
file mkdir $LOG_DIR

compile_fusion_lib \
    -dbs [glob ${DB_DIR}/*.db] \
    -lefs [list $IO_LEF] \
    -technology $TECH_FILE \
    -output_directory $OUT_DIR \
    -log_file_dir $LOG_DIR \
    -use_pg_pin \
    -check_options {-allow_missing_pg_pins -allow_missing_logical} \
    -force

	echo "=== NDM iocell gerado: ${LIB_NAME}.ndm ==="
