################################################################################
# Script: compile_io_mw_fixed.tcl
# Tool:   Library Compiler (lc_shell W-2024.09-SP2)
################################################################################

set LIB_NAME "tphn65lpnv2od3_sl"

# 1. Garante que o bin/ do Milkyway e do ICC fiquem no topo do PATH
set MW_BIN_DIR  "/tools/synopsys/mw/W-2024.09-SP2/bin"
set ICC_BIN_DIR "/tools/synopsys/icc/W-2024.09-SP2/bin"

# Cria symlink se Milkyway só existir dentro de linux64/
if {![file exists "${MW_BIN_DIR}/Milkyway"] && [file exists "${MW_BIN_DIR}/linux64/Milkyway"]} {
    catch {file link -symbolic "${MW_BIN_DIR}/Milkyway" "${MW_BIN_DIR}/linux64/Milkyway"}
}

set env(PATH) "${MW_BIN_DIR}:${ICC_BIN_DIR}:$env(PATH)"

# 2. Caminho EXATO da lib Milkyway (pasta que contém CEL, FRAM, lib, etc.)
set MW_LIB "/home/gme/gustavo.platcheck/CI_EXPERT_II/iPDK/TSMC_digital_library/stclib/tphn65lpnv2od3_sl_200b/TSMCHOME/digital/Back_End/milkyway/tphn65lpnv2od3_sl_200b/mt_2/9lm/cell_frame/tphn65lpnv2od3_sl"

set DB_DIR  "/home/gme/gustavo.platcheck/CI_EXPERT_II/iPDK/TSMC_digital_library/stclib/tphn65lpnv2od3_sl_200b/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tphn65lpnv2od3_sl_200b"
set OUT_DIR "../libs"
set LOG_DIR "../libs/logs"

file mkdir $OUT_DIR
file mkdir $LOG_DIR

# 3. Limpa compilacao anterior
file delete -force "${OUT_DIR}/${LIB_NAME}.ndm"

# Suprime aviso de PG pins
suppress_message LIBCHK-212

echo "=== Compilando NDM a partir da Milkyway ==="
echo "Milkyway Lib: $MW_LIB"
echo "DB Dir:       $DB_DIR"

# 4. Compilacao (SEM -technology para evitar o FLIB-21)
compile_fusion_lib \
    -dbs [glob -nocomplain ${DB_DIR}/*.db] \
    -mw_libs [list $MW_LIB] \
    -output_directory $OUT_DIR \
    -log_file_dir $LOG_DIR \
    -force

# 5. Verificacao
set FINAL_NDM "${OUT_DIR}/${LIB_NAME}.ndm"
if {[file exists $FINAL_NDM]} {
    echo "=========================================================="
    echo " SUCESSO: ${LIB_NAME}.ndm gerado com sucesso!"
    echo "=========================================================="
} else {
    echo "=========================================================="
    echo " ERRO: Falha na geracao. Verifique os logs em $LOG_DIR"
    echo "=========================================================="
}
