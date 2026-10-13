# =====================================================================
# GERAÇÃO DE NDM - STDCELLS IHP130 (lc_shell)
# =====================================================================
# Domínio de core 1.2V (slow_1p08V / typ_1p20V / fast_1p32V)
# Usando os .db da pasta CPF, que trazem os pg_pins lógicos
# (resolve o LIBCHK-212 'missing logical pg_pins' do db/ plano).
# =====================================================================

# .tf gerado por nós (área local, não é do PDK oficial)
set TECH_FILE "/home/gme/gustavo.platcheck/CI_EXPERT_II/iPDK/TSMC_digital_library/stclib/tcbn65gpluslvt_200a/TSMCHOME/digital/Back_End/milkyway/tcbn65gpluslvt_200a/techfiles/tsmcn65_9lmT2.tf"

set STD_LEF_DIR "/home/gme/gustavo.platcheck/CI_EXPERT_II/iPDK/TSMC_digital_library/stclib/tcbn65gpluslvt_200a/TSMCHOME/digital/Back_End/lef/tcbn65gpluslvt_200a/lef"
set TECH_LEF    "$STD_LEF_DIR/tcbn65gpluslvt_9lmT2.lef"
set CELL_LEF    "$STD_LEF_DIR/tcbn65gpluslvt_9lmT2.lef"
set PHYS_LEF    "$STD_LEF_DIR/tcbn65gpluslvt_9lmT2.lef"

# CPF: db com pg_pins (nome tem _CPF_ no meio)
set DB_DIR   "/home/gme/gustavo.platcheck/CI_EXPERT_II/iPDK/TSMC_digital_library/stclib/tcbn65gpluslvt_200a/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcbn65gpluslvt_200a"

set OUT_DIR "../libs"
set LOG_DIR "../libs/logs"
file mkdir $OUT_DIR
file mkdir $LOG_DIR

compile_fusion_lib \
    -dbs [glob ${DB_DIR}/*.db] \
    -lefs [list $TECH_LEF $CELL_LEF $PHYS_LEF] \
    -technology $TECH_FILE \
    -output_directory $OUT_DIR \
    -log_file_dir $LOG_DIR \
    -force

echo "=== compile_fusion_lib (stdcell CPF) finalizado. Ver $OUT_DIR ==="
