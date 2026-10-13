#set TECH_FILE "/home/mic63/ulisses.maffazioli/pdk/ihp/ihp.tf"
set TECH_FILE "/home/mic63/ulisses.maffazioli/pdk/ihp/ixc013g2ng_tech.tf"
set STD_LEF_DIR "/pdk/ihp/ihp130/ixc013g2ng_stdcell/lef"

# 1. cria workspace com o tech (como o professor fez)
create_workspace -technology $TECH_FILE ixc013g2ng_stdcell

# 2. adiciona o físico (LEF de células)
read_lef [list \
    $STD_LEF_DIR/ixc013g2ng_stdcell_v5p7.lef \
    $STD_LEF_DIR/ixc013g2ng_phys.lef]

# 3. adiciona o lógico (db slow/typ/fast 1.2V)
set DB_DIR "/pdk/ihp/ihp130/ixc013g2ng_stdcell/db"
read_db [glob ${DB_DIR}/ixc013g2ng_stdcell_{slow_1p08V,typ_1p20V,fast_1p32V}*.db]

# 4. check (aqui dá pra relaxar PG se precisar)
check_workspace

# 5. grava o NDM final em libs/
commit_workspace -output ../libs/ixc013g2ng_stdcell.ndm
