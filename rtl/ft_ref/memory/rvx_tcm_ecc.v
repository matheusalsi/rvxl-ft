// SPDX-License-Identifier: MIT
// Copyright (c) 2020-2026 RVX Project Contributors

module rvx_tcm_ecc #(

    // Size of the memory in bytes
    parameter SIZE_IN_BYTES = 8192,

    // Path to the file with program and data
    parameter INIT_FILE_PATH = "",

    // Base address of the memory
    parameter BASE_ADDRESS = 32'h00000000

) (

    // Global signals
    input wire clock,
    input wire reset_n,

    // Port 0 (read-only)
    input  wire [31:0] port0_address,
    output wire [31:0] port0_rdata,
    input  wire        port0_rrequest,
    output reg         port0_rresponse,
    output wire [2:0]  port0_sberr,
    output wire [2:0]  port0_dberr,

    // Port 1 (read/write)
    input  wire [31:0] port1_address,
    output wire [31:0] port1_rdata,
    input  wire        port1_rrequest,
    output reg         port1_rresponse,
    output wire [2:0]  port1_sberr,
    output wire [2:0]  port1_dberr,
    input  wire [31:0] port1_wdata,
    input  wire [ 3:0] port1_wstrobe,
    input  wire        port1_wrequest,
    output reg         port1_wresponse

);

  localparam NUM_WORDS = SIZE_IN_BYTES / 4;

  //reg  [31:0] tcm [BASE_ADDRESS/4 : BASE_ADDRESS/4 + NUM_WORDS - 1];
  reg  [12:0] tcm_ecc [3:0][BASE_ADDRESS/4 : BASE_ADDRESS/4 + NUM_WORDS - 1];

  // verilator lint_off UNUSED
  wire [31:0] port0_effective_address;
  wire [31:0] port1_effective_address;
  // verilator lint_on UNUSED

  wire        port0_invalid_address;
  wire        port1_invalid_address;

  // verilog_format: off
  // verilator lint_off UNSIGNED
  assign port0_invalid_address = ($unsigned(port0_address) >= $unsigned(SIZE_IN_BYTES + BASE_ADDRESS)) |
                                 ($unsigned(port0_address) <  $unsigned(BASE_ADDRESS));
  assign port1_invalid_address = ($unsigned(port1_address) >= $unsigned(SIZE_IN_BYTES + BASE_ADDRESS)) |
                                 ($unsigned(port1_address) <  $unsigned(BASE_ADDRESS));
  // verilator lint_on UNSIGNED
  // verilog_format: on

  integer i_init;
  initial begin
    for (i_init = BASE_ADDRESS/4; i_init < BASE_ADDRESS/4 + NUM_WORDS; i_init = i_init + 1) begin
        tcm_ecc[0][i_init] = 12'd0;
        tcm_ecc[1][i_init] = 12'd0;
        tcm_ecc[2][i_init] = 12'd0;
        tcm_ecc[3][i_init] = 12'd0;
        end
  end

  assign port0_effective_address = $unsigned(port0_address[31:0]) >> 2;
  assign port1_effective_address = $unsigned(port1_address[31:0]) >> 2;
  
  //ECC
  
  //PORT 0
  reg [12:0] port0_ecc_read_coded [3:0];
  wire [7:0] port0_ecc_read_clean [3:0];
  wire port0_ecc_sb_err[3:0] , port0_ecc_db_err[3:0];
  genvar i; 
  generate
      for (i = 0; i < 4; i = i + 1) begin : gen_ecc_port0
          ecc_dec #( .K(8), .LATENCY(0), .P0_LSB(1)) dec_port0 (
          .d_i(port0_ecc_read_coded[i]),        //encoded code word input
          .q_o(port0_ecc_read_clean[i]),        //information bit vector output
          .syndrome_o(),                           //syndrome vector output
        
          //flags
          .sb_err_o(port0_ecc_sb_err[i]),   //single bit error detected
          .db_err_o(port0_ecc_db_err[i]),   //double bit error detected
          .sb_fix_o()                   //repaired error in the information bits
        );
      end
  endgenerate
  
  assign port0_rdata = port0_rresponse ? {port0_ecc_read_clean[3], port0_ecc_read_clean[2], port0_ecc_read_clean[1], port0_ecc_read_clean[0]} : 32'h00000000; 
  
  // Mask Port 0 errors so they only output on the exact cycle the read completes
  assign port0_sberr = port0_rresponse ? (port0_ecc_sb_err[3] + port0_ecc_sb_err[2] + port0_ecc_sb_err[1] + port0_ecc_sb_err[0]) : 3'd0;
  assign port0_dberr = port0_rresponse ? (port0_ecc_db_err[3] + port0_ecc_db_err[2] + port0_ecc_db_err[1] + port0_ecc_db_err[0]) : 3'd0;

  
//  always @(*) begin
//    if (port0_rresponse) begin
//        port0_rdata[31:24] = port0_ecc_read_clean[3];
//        port0_rdata[23:16] = port0_ecc_read_clean[2];
//        port0_rdata[15: 8] = port0_ecc_read_clean[1];
//        port0_rdata[ 7: 0] = port0_ecc_read_clean[0];
//    end else begin
//        port0_rdata = 32'h00000000;    
//    end
//  end


//PORT 1
  reg  [12:0] port1_ecc_read_coded [3:0];
  wire [7:0] port1_ecc_read_clean [3:0];
  
  wire [7:0] port1_ecc_write_clean [3:0];
  wire [12:0] port1_ecc_write_coded [3:0];
  wire port1_ecc_sb_err[3:0] , port1_ecc_db_err[3:0]; 
  generate
      for (i = 0; i < 4; i = i + 1) begin : gen_ecc_port1
          ecc_dec #( .K(8), .LATENCY(0), .P0_LSB(1)) dec_port1 (
          .d_i(port1_ecc_read_coded[i]),        //encoded code word input
          .q_o(port1_ecc_read_clean[i]),        //information bit vector output
          .syndrome_o(),                           //syndrome vector output
        
          //flags
          .sb_err_o(port1_ecc_sb_err[i]),   //single bit error detected
          .db_err_o(port1_ecc_db_err[i]),   //double bit error detected
          .sb_fix_o()                       //repaired error in the information bits
        );
          ecc_enc #( .K(8), .P0_LSB(1) ) enc_port1 (
          .d_i(port1_ecc_write_clean[i]),      //information bit vector input
          .q_o(port1_ecc_write_coded[i]),      //encoded data word output
          .p_o(),                              //parity vector output
          .p0_o()                              //extended parity bit
        );
      end
  endgenerate
//  always @(*) begin
//    if (port1_rresponse) begin
//        port1_rdata[31:24] = port1_ecc_read_clean[3];
//        port1_rdata[23:16] = port1_ecc_read_clean[2];
//        port1_rdata[15: 8] = port1_ecc_read_clean[1];
//        port1_rdata[ 7: 0] = port1_ecc_read_clean[0];
//    end else begin
//        port1_rdata = 32'h00000000;    
//    end
//  end
  assign port1_rdata = port1_rresponse ? {port1_ecc_read_clean[3], port1_ecc_read_clean[2], port1_ecc_read_clean[1], port1_ecc_read_clean[0]} : 32'h00000000;
  
  // Mask Port 1 errors identically
  assign port1_sberr = port1_rresponse ? (port1_ecc_sb_err[3] + port1_ecc_sb_err[2] + port1_ecc_sb_err[1] + port1_ecc_sb_err[0]) : 3'd0;
  assign port1_dberr = port1_rresponse ? (port1_ecc_db_err[3] + port1_ecc_db_err[2] + port1_ecc_db_err[1] + port1_ecc_db_err[0]) : 3'd0;
    
  assign port1_ecc_write_clean[3] = port1_wdata[31:24];
  assign port1_ecc_write_clean[2] = port1_wdata[23:16];
  assign port1_ecc_write_clean[1] = port1_wdata[15:8];
  assign port1_ecc_write_clean[0] = port1_wdata[7:0];

// Read/Write Logic

// PORT0
  always @(posedge clock) begin
    if (!reset_n) begin
     //port0_rdata <= 32'h00000000;
      port0_rresponse <= 1'b0;
    end
    else if(port0_rrequest && !port0_invalid_address) begin
      //port0_rdata <= tcm[port0_effective_address];
      port0_ecc_read_coded[0] <= tcm_ecc[0][port0_effective_address];
      port0_ecc_read_coded[1] <= tcm_ecc[1][port0_effective_address];
      port0_ecc_read_coded[2] <= tcm_ecc[2][port0_effective_address];
      port0_ecc_read_coded[3] <= tcm_ecc[3][port0_effective_address];
      port0_rresponse <= 1'b1;
    end
    else begin
    //port0_rdata <= 32'h00000000;
      port0_rresponse <= 1'b0;
    end
    
// PORT1
    if (!reset_n) begin
      //port1_rdata <= 32'h00000000;
      port1_rresponse <= 1'b0;
    end
    else if(port1_rrequest && !port1_invalid_address) begin
      //port1_rdata <= tcm[port1_effective_address];
      port1_ecc_read_coded[0] <= tcm_ecc[0][port1_effective_address];
      port1_ecc_read_coded[1] <= tcm_ecc[1][port1_effective_address];
      port1_ecc_read_coded[2] <= tcm_ecc[2][port1_effective_address];
      port1_ecc_read_coded[3] <= tcm_ecc[3][port1_effective_address];
      port1_rresponse <= 1'b1;
    end
    else begin
      //port1_rdata <= 32'h00000000;
      port1_rresponse <= 1'b0;
    end
  end

  always @(posedge clock) begin
    if (port1_wrequest && !port1_invalid_address) begin
      port1_wresponse <= 1'b1;
      if (port1_wstrobe[0]) tcm_ecc[0][port1_effective_address] <= port1_ecc_write_coded[0];
      if (port1_wstrobe[1]) tcm_ecc[1][port1_effective_address] <= port1_ecc_write_coded[1];
      if (port1_wstrobe[2]) tcm_ecc[2][port1_effective_address] <= port1_ecc_write_coded[2];
      if (port1_wstrobe[3]) tcm_ecc[3][port1_effective_address] <= port1_ecc_write_coded[3];
    end
    else port1_wresponse <= 1'b0;
  end

endmodule
