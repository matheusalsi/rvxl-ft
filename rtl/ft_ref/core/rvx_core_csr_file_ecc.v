// SPDX-License-Identifier: MIT
// Copyright (c) 2020-2026 RVX Project Contributors

`include "rvx_constants.vh"

module rvx_core_csr_file_ecc #(

    parameter [31:0] SPI_BOOT_IMAGE_ADDRESS = 32'h00000000

) (

    // Global signals
    input wire clock,
    input wire clock_enable,
    input wire reset_n,

    // From pipeline stage 1
    input wire [ 3:0] core_state_s1,
    input wire        ebreak_s1,
    input wire        ecall_s1,
    input wire [31:0] instruction_s1,
    input wire        illegal_instruction_s1,
    input wire        irq_external_s1,
    input wire [15:0] irq_fast_s1,
    input wire        irq_software_s1,
    input wire        irq_timer_s1,
    input wire [63:0] memory_mapped_timer_s1,
    input wire        misaligned_instruction_address_s1,
    input wire        misaligned_load_s1,
    input wire        misaligned_store_s1,
    input wire [31:0] program_counter_s1,
    input wire        take_trap_s1,
    input wire [31:0] target_address_s1,

    // From pipeline stage 2
    input wire [11:0] csr_address_s2,
    input wire [ 2:0] csr_operation_s2,
    input wire        csr_write_request_s2,
    input wire [ 4:0] immediate_4_0_s2,
    input wire [31:0] rs1_data_s2,

    // Data output
    output reg [31:0] csr_data_out_s2,

    // Trap, exception and interrupt handling signals
    output wire [31:0] exception_address_s1,
    output wire        global_interrupt_enable_s1,
    output wire        interrupt_pending_s1,
    output wire [31:0] trap_handler_address_s1,
    
    // ECC Error Outputs (Max 20 simultaneous errors -> 5 bits)
    output wire [ 4:0] sb_err_o,
    output wire [ 4:0] db_err_o

);

  wire [31:0] interrupt_address_offset;
  wire        misaligned_address_exception;
  wire [31:0] csr_data_mask;

  wire [31:0] csr_mstatus;
  
  // --- ECC Width Localparams (n = m + K; ECC bits = n + 1) ---
  localparam W1_ECC  = 4;   // K=1  -> m=2, n=3
  localparam W5_ECC  = 10;  // K=5  -> m=4, n=9
  localparam W16_ECC = 22;  // K=16 -> m=5, n=21
  localparam W32_ECC = 39;  // K=32 -> m=6, n=38
  localparam W64_ECC = 72;  // K=64 -> m=7, n=71

  // --- Decoded Wires (Transparently replace original regs) ---
  wire        csr_mstatus_mie;
  wire        csr_mstatus_mpie;
  
  wire [31:0] csr_mie;
  wire [15:0] csr_mie_mfie;
  wire        csr_mie_meie;
  wire        csr_mie_msie;
  wire        csr_mie_mtie;
  
  wire [31:0] csr_mip;
  wire [15:0] csr_mip_mfip;
  wire        csr_mip_meip;
  wire        csr_mip_msip;
  wire        csr_mip_mtip;
  
  wire [31:0] csr_mepc;
  wire [31:0] csr_mtvec;
  wire [31:0] csr_mcause;
  wire [ 4:0] csr_mcause_code;
  wire        csr_mcause_interrupt_flag;
  wire [31:0] csr_mtval;
  wire [31:0] csr_mscratch;
  
  wire [63:0] csr_minstret;
  wire [63:0] csr_mcycle;
  wire [63:0] csr_utime;

  // --- Next-State logic registers (Unencoded) ---
  reg         csr_mstatus_mie_next;
  reg         csr_mstatus_mpie_next;
  reg  [15:0] csr_mie_mfie_next;
  reg         csr_mie_meie_next;
  reg         csr_mie_msie_next;
  reg         csr_mie_mtie_next;
  reg  [15:0] csr_mip_mfip_next;
  reg         csr_mip_meip_next;
  reg         csr_mip_msip_next;
  reg         csr_mip_mtip_next;
  reg  [31:0] csr_mepc_next;
  reg  [31:0] csr_mtvec_next;
  reg  [31:0] csr_mcause_next;
  reg  [ 4:0] csr_mcause_code_next;
  reg         csr_mcause_interrupt_flag_next;
  reg  [31:0] csr_mtval_next;
  reg  [31:0] csr_mscratch_next;
  reg  [63:0] csr_minstret_next;
  reg  [63:0] csr_mcycle_next;
  reg  [63:0] csr_utime_next;

  // --- Encoded Registers & Wires ---
  reg  [W1_ECC-1:0]  csr_mstatus_mie_ecc;
  wire [W1_ECC-1:0]  csr_mstatus_mie_next_ecc;
  reg  [W1_ECC-1:0]  csr_mstatus_mpie_ecc;
  wire [W1_ECC-1:0]  csr_mstatus_mpie_next_ecc;
  reg  [W16_ECC-1:0] csr_mie_mfie_ecc;
  wire [W16_ECC-1:0] csr_mie_mfie_next_ecc;
  reg  [W1_ECC-1:0]  csr_mie_meie_ecc;
  wire [W1_ECC-1:0]  csr_mie_meie_next_ecc;
  reg  [W1_ECC-1:0]  csr_mie_msie_ecc;
  wire [W1_ECC-1:0]  csr_mie_msie_next_ecc;
  reg  [W1_ECC-1:0]  csr_mie_mtie_ecc;
  wire [W1_ECC-1:0]  csr_mie_mtie_next_ecc;
  reg  [W16_ECC-1:0] csr_mip_mfip_ecc;
  wire [W16_ECC-1:0] csr_mip_mfip_next_ecc;
  reg  [W1_ECC-1:0]  csr_mip_meip_ecc;
  wire [W1_ECC-1:0]  csr_mip_meip_next_ecc;
  reg  [W1_ECC-1:0]  csr_mip_msip_ecc;
  wire [W1_ECC-1:0]  csr_mip_msip_next_ecc;
  reg  [W1_ECC-1:0]  csr_mip_mtip_ecc;
  wire [W1_ECC-1:0]  csr_mip_mtip_next_ecc;
  reg  [W32_ECC-1:0] csr_mepc_ecc;
  wire [W32_ECC-1:0] csr_mepc_next_ecc;
  reg  [W32_ECC-1:0] csr_mtvec_ecc;
  wire [W32_ECC-1:0] csr_mtvec_next_ecc;
  reg  [W32_ECC-1:0] csr_mcause_ecc;
  wire [W32_ECC-1:0] csr_mcause_next_ecc;
  reg  [W5_ECC-1:0]  csr_mcause_code_ecc;
  wire [W5_ECC-1:0]  csr_mcause_code_next_ecc;
  reg  [W1_ECC-1:0]  csr_mcause_interrupt_flag_ecc;
  wire [W1_ECC-1:0]  csr_mcause_interrupt_flag_next_ecc;
  reg  [W32_ECC-1:0] csr_mtval_ecc;
  wire [W32_ECC-1:0] csr_mtval_next_ecc;
  reg  [W32_ECC-1:0] csr_mscratch_ecc;
  wire [W32_ECC-1:0] csr_mscratch_next_ecc;
  reg  [W64_ECC-1:0] csr_minstret_ecc;
  wire [W64_ECC-1:0] csr_minstret_next_ecc;
  reg  [W64_ECC-1:0] csr_mcycle_ecc;
  wire [W64_ECC-1:0] csr_mcycle_next_ecc;
  reg  [W64_ECC-1:0] csr_utime_ecc;
  wire [W64_ECC-1:0] csr_utime_next_ecc;
  
  // Comb output logic
  reg  [31:0] csr_write_data;

  // --- Error Arrays and Outputs ---
  wire [19:0] sb_errs;
  wire [19:0] db_errs;

  assign sb_err_o = sb_errs[0] + sb_errs[1] + sb_errs[2]  + sb_errs[3]  + sb_errs[4]  +
                    sb_errs[5] + sb_errs[6] + sb_errs[7]  + sb_errs[8]  + sb_errs[9]  +
                    sb_errs[10]+ sb_errs[11]+ sb_errs[12] + sb_errs[13] + sb_errs[14] +
                    sb_errs[15]+ sb_errs[16]+ sb_errs[17] + sb_errs[18] + sb_errs[19];

  assign db_err_o = db_errs[0] + db_errs[1] + db_errs[2]  + db_errs[3]  + db_errs[4]  +
                    db_errs[5] + db_errs[6] + db_errs[7]  + db_errs[8]  + db_errs[9]  +
                    db_errs[10]+ db_errs[11]+ db_errs[12] + db_errs[13] + db_errs[14] +
                    db_errs[15]+ db_errs[16]+ db_errs[17] + db_errs[18] + db_errs[19];

  // --- ECC Encoders & Decoders Instantiation ---

  // 1. csr_mstatus_mie
  ecc_dec #(.K(1)) dec_0 (.rst_ni(1'b1), .clk_i(1'b0), .clkena_i(1'b0), .d_i(csr_mstatus_mie_ecc), .q_o(csr_mstatus_mie), .sb_err_o(sb_errs[0]), .db_err_o(db_errs[0]), .syndrome_o(), .sb_fix_o());
  ecc_enc #(.K(1)) enc_0 (.d_i(csr_mstatus_mie_next), .q_o(csr_mstatus_mie_next_ecc), .p_o(), .p0_o());

  // 2. csr_mstatus_mpie
  ecc_dec #(.K(1)) dec_1 (.rst_ni(1'b1), .clk_i(1'b0), .clkena_i(1'b0), .d_i(csr_mstatus_mpie_ecc), .q_o(csr_mstatus_mpie), .sb_err_o(sb_errs[1]), .db_err_o(db_errs[1]), .syndrome_o(), .sb_fix_o());
  ecc_enc #(.K(1)) enc_1 (.d_i(csr_mstatus_mpie_next), .q_o(csr_mstatus_mpie_next_ecc), .p_o(), .p0_o());

  // 3. csr_mie_mfie
  ecc_dec #(.K(16)) dec_2 (.rst_ni(1'b1), .clk_i(1'b0), .clkena_i(1'b0), .d_i(csr_mie_mfie_ecc), .q_o(csr_mie_mfie), .sb_err_o(sb_errs[2]), .db_err_o(db_errs[2]), .syndrome_o(), .sb_fix_o());
  ecc_enc #(.K(16)) enc_2 (.d_i(csr_mie_mfie_next), .q_o(csr_mie_mfie_next_ecc), .p_o(), .p0_o());

  // 4. csr_mie_meie
  ecc_dec #(.K(1)) dec_3 (.rst_ni(1'b1), .clk_i(1'b0), .clkena_i(1'b0), .d_i(csr_mie_meie_ecc), .q_o(csr_mie_meie), .sb_err_o(sb_errs[3]), .db_err_o(db_errs[3]), .syndrome_o(), .sb_fix_o());
  ecc_enc #(.K(1)) enc_3 (.d_i(csr_mie_meie_next), .q_o(csr_mie_meie_next_ecc), .p_o(), .p0_o());

  // 5. csr_mie_msie
  ecc_dec #(.K(1)) dec_4 (.rst_ni(1'b1), .clk_i(1'b0), .clkena_i(1'b0), .d_i(csr_mie_msie_ecc), .q_o(csr_mie_msie), .sb_err_o(sb_errs[4]), .db_err_o(db_errs[4]), .syndrome_o(), .sb_fix_o());
  ecc_enc #(.K(1)) enc_4 (.d_i(csr_mie_msie_next), .q_o(csr_mie_msie_next_ecc), .p_o(), .p0_o());

  // 6. csr_mie_mtie
  ecc_dec #(.K(1)) dec_5 (.rst_ni(1'b1), .clk_i(1'b0), .clkena_i(1'b0), .d_i(csr_mie_mtie_ecc), .q_o(csr_mie_mtie), .sb_err_o(sb_errs[5]), .db_err_o(db_errs[5]), .syndrome_o(), .sb_fix_o());
  ecc_enc #(.K(1)) enc_5 (.d_i(csr_mie_mtie_next), .q_o(csr_mie_mtie_next_ecc), .p_o(), .p0_o());

  // 7. csr_mip_mfip
  ecc_dec #(.K(16)) dec_6 (.rst_ni(1'b1), .clk_i(1'b0), .clkena_i(1'b0), .d_i(csr_mip_mfip_ecc), .q_o(csr_mip_mfip), .sb_err_o(sb_errs[6]), .db_err_o(db_errs[6]), .syndrome_o(), .sb_fix_o());
  ecc_enc #(.K(16)) enc_6 (.d_i(csr_mip_mfip_next), .q_o(csr_mip_mfip_next_ecc), .p_o(), .p0_o());

  // 8. csr_mip_meip
  ecc_dec #(.K(1)) dec_7 (.rst_ni(1'b1), .clk_i(1'b0), .clkena_i(1'b0), .d_i(csr_mip_meip_ecc), .q_o(csr_mip_meip), .sb_err_o(sb_errs[7]), .db_err_o(db_errs[7]), .syndrome_o(), .sb_fix_o());
  ecc_enc #(.K(1)) enc_7 (.d_i(csr_mip_meip_next), .q_o(csr_mip_meip_next_ecc), .p_o(), .p0_o());

  // 9. csr_mip_msip
  ecc_dec #(.K(1)) dec_8 (.rst_ni(1'b1), .clk_i(1'b0), .clkena_i(1'b0), .d_i(csr_mip_msip_ecc), .q_o(csr_mip_msip), .sb_err_o(sb_errs[8]), .db_err_o(db_errs[8]), .syndrome_o(), .sb_fix_o());
  ecc_enc #(.K(1)) enc_8 (.d_i(csr_mip_msip_next), .q_o(csr_mip_msip_next_ecc), .p_o(), .p0_o());

  // 10. csr_mip_mtip
  ecc_dec #(.K(1)) dec_9 (.rst_ni(1'b1), .clk_i(1'b0), .clkena_i(1'b0), .d_i(csr_mip_mtip_ecc), .q_o(csr_mip_mtip), .sb_err_o(sb_errs[9]), .db_err_o(db_errs[9]), .syndrome_o(), .sb_fix_o());
  ecc_enc #(.K(1)) enc_9 (.d_i(csr_mip_mtip_next), .q_o(csr_mip_mtip_next_ecc), .p_o(), .p0_o());

  // 11. csr_mepc
  ecc_dec #(.K(32)) dec_10 (.rst_ni(1'b1), .clk_i(1'b0), .clkena_i(1'b0), .d_i(csr_mepc_ecc), .q_o(csr_mepc), .sb_err_o(sb_errs[10]), .db_err_o(db_errs[10]), .syndrome_o(), .sb_fix_o());
  ecc_enc #(.K(32)) enc_10 (.d_i(csr_mepc_next), .q_o(csr_mepc_next_ecc), .p_o(), .p0_o());

  // 12. csr_mtvec
  ecc_dec #(.K(32)) dec_11 (.rst_ni(1'b1), .clk_i(1'b0), .clkena_i(1'b0), .d_i(csr_mtvec_ecc), .q_o(csr_mtvec), .sb_err_o(sb_errs[11]), .db_err_o(db_errs[11]), .syndrome_o(), .sb_fix_o());
  ecc_enc #(.K(32)) enc_11 (.d_i(csr_mtvec_next), .q_o(csr_mtvec_next_ecc), .p_o(), .p0_o());

  // 13. csr_mcause
  ecc_dec #(.K(32)) dec_12 (.rst_ni(1'b1), .clk_i(1'b0), .clkena_i(1'b0), .d_i(csr_mcause_ecc), .q_o(csr_mcause), .sb_err_o(sb_errs[12]), .db_err_o(db_errs[12]), .syndrome_o(), .sb_fix_o());
  ecc_enc #(.K(32)) enc_12 (.d_i(csr_mcause_next), .q_o(csr_mcause_next_ecc), .p_o(), .p0_o());

  // 14. csr_mcause_code
  ecc_dec #(.K(5)) dec_13 (.rst_ni(1'b1), .clk_i(1'b0), .clkena_i(1'b0), .d_i(csr_mcause_code_ecc), .q_o(csr_mcause_code), .sb_err_o(sb_errs[13]), .db_err_o(db_errs[13]), .syndrome_o(), .sb_fix_o());
  ecc_enc #(.K(5)) enc_13 (.d_i(csr_mcause_code_next), .q_o(csr_mcause_code_next_ecc), .p_o(), .p0_o());

  // 15. csr_mcause_interrupt_flag
  ecc_dec #(.K(1)) dec_14 (.rst_ni(1'b1), .clk_i(1'b0), .clkena_i(1'b0), .d_i(csr_mcause_interrupt_flag_ecc), .q_o(csr_mcause_interrupt_flag), .sb_err_o(sb_errs[14]), .db_err_o(db_errs[14]), .syndrome_o(), .sb_fix_o());
  ecc_enc #(.K(1)) enc_14 (.d_i(csr_mcause_interrupt_flag_next), .q_o(csr_mcause_interrupt_flag_next_ecc), .p_o(), .p0_o());

  // 16. csr_mtval
  ecc_dec #(.K(32)) dec_15 (.rst_ni(1'b1), .clk_i(1'b0), .clkena_i(1'b0), .d_i(csr_mtval_ecc), .q_o(csr_mtval), .sb_err_o(sb_errs[15]), .db_err_o(db_errs[15]), .syndrome_o(), .sb_fix_o());
  ecc_enc #(.K(32)) enc_15 (.d_i(csr_mtval_next), .q_o(csr_mtval_next_ecc), .p_o(), .p0_o());

  // 17. csr_mscratch
  ecc_dec #(.K(32)) dec_16 (.rst_ni(1'b1), .clk_i(1'b0), .clkena_i(1'b0), .d_i(csr_mscratch_ecc), .q_o(csr_mscratch), .sb_err_o(sb_errs[16]), .db_err_o(db_errs[16]), .syndrome_o(), .sb_fix_o());
  ecc_enc #(.K(32)) enc_16 (.d_i(csr_mscratch_next), .q_o(csr_mscratch_next_ecc), .p_o(), .p0_o());

  // 18. csr_minstret
  ecc_dec #(.K(64)) dec_17 (.rst_ni(1'b1), .clk_i(1'b0), .clkena_i(1'b0), .d_i(csr_minstret_ecc), .q_o(csr_minstret), .sb_err_o(sb_errs[17]), .db_err_o(db_errs[17]), .syndrome_o(), .sb_fix_o());
  ecc_enc #(.K(64)) enc_17 (.d_i(csr_minstret_next), .q_o(csr_minstret_next_ecc), .p_o(), .p0_o());

  // 19. csr_mcycle
  ecc_dec #(.K(64)) dec_18 (.rst_ni(1'b1), .clk_i(1'b0), .clkena_i(1'b0), .d_i(csr_mcycle_ecc), .q_o(csr_mcycle), .sb_err_o(sb_errs[18]), .db_err_o(db_errs[18]), .syndrome_o(), .sb_fix_o());
  ecc_enc #(.K(64)) enc_18 (.d_i(csr_mcycle_next), .q_o(csr_mcycle_next_ecc), .p_o(), .p0_o());

  // 20. csr_utime
  ecc_dec #(.K(64)) dec_19 (.rst_ni(1'b1), .clk_i(1'b0), .clkena_i(1'b0), .d_i(csr_utime_ecc), .q_o(csr_utime), .sb_err_o(sb_errs[19]), .db_err_o(db_errs[19]), .syndrome_o(), .sb_fix_o());
  ecc_enc #(.K(64)) enc_19 (.d_i(csr_utime_next), .q_o(csr_utime_next_ecc), .p_o(), .p0_o());


  // --- Structural Wire Assignments ---

  assign csr_data_mask = csr_operation_s2[2] == 1'b1 ? {27'b0, immediate_4_0_s2} : rs1_data_s2;
  assign misaligned_address_exception = misaligned_load_s1 | misaligned_store_s1 | misaligned_instruction_address_s1;
  assign interrupt_address_offset = {{25{1'b0}}, csr_mcause_code, 2'b00};

  assign trap_handler_address_s1 = (csr_mtvec[1:0] == 2'b01 && csr_mcause_interrupt_flag) ?
    {csr_mtvec[31:2], 2'b00} + interrupt_address_offset : {csr_mtvec[31:2], 2'b00};

  assign interrupt_pending_s1 = (csr_mie_meie & csr_mip_meip) | (csr_mie_mtie & csr_mip_mtip) |
    (csr_mie_msie & csr_mip_msip) | (|(csr_mie_mfie & csr_mip_mfip));

  assign global_interrupt_enable_s1 = csr_mstatus_mie;
  assign exception_address_s1 = csr_mepc;

  assign csr_mstatus = {
    19'b0,
    2'b11,  // M-mode Prior Privilege (always M-mode)
    3'b0,
    csr_mstatus_mpie,  // M-mode Prior Global Interrupt Enable
    3'b0,
    csr_mstatus_mie,  // M-mode Global Interrupt Enable
    3'b0
  };

  assign csr_mie = {
    csr_mie_mfie,  // RVX Fast Interrupt Enable
    4'b0,
    csr_mie_meie,  // M-mode External Interrupt Enable
    3'b0,
    csr_mie_mtie,  // M-mode Timer Interrupt Enable
    3'b0,
    csr_mie_msie,  // M-mode Software Interrupt Enable
    3'b0
  };

  assign csr_mip = {
    csr_mip_mfip,  // RVX Fast Interrupt Pending
    4'b0,
    csr_mip_meip,  // M-mode External Interrupt Pending
    3'b0,
    csr_mip_mtip,  // M-mode Timer Interrupt Pending
    3'b0,
    csr_mip_msip,  // M-mode Software Interrupt Pending
    3'b0
  };


  // --- Output & Mask Muxing ---

  always @* begin : csr_write_data_mux
    case (csr_operation_s2[1:0])
      `RVX_CSR_OPERATION_RW: csr_write_data = csr_data_mask;
      `RVX_CSR_OPERATION_RS: csr_write_data = csr_data_out_s2 | csr_data_mask;
      `RVX_CSR_OPERATION_RC: csr_write_data = csr_data_out_s2 & ~csr_data_mask;
      default:               csr_write_data = csr_data_out_s2;
    endcase
  end

  always @* begin : csr_data_out_mux
    case (csr_address_s2)
      `RISCV_CSR_MARCHID_ADDR:      csr_data_out_s2 = 32'h00000018; // RVX microarchitecture ID
      `RISCV_CSR_MIMPID_ADDR:       csr_data_out_s2 = 32'h00000007; // Version 4.0.0
      `RISCV_CSR_UCYCLE_ADDR:       csr_data_out_s2 = csr_mcycle[31:0];
      `RISCV_CSR_UCYCLEH_ADDR:      csr_data_out_s2 = csr_mcycle[63:32];
      `RISCV_CSR_UTIME_ADDR:        csr_data_out_s2 = csr_utime[31:0];
      `RISCV_CSR_UTIMEH_ADDR:       csr_data_out_s2 = csr_utime[63:32];
      `RISCV_CSR_UINSTRET_ADDR:     csr_data_out_s2 = csr_minstret[31:0];
      `RISCV_CSR_UINSTRETH_ADDR:    csr_data_out_s2 = csr_minstret[63:32];
      `RISCV_CSR_MSTATUS_ADDR:      csr_data_out_s2 = csr_mstatus;
      `RISCV_CSR_MSTATUSH_ADDR:     csr_data_out_s2 = 32'h00000000;
      `RISCV_CSR_MISA_ADDR:         csr_data_out_s2 = 32'h40000100; // RV32I base ISA only
      `RISCV_CSR_MIE_ADDR:          csr_data_out_s2 = csr_mie;
      `RISCV_CSR_MTVEC_ADDR:        csr_data_out_s2 = csr_mtvec;
      `RISCV_CSR_MSCRATCH_ADDR:     csr_data_out_s2 = csr_mscratch;
      `RISCV_CSR_MEPC_ADDR:         csr_data_out_s2 = csr_mepc;
      `RISCV_CSR_MCAUSE_ADDR:       csr_data_out_s2 = csr_mcause;
      `RISCV_CSR_MTVAL_ADDR:        csr_data_out_s2 = csr_mtval;
      `RISCV_CSR_MIP_ADDR:          csr_data_out_s2 = csr_mip;
      `RISCV_CSR_MCYCLE_ADDR:       csr_data_out_s2 = csr_mcycle[31:0];
      `RISCV_CSR_MCYCLEH_ADDR:      csr_data_out_s2 = csr_mcycle[63:32];
      `RISCV_CSR_MINSTRET_ADDR:     csr_data_out_s2 = csr_minstret[31:0];
      `RISCV_CSR_MINSTRETH_ADDR:    csr_data_out_s2 = csr_minstret[63:32];
      `RVX_CSR_SPI_BOOT_IMAGE_ADDR: csr_data_out_s2 = SPI_BOOT_IMAGE_ADDRESS;
      default:                      csr_data_out_s2 = 32'h00000000;
    endcase
  end


  // --- Next-State Logic (Combinational translations of original posedge logic) ---

  always @* begin : csr_mstatus_next_logic
    csr_mstatus_mie_next  = csr_mstatus_mie;
    csr_mstatus_mpie_next = csr_mstatus_mpie;
    
    if (!reset_n) begin
      csr_mstatus_mie_next  = 1'b0;
      csr_mstatus_mpie_next = 1'b1;
    end
    else if (clock_enable) begin
      if (core_state_s1 == `RVX_STATE_TRAP_RETURN) begin
        csr_mstatus_mie_next  = csr_mstatus_mpie;
        csr_mstatus_mpie_next = 1'b1;
      end
      else if (core_state_s1 == `RVX_STATE_TRAP_TAKEN) begin
        csr_mstatus_mpie_next = csr_mstatus_mie;
        csr_mstatus_mie_next  = 1'b0;
      end
      else if (core_state_s1 == `RVX_STATE_OPERATING && csr_address_s2 == `RISCV_CSR_MSTATUS_ADDR &&
               csr_write_request_s2) begin
        csr_mstatus_mie_next  = csr_write_data[3];
        csr_mstatus_mpie_next = csr_write_data[7];
      end
    end
  end

  always @* begin : csr_mie_next_logic
    csr_mie_mfie_next = csr_mie_mfie;
    csr_mie_meie_next = csr_mie_meie;
    csr_mie_mtie_next = csr_mie_mtie;
    csr_mie_msie_next = csr_mie_msie;
    
    if (!reset_n) begin
      csr_mie_mfie_next = 16'b0;
      csr_mie_meie_next = 1'b0;
      csr_mie_mtie_next = 1'b0;
      csr_mie_msie_next = 1'b0;
    end
    else if (clock_enable & csr_address_s2 == `RISCV_CSR_MIE_ADDR && csr_write_request_s2) begin
      csr_mie_mfie_next = csr_write_data[31:16];
      csr_mie_meie_next = csr_write_data[11];
      csr_mie_mtie_next = csr_write_data[7];
      csr_mie_msie_next = csr_write_data[3];
    end
  end

  always @* begin : csr_mip_next_logic
    csr_mip_mfip_next = csr_mip_mfip;
    csr_mip_meip_next = csr_mip_meip;
    csr_mip_mtip_next = csr_mip_mtip;
    csr_mip_msip_next = csr_mip_msip;
    
    if (!reset_n) begin
      csr_mip_mfip_next = 16'b0;
      csr_mip_meip_next = 1'b0;
      csr_mip_mtip_next = 1'b0;
      csr_mip_msip_next = 1'b0;
    end
    else begin
      csr_mip_mfip_next = irq_fast_s1;
      csr_mip_meip_next = irq_external_s1;
      csr_mip_mtip_next = irq_timer_s1;
      csr_mip_msip_next = irq_software_s1;
    end
  end

  always @* begin : csr_mepc_next_logic
    csr_mepc_next = csr_mepc;
    
    if (!reset_n) csr_mepc_next = 32'h00000000;
    else if (clock_enable) begin
      if (take_trap_s1) csr_mepc_next = program_counter_s1;
      else if (core_state_s1 == `RVX_STATE_OPERATING && csr_address_s2 == `RISCV_CSR_MEPC_ADDR && csr_write_request_s2)
        csr_mepc_next = {csr_write_data[31:2], 2'b00};
    end
  end

  always @* begin : csr_mscratch_next_logic
    csr_mscratch_next = csr_mscratch;
    
    if (!reset_n) csr_mscratch_next = 32'h00000000;
    else if (clock_enable & csr_address_s2 == `RISCV_CSR_MSCRATCH_ADDR && csr_write_request_s2)
      csr_mscratch_next = csr_write_data;
  end

  always @* begin : csr_mcycle_next_logic
    csr_mcycle_next = csr_mcycle;
    
    if (!reset_n) csr_mcycle_next = 64'b0;
    else begin
      if (clock_enable & csr_address_s2 == `RISCV_CSR_MCYCLE_ADDR && csr_write_request_s2)
        csr_mcycle_next = {csr_mcycle[63:32], csr_write_data} + 1;
      else if (clock_enable & csr_address_s2 == `RISCV_CSR_MCYCLEH_ADDR && csr_write_request_s2)
        csr_mcycle_next = {csr_write_data, csr_mcycle[31:0]} + 1;
      else csr_mcycle_next = csr_mcycle + 1;
    end
  end

  always @* begin : csr_minstret_next_logic
    csr_minstret_next = csr_minstret;
    
    if (!reset_n) csr_minstret_next = 64'b0;
    else if (clock_enable) begin
      if (csr_address_s2 == `RISCV_CSR_MINSTRET_ADDR && csr_write_request_s2) begin
        if (core_state_s1 == `RVX_STATE_OPERATING) csr_minstret_next = {csr_minstret[63:32], csr_write_data} + 1;
        else csr_minstret_next = {csr_minstret[63:32], csr_write_data};
      end
      else if (csr_address_s2 == `RISCV_CSR_MINSTRETH_ADDR && csr_write_request_s2) begin
        if (core_state_s1 == `RVX_STATE_OPERATING) csr_minstret_next = {csr_write_data, csr_minstret[31:0]} + 1;
        else csr_minstret_next = {csr_write_data, csr_minstret[31:0]};
      end
      else begin
        if (core_state_s1 == `RVX_STATE_OPERATING) csr_minstret_next = csr_minstret + 1;
        else csr_minstret_next = csr_minstret;
      end
    end
  end

  always @* begin : csr_utime_next_logic
    csr_utime_next = memory_mapped_timer_s1;
  end

  always @* begin : csr_mcause_next_logic
    csr_mcause_next = csr_mcause;
    
    if (!reset_n) csr_mcause_next = 32'h00000000;
    else if (clock_enable) begin
      if (core_state_s1 == `RVX_STATE_TRAP_TAKEN) csr_mcause_next = {csr_mcause_interrupt_flag, 26'b0, csr_mcause_code};
      else
          if (core_state_s1 == `RVX_STATE_OPERATING && csr_address_s2 == `RISCV_CSR_MCAUSE_ADDR && csr_write_request_s2)
        csr_mcause_next = csr_write_data;
    end
  end

  always @* begin : csr_mcause_code_next_logic
    csr_mcause_code_next           = csr_mcause_code;
    csr_mcause_interrupt_flag_next = csr_mcause_interrupt_flag;
    
    // Strict preservation of IF sequence from original code to avoid logic drifts
    if (!reset_n) begin
      csr_mcause_code_next           = 5'd0;
      csr_mcause_interrupt_flag_next = 1'b0;
    end
    if (clock_enable & core_state_s1 == `RVX_STATE_OPERATING) begin
      if (misaligned_instruction_address_s1) begin
        csr_mcause_code_next           = 5'd0;
        csr_mcause_interrupt_flag_next = 1'b0;
      end
      else if (illegal_instruction_s1) begin
        csr_mcause_code_next           = 5'd2;
        csr_mcause_interrupt_flag_next = 1'b0;
      end
      else if (ebreak_s1) begin
        csr_mcause_code_next           = 5'd3;
        csr_mcause_interrupt_flag_next = 1'b0;
      end
      else if (misaligned_load_s1) begin
        csr_mcause_code_next           = 5'd4;
        csr_mcause_interrupt_flag_next = 1'b0;
      end
      else if (misaligned_store_s1) begin
        csr_mcause_code_next           = 5'd6;
        csr_mcause_interrupt_flag_next = 1'b0;
      end
      else if (ecall_s1) begin
        csr_mcause_code_next           = 5'd11;
        csr_mcause_interrupt_flag_next = 1'b0;
      end
      else if (csr_mstatus_mie & csr_mie_mfie[0] & csr_mip_mfip[0]) begin
        csr_mcause_code_next           = 5'd16;
        csr_mcause_interrupt_flag_next = 1'b1;
      end
      else if (csr_mstatus_mie & csr_mie_mfie[1] & csr_mip_mfip[1]) begin
        csr_mcause_code_next           = 5'd17;
        csr_mcause_interrupt_flag_next = 1'b1;
      end
      else if (csr_mstatus_mie & csr_mie_mfie[2] & csr_mip_mfip[2]) begin
        csr_mcause_code_next           = 5'd18;
        csr_mcause_interrupt_flag_next = 1'b1;
      end
      else if (csr_mstatus_mie & csr_mie_mfie[3] & csr_mip_mfip[3]) begin
        csr_mcause_code_next           = 5'd19;
        csr_mcause_interrupt_flag_next = 1'b1;
      end
      else if (csr_mstatus_mie & csr_mie_mfie[4] & csr_mip_mfip[4]) begin
        csr_mcause_code_next           = 5'd20;
        csr_mcause_interrupt_flag_next = 1'b1;
      end
      else if (csr_mstatus_mie & csr_mie_mfie[5] & csr_mip_mfip[5]) begin
        csr_mcause_code_next           = 5'd21;
        csr_mcause_interrupt_flag_next = 1'b1;
      end
      else if (csr_mstatus_mie & csr_mie_mfie[6] & csr_mip_mfip[6]) begin
        csr_mcause_code_next           = 5'd22;
        csr_mcause_interrupt_flag_next = 1'b1;
      end
      else if (csr_mstatus_mie & csr_mie_mfie[7] & csr_mip_mfip[7]) begin
        csr_mcause_code_next           = 5'd23;
        csr_mcause_interrupt_flag_next = 1'b1;
      end
      else if (csr_mstatus_mie & csr_mie_mfie[8] & csr_mip_mfip[8]) begin
        csr_mcause_code_next           = 5'd24;
        csr_mcause_interrupt_flag_next = 1'b1;
      end
      else if (csr_mstatus_mie & csr_mie_mfie[9] & csr_mip_mfip[9]) begin
        csr_mcause_code_next           = 5'd25;
        csr_mcause_interrupt_flag_next = 1'b1;
      end
      else if (csr_mstatus_mie & csr_mie_mfie[10] & csr_mip_mfip[10]) begin
        csr_mcause_code_next           = 5'd26;
        csr_mcause_interrupt_flag_next = 1'b1;
      end
      else if (csr_mstatus_mie & csr_mie_mfie[11] & csr_mip_mfip[11]) begin
        csr_mcause_code_next           = 5'd27;
        csr_mcause_interrupt_flag_next = 1'b1;
      end
      else if (csr_mstatus_mie & csr_mie_mfie[12] & csr_mip_mfip[12]) begin
        csr_mcause_code_next           = 5'd28;
        csr_mcause_interrupt_flag_next = 1'b1;
      end
      else if (csr_mstatus_mie & csr_mie_mfie[13] & csr_mip_mfip[13]) begin
        csr_mcause_code_next           = 5'd29;
        csr_mcause_interrupt_flag_next = 1'b1;
      end
      else if (csr_mstatus_mie & csr_mie_mfie[14] & csr_mip_mfip[14]) begin
        csr_mcause_code_next           = 5'd30;
        csr_mcause_interrupt_flag_next = 1'b1;
      end
      else if (csr_mstatus_mie & csr_mie_mfie[15] & csr_mip_mfip[15]) begin
        csr_mcause_code_next           = 5'd31;
        csr_mcause_interrupt_flag_next = 1'b1;
      end
      else if (csr_mstatus_mie & csr_mie_meie & csr_mip_meip) begin
        csr_mcause_code_next           = 5'd11;
        csr_mcause_interrupt_flag_next = 1'b1;
      end
      else if (csr_mstatus_mie & csr_mie_msie & csr_mip_msip) begin
        csr_mcause_code_next           = 5'd3;
        csr_mcause_interrupt_flag_next = 1'b1;
      end
      else if (csr_mstatus_mie & csr_mie_mtie & csr_mip_mtip) begin
        csr_mcause_code_next           = 5'd7;
        csr_mcause_interrupt_flag_next = 1'b1;
      end
    end
  end

  always @* begin : csr_mtval_next_logic
    csr_mtval_next = csr_mtval;
    
    if (!reset_n) csr_mtval_next = 32'h00000000;
    else if (clock_enable) begin
      if (take_trap_s1) begin
        if (misaligned_address_exception) csr_mtval_next = target_address_s1;
        else if (ebreak_s1) csr_mtval_next = program_counter_s1;
        else if (illegal_instruction_s1) csr_mtval_next = instruction_s1;
        else csr_mtval_next = 32'h00000000;
      end
      else if (core_state_s1 == `RVX_STATE_OPERATING && csr_address_s2 == `RISCV_CSR_MTVAL_ADDR && csr_write_request_s2)
        csr_mtval_next = csr_write_data;
    end
  end

  always @* begin : csr_mtvec_next_logic
    csr_mtvec_next = csr_mtvec;
    
    if (!reset_n) csr_mtvec_next = 32'h00000000;
    else if (clock_enable & csr_address_s2 == `RISCV_CSR_MTVEC_ADDR && csr_write_request_s2)
      csr_mtvec_next = {csr_write_data[31:2], 1'b0, csr_write_data[0]};
  end

  // --- Clock edge register updates (ECC state only) ---

  always @(posedge clock) begin
    csr_mstatus_mie_ecc <= csr_mstatus_mie_next_ecc;
    csr_mstatus_mpie_ecc <= csr_mstatus_mpie_next_ecc;
    csr_mie_mfie_ecc <= csr_mie_mfie_next_ecc;
    csr_mie_meie_ecc <= csr_mie_meie_next_ecc;
    csr_mie_msie_ecc <= csr_mie_msie_next_ecc;
    csr_mie_mtie_ecc <= csr_mie_mtie_next_ecc;
    csr_mip_mfip_ecc <= csr_mip_mfip_next_ecc;
    csr_mip_meip_ecc <= csr_mip_meip_next_ecc;
    csr_mip_msip_ecc <= csr_mip_msip_next_ecc;
    csr_mip_mtip_ecc <= csr_mip_mtip_next_ecc;
    csr_mepc_ecc <= csr_mepc_next_ecc;
    csr_mtvec_ecc <= csr_mtvec_next_ecc;
    csr_mcause_ecc <= csr_mcause_next_ecc;
    csr_mcause_code_ecc <= csr_mcause_code_next_ecc;
    csr_mcause_interrupt_flag_ecc <= csr_mcause_interrupt_flag_next_ecc;
    csr_mtval_ecc <= csr_mtval_next_ecc;
    csr_mscratch_ecc <= csr_mscratch_next_ecc;
    csr_minstret_ecc <= csr_minstret_next_ecc;
    csr_mcycle_ecc <= csr_mcycle_next_ecc;
    csr_utime_ecc <= csr_utime_next_ecc;
  end

endmodule