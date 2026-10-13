set LIB_NAME  "tphn65lpnv2od3_slbc"
set TECH_FILE "/home/gme/gustavo.platcheck/CI_EXPERT_II/iPDK/TSMC_digital_library/stclib/tcbn65gplus_200a/TSMCHOME/digital/Back_End/milkyway/tcbn65gplus_200a/techfiles/tsmcn65_9lmT2.tf"
set IO_LEF    "/home/gme/gustavo.platcheck/CI_EXPERT_II/iPDK/TSMC_digital_library/stclib/tphn65lpnv2od3_sl_200b/TSMCHOME/digital/Back_End/lef/tphn65lpnv2od3_sl_200b/mt_2/9lm/lef/tphn65lpnv2od3_sl_9lm.lef"
set DB_DIR    "/home/gme/gustavo.platcheck/CI_EXPERT_II/iPDK/TSMC_digital_library/stclib/tphn65lpnv2od3_sl_200b/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tphn65lpnv2od3_sl_200b"

set OUT_DIR   "../libs"
set LOG_DIR   "../libs/logs"
set FRAME_NDM "${OUT_DIR}/${LIB_NAME}_frame.ndm"

file mkdir $OUT_DIR
file mkdir $LOG_DIR
file delete -force $FRAME_NDM "${OUT_DIR}/${LIB_NAME}.ndm"

# 1. Cria a biblioteca física no formato nativo
create_physical_lib -technology $TECH_FILE $LIB_NAME

# 2. Carrega a geometria física dos pads do LEF
read_lef $IO_LEF

# 3. Extrai/Gera as views de FRAM a partir das geometrias carregadas
create_frame

# 4. Salva a biblioteca de FRAM
write_physical_lib -output $FRAME_NDM -force

# 5. Vincula os FRAMs gerados com os arquivos .db de timing
compile_fusion_lib \
    -dbs [glob -nocomplain ${DB_DIR}/tphn65lpnv2od3_slbc.db] \
    -frames [list $FRAME_NDM] \
    -output_directory $OUT_DIR \
    -log_file_dir $LOG_DIR \
    -force
