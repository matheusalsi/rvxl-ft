// ----------------------------------------------------------------------------
// SPDX-FileCopyrightText: Copyright (c) 2026 Universidade Federal do Rio Grande do Sul
// SPDX-FileCopyrightText: Copyright (c) 2026 Fabio Benevenuti
// SPDX-FileCopyrightText: Copyright (c) 2020-2026 Stephan Nolting. All rights reserved.
// SPDX-FileCopyrightText: Copyright (c) NEORV32 contributors.
// SPDX-License-Identifier: BSD-3-Clause
//
// Derived from: 
//    https://github.com/stnolting/neorv32 
//    commit 741b61ef5f76619bcf3be8065e614b29706475c6
// Source file: 
//    rtl/verilog/testbench.v
//
// Modifications: overall test plan reformulated for RVX RISC-V
// ----------------------------------------------------------------------------



`timescale 1ns/1ns



`define GENERATE_VCD   1
`define VCD_FILENAME   "TOP_PAD_tb.vcd"
`define VCD_DUMP_LEVEL 0 // zero is unlimited
`define SDF_FILENAME   "TOP_PAD_tb.sdf"
`define MAX_TEST_TIME_MS  15
`define MAX_TEST_TIME_NS  (`MAX_TEST_TIME_MS*1000*1000)

`define MIN_TEST_TIME_MS  12
`define MIN_TEST_TIME_NS  (`MIN_TEST_TIME_MS*1000*1000)


//`define BOOTLOADER_INIT_FILE  "bootstrap_1_linear.mem"
`ifndef FLASH_INIT_FILE
`define FLASH_INIT_FILE "soc_test_suite_2_flash.mem"
`endif


module TOP_PAD_tb;

    //
    // DUT
    //

    reg dut_clock;
    reg dut_reset_n;
    wire dut_reset;
    
    // UART
    wire dut_uart_rx;
    wire dut_uart_tx;
    // REP_UART
    wire dut_rep_uart_rx;
    wire dut_rep_uart_tx;
    // SPI
    wire dut_sclk;
    wire dut_mosi; 
    wire dut_miso;
    wire dut_cs;
    // I2C    
    wire dut_i2c_sda;
    wire dut_i2c_scl;
    // GPIO
    wire [7:0] dut_gpio;

    TOP_PAD          
    dut (
        .clock(dut_clock), 
        .reset_n(dut_reset_n),
        // UART     
        .uart_rx(dut_uart_rx), 
        .uart_tx(dut_uart_tx),
        // UART     
        .rep_uart_rx(dut_rep_uart_rx), 
        .rep_uart_tx(dut_rep_uart_tx),
        // SPI
        .sclk(dut_sclk), 
        .mosi(dut_mosi), 
        .miso(dut_miso), 
        .cs(dut_cs),
        // I2C    
        .i2c_sda_inout(dut_i2c_sda), 
        .i2c_scl_inout(dut_i2c_scl),
        // GPIO
        .gpio_inout(dut_gpio)
    );



    //
    // Test harness defs
    //

    localparam DUT_CLOCK_FREQUENCY_HZ = 38461538;
    localparam DUT_CLOCK_PERIOD_NS = 26; // nanosecs

    localparam DUT_RESET_PULSE_LENGTH_TICKS = 16;

    localparam TST_I2C_DEV_ADDR = 7'h15;
    localparam TST_REG_DATA_WIDTH = 8;

    reg tst_passed = 0;
    reg tst_failed = 0;
    wire [TST_REG_DATA_WIDTH-1:0] tst_i2c_q;

    //
    // Clock and reset generation
    //

    initial begin
    dut_clock = 1'b1;
        forever #(DUT_CLOCK_PERIOD_NS / 2) begin
            dut_clock = ~dut_clock;
        end
    end

    assign dut_reset = !dut_reset_n;
    initial begin
        $display("%t: %m: Starting testbench", $time);
        $monitor("%t: %m: DUT reset: %0d", $time, dut_reset_n);
        
                                                              dut_reset_n = 1'b1;
        #(DUT_CLOCK_PERIOD_NS/4)                              dut_reset_n = 1'b0;
        #(DUT_CLOCK_PERIOD_NS * DUT_RESET_PULSE_LENGTH_TICKS) dut_reset_n = 1'b1;
    end

    pullup (dut_i2c_sda);
    pullup (dut_i2c_scl);
    //pullup (dut_cs);
    //pullup (dut_mosi);
    //pulldown (dut_miso);
    
    //0
    pulldown(dut_gpio[0]);
    pulldown(dut_gpio[1]);
    pulldown(dut_gpio[2]);
    pulldown(dut_gpio[3]);

    //5
    pullup(  dut_gpio[4]);
    pulldown(dut_gpio[5]);
    pullup(  dut_gpio[6]);
    pulldown(dut_gpio[7]);
   
    pullup(dut_uart_tx);
    pullup(dut_uart_rx);
    pullup(dut_rep_uart_tx);
    // pullup(dut_rep_uart_rx); // Replaced by direct assignment

    i2c_1_reg_bidir #(
        .I2C_DEV_ADDR(TST_I2C_DEV_ADDR),
        .REG_DATA_WIDTH(TST_REG_DATA_WIDTH)
    ) dummy_i2c_dev_i (
        .aresetn(dut_reset_n),
        .sda(dut_i2c_sda),
        .scl(dut_i2c_scl),
        .q(tst_i2c_q)
    );
    
    spi_mem_emu #(
        .SIZE_IN_BYTES(1024),
        .INIT_FILE_PATH(`FLASH_INIT_FILE),
        .BASE_ADDRESS(32'h00000000) // default 32'h00000000
    ) dummy_flash_dev_i (
        .clk(dut_sclk),
        .cs_n(dut_cs),
        .mosi(dut_mosi),
        .miso(dut_miso)
    );


    // UART observer

    localparam DUT_UART_BAUDRATE = 115200;

    wire [7:0]  tst_uart_data;
    wire        tst_uart_valid;
    reg         tst_uart_ready;
    wire        tst_uart_busy;
    wire        tst_uart_overrun_error;
    wire        tst_uart_frame_error;
    reg  [3:0]  tst_uart_chars;
    wire [15:0] tst_uart_prescale = DUT_CLOCK_FREQUENCY_HZ/(DUT_UART_BAUDRATE*8);

    uart_rx #(
        .DATA_WIDTH(8)
    ) tst_uart_rx (
        .clk(dut_clock),
        .rst(dut_reset),
        .m_axis_tdata(tst_uart_data),
        .m_axis_tvalid(tst_uart_valid),
        .m_axis_tready(tst_uart_ready),
        .rxd(dut_uart_tx),
        .busy(tst_uart_busy),
        .overrun_error(tst_uart_overrun_error),
        .frame_error(tst_uart_frame_error),
        .prescale(tst_uart_prescale)
    );
    
    initial begin
        tst_uart_chars <= 0;
    end
    
	always begin
		
		@(negedge dut_clock);
		tst_uart_ready <= 1'b0;
		
		@(posedge dut_clock);
		if (tst_uart_valid) begin
            tst_uart_ready <= 1'b1;
            
            // RVX test is emitted by bootstrap_1
            // > xx xx is emitted by soc_test_suite_1
            
            //R
            if ( (tst_uart_chars == 4'd0) && ( tst_uart_data == 8'd82) ) begin 
                tst_uart_chars <= 4'd1;
            end
            //V
            else if ( (tst_uart_chars == 4'd1) && ( tst_uart_data == 8'd86) ) begin
                tst_uart_chars <= 4'd2;
            //X
            end
            else if ( (tst_uart_chars == 4'd2) && ( tst_uart_data == 8'd88) ) begin
                tst_uart_chars <= 4'd3;
            end
            //>
            else if ( (tst_uart_chars == 4'd3) && ( tst_uart_data == 8'd62) ) begin
                tst_uart_chars <= 4'd4;
            end
            //> with terse bootloader
            else if ( (tst_uart_chars == 4'd0) && ( tst_uart_data == 8'd62) ) begin
                tst_uart_chars <= 4'd5;
            end
            
            // non-printable
            if (tst_uart_data < 32 || tst_uart_data >= 127) begin
                $display("Serial data: %d", tst_uart_data);
            end
            // printable
            else begin
                $display("Serial data: '%c' %d", tst_uart_data, tst_uart_data);
            end
    		@(posedge dut_clock);
		end
    end

    // REP_UART observer and stimulus
    localparam DUT_REP_UART_BAUDRATE = 115200;
    wire [15:0] tst_rep_uart_prescale = DUT_CLOCK_FREQUENCY_HZ/(DUT_REP_UART_BAUDRATE*8);
    wire [7:0] tst_rep_uart_data;
    wire       tst_rep_uart_valid;
    reg        tst_rep_uart_ready;
    reg  [4:0] tst_rep_uart_zero_count;

    uart_rx #(
        .DATA_WIDTH(8)
    ) tst_rep_uart_rx_inst (
        .clk(dut_clock),
        .rst(dut_reset),
        .m_axis_tdata(tst_rep_uart_data),
        .m_axis_tvalid(tst_rep_uart_valid),
        .m_axis_tready(tst_rep_uart_ready),
        .rxd(dut_rep_uart_tx),
        .busy(),
        .overrun_error(),
        .frame_error(),
        .prescale(tst_rep_uart_prescale)
    );

    initial begin
        tst_rep_uart_zero_count = 0;
        tst_rep_uart_ready = 1'b0;
    end

    always @(posedge dut_clock) begin
        tst_rep_uart_ready <= 1'b1;
        if (tst_rep_uart_valid && tst_rep_uart_ready) begin
            $display("%t: REP_UART data: 0x%02X", $time, tst_rep_uart_data);
            if (tst_rep_uart_data == 8'h00) begin
                tst_rep_uart_zero_count <= tst_rep_uart_zero_count + 1;
            end else begin
                $display("%t: REP_UART received non-zero: %x", $time, tst_rep_uart_data);
            end
        end
    end

    reg cpu_tst_passed = 0;
    reg rep_uart_tst_passed = 0;

    // Stimulus for rep_uart_rx
    reg [7:0] tst_rep_uart_tx_data;
    reg       tst_rep_uart_tx_valid;
    wire      tst_rep_uart_tx_ready;
    
    uart_tx #(
        .DATA_WIDTH(8)
    ) tst_rep_uart_tx_inst (
        .clk(dut_clock),
        .rst(dut_reset),
        .s_axis_tdata(tst_rep_uart_tx_data),
        .s_axis_tvalid(tst_rep_uart_tx_valid),
        .s_axis_tready(tst_rep_uart_tx_ready),
        .txd(dut_rep_uart_rx),
        .prescale(tst_rep_uart_prescale)
    );

    integer rep_uart_retry_cnt;
    
    initial begin
        tst_rep_uart_tx_valid = 1'b0;
        tst_rep_uart_tx_data = 8'h00;
        
        $display("%t: [INFO] Waiting for CPU SoC test to pass before starting REP_UART telemetry test...", $time);
        
        while(!cpu_tst_passed) @(posedge dut_clock);
        
        $display("%t: [INFO] Starting REP_UART telemetry test (Sending 'R' command)...", $time);
        
        @(posedge dut_clock);
        // Send 'R' (0x52)
        tst_rep_uart_tx_data = 8'h52;
        tst_rep_uart_tx_valid = 1'b1;
        while(!tst_rep_uart_tx_ready) @(posedge dut_clock);
        @(posedge dut_clock);
        tst_rep_uart_tx_valid = 1'b0;
        
        // Wait for response
        #(1000000000/DUT_REP_UART_BAUDRATE * 15 * 13); // Wait for ~13 bytes worth of time
        
        if (tst_rep_uart_zero_count >= 12) begin
            if (!rep_uart_tst_passed) $display("%t: [PASS] REP_UART telemetry test (received %0d zero bytes).", $time, tst_rep_uart_zero_count);
            rep_uart_tst_passed = 1'b1;
        end else begin
            $display("%t: [FAIL] REP_UART telemetry test (received %0d zero bytes, expected 12).", $time, tst_rep_uart_zero_count);
            tst_failed = 1'b1;
        end
    end

    //
    // Test sequence
    //
    


    initial begin
        $display("%t: [INFO] Starting CPU SoC test (I2C, GPIO, UART).", $time);
        
        #(`MIN_TEST_TIME_MS)

        forever begin
            @(negedge dut_clock);
            if ( ( tst_i2c_q == 8'h50 ) && ( dut_gpio == 8'h55 ) && ( (tst_uart_chars == 5) || (tst_uart_chars == 4) ) ) begin
                if (!cpu_tst_passed) $display("%t: [PASS] CPU SoC test (I2C, GPIO, UART output verified).", $time);
                cpu_tst_passed <= 1'b1;
            end 
        end
    end

    // Overall completion check
    always @(posedge dut_clock) begin
        if (cpu_tst_passed && rep_uart_tst_passed && !tst_passed) begin
            tst_passed <= 1'b1;
        end
    end


    always begin
    
        @(negedge dut_clock);
        
        if (tst_passed) begin
            // http://patorjk.com/software/taag/#p=display&f=Banner&t=
            $display("########     ###     ######   ######  ######## ########");
            $display("##     ##   ## ##   ##    ## ##    ## ##       ##     ##");
            $display("##     ##  ##   ##  ##       ##       ##       ##     ##");
            $display("########  ##     ##  ######   ######  ######   ##     ##");
            $display("##        #########       ##       ## ##       ##     ##");
            $display("##        ##     ## ##    ## ##    ## ##       ##     ##");
            $display("##        ##     ##  ######   ######  ######## ########");
            $display("");  
            $display("%t: %m: Tests passed.", $time);
            $finish;
        end

        if (tst_failed) begin
            // http://patorjk.com/software/taag/#p=display&f=Banner&t=
            $display("########    ###    #### ##       ######## ########");
            $display("##         ## ##    ##  ##       ##       ##     ##");
            $display("##        ##   ##   ##  ##       ##       ##     ##");
            $display("######   ##     ##  ##  ##       ######   ##     ##");
            $display("##       #########  ##  ##       ##       ##     ##");
            $display("##       ##     ##  ##  ##       ##       ##     ##"); 
            $display("##       ##     ## #### ######## ######## ########");
            $display("");  
            $display("%t: %m: Tests failed.", $time);
            $finish;
        end
    end
    
    initial begin
        #(`MAX_TEST_TIME_NS)
        // http://patorjk.com/software/taag/#p=display&f=Banner&t=
        $display("######## #### ##     ## ########  #######  ##     ## ########");
        $display("   ##     ##  ###   ### ##       ##     ## ##     ##    ##");
        $display("   ##     ##  #### #### ##       ##     ## ##     ##    ##");
        $display("   ##     ##  ## ### ## ######   ##     ## ##     ##    ##");
        $display("   ##     ##  ##     ## ##       ##     ## ##     ##    ##");
        $display("   ##     ##  ##     ## ##       ##     ## ##     ##    ##");
        $display("   ##    #### ##     ## ########  #######   #######     ##");
        $display("");
        $display("%t: %m: Test timer run out.", $time);
        $finish;
    end




    //
    // Wave file
    //
    initial begin
        `ifdef GENERATE_VCD
            $dumpfile(`VCD_FILENAME);
            $dumpvars;
            $dumpvars(`VCD_DUMP_LEVEL, TOP_PAD_tb);
        `endif
    end
    
    initial begin
        //`ifdef SYNOPSYS
            $vcdpluson;
            #10000 
            $vcdplusoff;
            //$finish;
        //`endif
    end
    initial begin
        `ifdef sdf
            $sdf_annotate(`SDF_FILENAME, TOP_PAD_tb.dut);
        `endif
    end


endmodule
  
