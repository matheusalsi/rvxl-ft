# =====================================================================
# SCRIPT DE GERAÇÃO DE NDM (PHYSICAL + TIMING) NO LC_SHELL
# =====================================================================
# 1. Definição dos caminhos baseados nos dados fornecidos
set DB_DIR    "/pdk/synopsys/saed32/SAED32_EDK/lib/stdcell_rvt/db_nldm"

# Nome da biblioteca NDM de saída que será gerada
#read_lib [glob ${DB_DIR}/{saed32rvt_ff*.lib,saed32rvt_ss*.lib,saed32rvt_tt*.lib}] 

#foreach lib_to_db [glob ${DB_DIR}/{saed32rvt_ff*.lib,saed32rvt_ss*.lib,saed32rvt_tt*.lib}] {
#read_lib $lib_to_db
#write_lib $lib_to_db -output ${lib_to_db}.db
#echo "=== NDM Gerado com sucesso: ${lib_to_db}.db ==="
#}
read_lib ../lib_db_exemplo/saed32rvt_tt1p05v25c.lib
write_lib saed32rvt_tt1p05v25c -output saed32rvt_tt1p05v25c.db -format db
#echo "=== db Gerado com sucesso ==="
#exit

