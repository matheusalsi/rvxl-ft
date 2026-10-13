`timescale 1ns / 1ps

module ecc_counters_uart #(
    parameter NUM_COUNTERS = 6,
    parameter BAUD_RATE    = 115200,
    parameter CLK_FREQ     = 50000000
) (
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire [(NUM_COUNTERS*8)-1 : 0] inc_vals,
    input  wire                          rx,
    output wire                          tx
);

    localparam CMD_GET = 8'h47; // 'G'
    localparam CMD_RST = 8'h52; // 'R'

    // -------------------------------------------------------------------------
    // 1. SECDED ECC Registers & Increment Logic
    // -------------------------------------------------------------------------
    reg  [12:0] counters_ecc_reg [0:NUM_COUNTERS-1];
    wire [7:0]  counters_decoded [0:NUM_COUNTERS-1];
    wire [12:0] counters_encoded [0:NUM_COUNTERS-1];
    
    reg         snapshot_and_clear; // Triggered by 'R' command

    genvar i;
    generate
        for (i = 0; i < NUM_COUNTERS; i = i + 1) begin : g_counters
            
            // Decoder: Still required internally to extract the value for addition
            ecc_dec #(.K(8), .LATENCY(0), .P0_LSB(1)) u_dec (
                .rst_ni(rst_n), .clk_i(clk), .clkena_i(1'b1),
                .d_i(counters_ecc_reg[i]), .q_o(counters_decoded[i]),
                .syndrome_o(), .sb_err_o(), .db_err_o(), .sb_fix_o()
            );

            wire [7:0] inc_val  = inc_vals[(i*8) +: 8];
            wire [7:0] next_val = counters_decoded[i] + inc_val;

            // Encoder: Re-encode the updated value
            ecc_enc #(.K(8), .P0_LSB(1)) u_enc (
                .d_i(next_val), .q_o(counters_encoded[i]), .p_o(), .p0_o()
            );

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    counters_ecc_reg[i] <= 13'd0;
                end else if (snapshot_and_clear) begin
                    // 'R' Command zeroes out the register
                    // 13'd0 is the correct encoded representation of 8'd0
                    counters_ecc_reg[i] <= 13'd0;
                end else begin
                    counters_ecc_reg[i] <= counters_encoded[i];
                end
            end
        end
    endgenerate

    // -------------------------------------------------------------------------
    // 2. UART Instantiation
    // -------------------------------------------------------------------------
    wire [7:0] rx_data_out;
    wire       rx_data_stb;
    reg  [7:0] tx_data_in;
    reg        tx_data_stb;
    wire       tx_data_ack;

    uart #(.baud(BAUD_RATE), .clock_frequency(CLK_FREQ)) u_uart (
        .clock(clk), .reset(~rst_n),              
        .data_stream_in(tx_data_in), .data_stream_in_stb(tx_data_stb),         
        .data_stream_in_ack(tx_data_ack),         
        .data_stream_out(rx_data_out), .data_stream_out_stb(rx_data_stb),         
        .tx(tx), .rx(rx)
    );

    // -------------------------------------------------------------------------
    // 3. UART Transmission FSM (Transmits Raw 13-bit Data)
    // -------------------------------------------------------------------------
    localparam IDLE     = 2'd0;
    localparam SEND     = 2'd1;
    localparam WAIT_ACK = 2'd2;

    reg [1:0]  fsm_state;
    integer    send_idx;
    reg        byte_phase; // 0: LSB, 1: MSB
    
    // Latches the data safely so the registers can be immediately cleared
    reg [12:0] tx_buffer [0:NUM_COUNTERS-1];
    integer k;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fsm_state          <= IDLE;
            send_idx           <= 0;
            byte_phase         <= 1'b0;
            tx_data_stb        <= 1'b0;
            tx_data_in         <= 8'd0;
            snapshot_and_clear <= 1'b0;
        end else begin
            // Default to no clear
            snapshot_and_clear <= 1'b0;
            
            case (fsm_state)
                IDLE: begin
                    tx_data_stb <= 1'b0;
                    if (rx_data_stb && (rx_data_out == CMD_GET || rx_data_out == CMD_RST)) begin
                        fsm_state  <= SEND;
                        send_idx   <= 0;
                        byte_phase <= 1'b0;
                        
                        // Latch current raw 13-bit registers
                        
                        for (k=0; k<NUM_COUNTERS; k=k+1)
                            tx_buffer[k] <= counters_ecc_reg[k];
                        
                        // Trigger a synchronous wipe of the counters if 'R'
                        if (rx_data_out == CMD_RST) begin
                            snapshot_and_clear <= 1'b1;
                        end
                    end
                end

                SEND: begin
                    // Send LSB first, then padded MSB
                    if (byte_phase == 1'b0)
                        tx_data_in <= tx_buffer[send_idx][7:0];
                    else
                        tx_data_in <= {3'd0, tx_buffer[send_idx][12:8]};
                        
                    tx_data_stb <= 1'b1;
                    fsm_state   <= WAIT_ACK;
                end

                WAIT_ACK: begin
                    if (tx_data_ack) begin
                        tx_data_stb <= 1'b0;
                        
                        if (byte_phase == 1'b0) begin
                            // Move to MSB phase
                            byte_phase <= 1'b1;
                            fsm_state  <= SEND;
                        end else begin
                            // MSB done, move to next counter
                            if (send_idx == (NUM_COUNTERS - 1)) begin
                                fsm_state <= IDLE;
                            end else begin
                                send_idx   <= send_idx + 1;
                                byte_phase <= 1'b0;
                                fsm_state  <= SEND;
                            end
                        end
                    end
                end
                
                default: fsm_state <= IDLE;
            endcase
        end
    end

endmodule