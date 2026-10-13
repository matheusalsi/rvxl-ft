// SPDX-License-Identifier: MIT
// Copyright (c) 2020-2026 RVX Project Contributors

`include "rvx_constants.vh"

module rvx_core_integer_file_ecc (

    // Global signals
    input wire clock,
    input wire clock_enable,
    input wire reset_n,

    // Read port 1
    input  wire [ 4:0] rs1_address_s1,
    output wire [31:0] rs1_data_s1,

    // Read port 2
    input  wire [ 4:0] rs2_address_s1,
    output wire [31:0] rs2_data_s1,

    // Write port
    input wire [ 4:0] rd_address_s2,
    input wire [31:0] rd_data_s2,
    input wire        write_request_s2,

    // ECC Error Outputs (Max 2 simultaneous errors -> 2 bits)
    output wire [ 1:0] sb_err_o,
    output wire [ 1:0] db_err_o

);

  // verilog_format: off
  integer i;
  //reg [31:0] integer_file [31:1];
  reg [38:0] ecc_integer_file [31:1];
  // verilog_format: on

  //ECC stuff
  wire [1:0] rs1_err;
  wire [31:0] clean_rs1_data_s1;
  wire [38:0] rs1_ecc_in = (rs1_address_s1 == 5'b00000) ? 39'b0 : ecc_integer_file[rs1_address_s1];

  ecc_dec #( .K(32), .LATENCY(0), .P0_LSB(1)) dec_rs1 (
    .d_i(rs1_ecc_in),                          //encoded code word input
    .q_o(clean_rs1_data_s1),                   //information bit vector output
    .syndrome_o(),                             //syndrome vector output
    .sb_err_o(rs1_err[0]),                     //single bit error detected
    .db_err_o(rs1_err[1]),                     //double bit error detected
    .sb_fix_o()                                //repaired error in the information bits
  );

  wire [1:0] rs2_err;
  wire [31:0] clean_rs2_data_s1;
  wire [38:0] rs2_ecc_in = (rs2_address_s1 == 5'b00000) ? 39'b0 : ecc_integer_file[rs2_address_s1];

  ecc_dec #( .K(32), .LATENCY(0), .P0_LSB(1)) dec_rs2 (
    .d_i(rs2_ecc_in),                         //encoded code word input
    .q_o(clean_rs2_data_s1),                  //information bit vector output
    .syndrome_o(),                            //syndrome vector output
    .sb_err_o(rs2_err[0]),                    //single bit error detected
    .db_err_o(rs2_err[1]),                    //double bit error detected   
    .sb_fix_o()                               //repaired error in the information bits
  );

  wire [38:0] ecc_rd_data_s2;
  
  ecc_enc #( .K(32), .P0_LSB(1) ) enc_port1 (
    .d_i(rd_data_s2),                        //information bit vector input
    .q_o(ecc_rd_data_s2),                    //encoded data word output
    .p_o(),                                  //parity vector output
    .p0_o()                                  //extended parity bit
  );

  // error output aggregation, masked so it only counts when the pipeline isnt stalled
  assign sb_err_o = clock_enable ? (rs1_err[0] + rs2_err[0]) : 2'd0;
  assign db_err_o = clock_enable ? (rs1_err[1] + rs2_err[1]) : 2'd0;

  //regular signals
  wire        write_enable = clock_enable & write_request_s2 & (rd_address_s2 != 5'b00000);
  wire        forward_rs1 = (rs1_address_s1 == rd_address_s2) && write_enable;
  wire        forward_rs2 = (rs2_address_s1 == rd_address_s2) && write_enable;
  
  wire [31:0] rs1_mux = forward_rs1 ? rd_data_s2 : clean_rs1_data_s1;
  wire [31:0] rs2_mux = forward_rs2 ? rd_data_s2 : clean_rs2_data_s1;
  
  // rs1_mux and rs2_mux already evaluate to 0 if address is 0, since the clean data is 0 when fed 39'b0
  assign rs1_data_s1 = rs1_mux;
  assign rs2_data_s1 = rs2_mux;

  //writing
  always @(posedge clock) begin
    if (!reset_n) begin
      for (i = 1; i < 32; i = i + 1) begin
        ecc_integer_file[i] <= 39'b00000000_00000000_00000000_00000000_0000000;
      end
    end
    else if (write_enable) begin
      ecc_integer_file[rd_address_s2] <= ecc_rd_data_s2;
    end
  end

endmodule