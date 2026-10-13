# =====================================================================
# SCRIPT DE GERAÇÃO DE NDM (PHYSICAL + TIMING) NO LC_SHELL
# =====================================================================
# 1. Definição dos caminhos baseados nos dados fornecidos
set TECH_FILE "/pdk/synopsys/saed32/SAED32_EDK/tech/tf/saed32nm_1p9m.tf"
set LEF_FILE  "/pdk/synopsys/saed32/SAED32_EDK/lib/stdcell_rvt/lef/saed32nm_rvt_1p9m.lef"
set DB_DIR    "/pdk/synopsys/saed32/SAED32_EDK/lib/stdcell_rvt/db_nldm"

# Nome da biblioteca NDM de saída que será gerada
set LIB_NAME  "saed32_rvt_frame"

# 2. Cria o workspace de biblioteca física com o arquivo de tecnologia (.tf)
create_physical_lib  -technology ${TECH_FILE}  ${LIB_NAME}

# 3. Lê as informações lógicas (.db) requisitadas
# O comando lê todos os arquivos correspondentes ao padrão saed32rvt_*
foreach db_file [glob ${DB_DIR}/saed32rvt_*.db] {
    echo "Lendo arquivo lógico de temporização: $db_file"
    read_db $db_file
}

# 4. Lê a estrutura física (LEF) mapeando-a diretamente para a extração do FRAME
read_lef ${LEF_FILE} 
create_frame

# 5. Faz o check final para garantir o casamento de pinos lógicos com formas físicas
foreach db_file [glob ${DB_DIR}/saed32rvt_*.db] {

check_library -logic_library_name $db_file
}
# 6. Consolida e exporta a biblioteca em formato .ndm
# O arquivo gerado estará pronto para uso no IC Compiler II ou Fusion Compiler
write_physical_lib -output ${LIB_NAME}.ndm

echo "=== NDM Gerado com sucesso: ${LIB_NAME}.ndm ==="
#exit

