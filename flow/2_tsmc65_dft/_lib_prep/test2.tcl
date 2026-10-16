# Ensure environment PATH prioritizes the tool binary directories
set env(PATH) "/tools/synopsys/mw/W-2024.09-SP2/bin:/tools/synopsys/icc/W-2024.09-SP2/bin:$env(PATH)"

# 2. Paths
set LIB_NAME "tphn65lpnv2od3_sl"

# Milkyway container path (directory containing CEL, FRAM, lib, etc.)
set MW_LIB "/home/gme/gustavo.platcheck/CI_EXPERT_II/iPDK/TSMC_digital_library/stclib/tphn65lpnv2od3_sl_200b/TSMCHOME/digital/Back_End/milkyway/tphn65lpnv2od3_sl_200b/mt_2/9lm/cell_frame/tphn65lpnv2od3_sl"

set DB_DIR "/home/gme/gustavo.platcheck/CI_EXPERT_II/iPDK/TSMC_digital_library/stclib/tphn65lpnv2od3_sl_200b/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tphn65lpnv2od3_sl_200b"

set OUT_DIR "../libs"
set LOG_DIR "../libs/logs"

file mkdir $OUT_DIR
file mkdir $LOG_DIR

# 3. Clean prior runs
file delete -force "${OUT_DIR}/${LIB_NAME}.ndm"
file delete -force "${OUT_DIR}/${LIB_NAME}_physical_only.ndm"

# 4. Select DB files
# Option A: Glob all 42 DBs (may hit LIBCHK-309 PVT duplication)
# set DB_FILES [glob -nocomplain ${DB_DIR}/*.db]

# Option B: Select non-conflicting primary corners (recommended to prevent LIBCHK-309)
set DB_FILES [glob -nocomplain ${DB_DIR}/*.db]
if {[llength $DB_FILES] == 0} {
    # Fallback to all DBs if specific pattern is not matched
    set DB_FILES [glob -nocomplain ${DB_DIR}/*.db]
}

echo "=== Compiling Fusion Library with Milkyway + DBs ==="
echo "Milkyway Lib: $MW_LIB"
echo "Found [llength $DB_FILES] DB file(s)"

# 5. Compile Fusion Library
# Note: -technology is omitted because technology data is read from the Milkyway container
compile_fusion_lib \
    -dbs $DB_FILES \
    -mw_libs [list $MW_LIB] \
    -output_directory $OUT_DIR \
    -log_file_dir $LOG_DIR \
    -force

# 6. Verification
set CREATED_NDMS [glob -nocomplain ${OUT_DIR}/*${LIB_NAME}*.ndm]

if {[llength $CREATED_NDMS] > 0} {
    echo "=========================================================="
    echo " SUCCESS: Generated NDM library:"
    foreach ndm $CREATED_NDMS {
        echo "   -> $ndm"
    }
    echo "=========================================================="
} else {
    echo "=========================================================="
    echo " ERROR: Compilation failed. Inspect logs in: $LOG_DIR"
    echo "=========================================================="
}
