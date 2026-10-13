#set TECH_FILE "/home/mic63/ulisses.maffazioli/pdk/ihp/ihp.tf"
set TECH_FILE "/home/gme/gustavo.platcheck/CI_EXPERT_II/iPDK/TSMC_digital_library/stclib/tcbn65gplus_200a/TSMCHOME/digital/Back_End/milkyway/tcbn65gplus_200a/techfiles/tsmcn65_9lmT2.tf"

set STD_LEF_DIR "/home/gme/gustavo.platcheck/CI_EXPERT_II/iPDK/TSMC_digital_library/stclib/tcbn65gplus_200a/TSMCHOME/digital/Back_End/lef/tcbn65gplus_200a/lef"
#set IO_LEF_DIR  "/home/gme/gustavo.platcheck/CI_EXPERT_II/iPDK/TSMC_digital_library/stclib/tphn65lpnv2od3_sl_200b/TSMCHOME/digital/Back_End/lef/tphn65lpnv2od3_sl_200b/mt_2/9lm/lef"
# 1. cria workspace com o tech (como o professor fez)
create_workspace -technology $TECH_FILE tsmc65
# 2. adiciona o físico (tech LEF da stdcell + LEF de I/O)
#read_lef [list \
#    $STD_LEF_DIR/tcbn65gplus_9lmT2.lef.lef \
#    $IO_LEF_DIR/tphn65lpnv2od3_sl_9lm.lef]
read_lef $STD_LEF_DIR/tcbn65gplus_9lmT2.lef.lef
# 3. adiciona o lógico (db slow/typ/fast - core 1.2V / io 3.3V)
set DB_DIR "/home/gme/gustavo.platcheck/CI_EXPERT_II/iPDK/TSMC_digital_library/stclib/tcbn65gplus_200a/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcbn65gplus_200a"
read_db [glob ${DB_DIR}/*.db]
# 4. check (aqui dá pra relaxar PG se precisar)
check_workspace
# 5. grava o NDM final em libs/
commit_workspace -output ../libs/tcbn65gplus_200a.ndm
