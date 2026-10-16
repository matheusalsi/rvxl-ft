# proj paths
#   _setup/ -> flow/tsmc65/ (FLOW_ROOT) -> flow/ -> repo root (PRJ_ROOT)
set SCRIPT_DIR      [file dirname [file normalize [info script]]]
set FLOW_ROOT_SETUP [file dirname $SCRIPT_DIR]
set PRJ_ROOT_SETUP  [file dirname [file dirname $FLOW_ROOT_SETUP]]

# RTL sources read by synthesis (each dir is scanned for *.v; first dir is also the include dir)
set RTL_DIRS_SETUP [list \
    $PRJ_ROOT_SETUP/rtl/rvx \
    $PRJ_ROOT_SETUP/rtl/pads/tsmc65 \
]

# library dir & path
set PDK_PATH_SETUP            "/pdk/tsmc/TSMC65_u105206/stdlib_u105206"
set STD_LIB_PATH_SETUP        $PDK_PATH_SETUP/tcbn65gplus_200a/TSMCHOME/digital
set IO_LIB_PATH_SETUP         $PDK_PATH_SETUP/tphn65lpnv2od3_sl_200b/TSMCHOME/digital
set STD_VERILOG_PATH_SETUP    $STD_LIB_PATH_SETUP/Front_End/verilog/tcbn65gplus_200a/tcbn65gplus.v
