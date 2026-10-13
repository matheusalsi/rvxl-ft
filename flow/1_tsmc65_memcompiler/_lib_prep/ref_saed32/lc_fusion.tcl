# =====================================================================
# SCRIPT DE GERAÇÃO DE NDM (PHYSICAL + TIMING) NO LC_SHELL
# =====================================================================
# 1. Definição dos caminhos baseados nos dados fornecidos
set TECH_FILE "/pdk/synopsys/saed32/SAED32_EDK/tech/tf/saed32nm_1p9m.tf"
set LEF_FILE  "/pdk/synopsys/saed32/SAED32_EDK/lib/stdcell_rvt/lef/saed32nm_rvt_1p9m.lef"
set DB_DIR    "/pdk/synopsys/saed32/SAED32_EDK/lib/stdcell_rvt/db_nldm"

# Nome da biblioteca NDM de saída que será gerada
set LIB_NAME  "saed32_rvt_output"

#create_fusion_lib -dbs [glob ${DB_DIR}/{saed32rvt_ff*.db,saed32rvt_ss*.db,saed32rvt_tt*.db}] -lefs ${LEF_FILE} -technology ${TECH_FILE} ${LIB_NAME}.ndm
compile_fusion_lib -dbs [glob ${DB_DIR}/saed32rvt_*.db] -lefs ${LEF_FILE} -technology ${TECH_FILE} 

#close_fusion_lib -save

echo "=== NDM Gerado com sucesso: ${LIB_NAME}.ndm ==="
#exit

