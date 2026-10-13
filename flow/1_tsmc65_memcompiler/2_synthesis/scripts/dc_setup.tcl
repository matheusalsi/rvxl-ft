# library dir & path
set PRJ_ROOT            $PRJ_ROOT_SETUP
set FLOW_ROOT           $FLOW_ROOT_SETUP
set IO_LIB_PATH	        $IO_LIB_PATH_SETUP
set STD_LIB_PATH        $STD_LIB_PATH_SETUP
set RTL_DIRS            $RTL_DIRS_SETUP
set SOURCE_PATH         [lindex $RTL_DIRS 0]  ;# include dir (rvx_constants.vh)

# search path for all files
#set_app_var search_path [concat $search_path "." $STD_LIB_PATH $IO_LIB_PATH $SOURCE_PATH]
set_app_var search_path [concat $search_path "." /pdk/tsmc/TSMC65_u105206/stdlib_u105206/tcbn65gplus_200a/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcbn65gplus_200a /pdk/tsmc/TSMC65_u105206/stdlib_u105206/tphn65lpgv2od3_sl_210a/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tphn65lpgv2od3_sl_210a $SOURCE_PATH]

# library settings
set synthetic_library   "dw_foundation.sldb"
set target_library      /pdk/tsmc/TSMC65_u105206/stdlib_u105206/tcbn65gplus_200a/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcbn65gplus_200a/tcbn65gpluswc0d72.db	    ;#slow
set iopad_library	    /pdk/tsmc/TSMC65_u105206/stdlib_u105206/tphn65lpnv2od3_sl_200b/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tphn65lpnv2od3_sl_200b/tphn65lpnv2od3_slwc5.db 	;#slow

# set link_library        "* $target_library $synthetic_library $iopad_library"
set_app_var link_library  [concat "*" $target_library $synthetic_library $iopad_library] 

# min/max (BC-WC): each lib max (slow) gets its version min (fast)
set_min_library /pdk/tsmc/TSMC65_u105206/stdlib_u105206/tcbn65gplus_200a/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcbn65gplus_200a/tcbn65gpluswc0d72.db \
    -min_version /pdk/tsmc/TSMC65_u105206/stdlib_u105206/tcbn65gplus_200a/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcbn65gplus_200a/tcbn65gpluslt.db

set_min_library /pdk/tsmc/TSMC65_u105206/stdlib_u105206/tphn65lpnv2od3_sl_200b/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tphn65lpnv2od3_sl_200b/tphn65lpnv2od3_slwc5.db \
    -min_version /pdk/tsmc/TSMC65_u105206/stdlib_u105206/tphn65lpnv2od3_sl_200b/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tphn65lpnv2od3_sl_200b/tphn65lpnv2od3_sllt.db 

# design setting
set TOP_MODULE_NAME top_pad_rvx
set DESIGN rvx

#UM: Fix register autoremoval
#set_app_var compile_seqmap_propagate_constants false
set_app_var compile_seqmap_propagate_high_effort false

# output dir
set PRE_LAYOUT_DIR	$FLOW_ROOT/out_data/pre_layout
set REPORT_DIR  	$FLOW_ROOT/out_data/reports/syn

file mkdir $PRE_LAYOUT_DIR
file mkdir $REPORT_DIR
