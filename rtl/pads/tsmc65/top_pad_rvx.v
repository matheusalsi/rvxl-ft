module top_pad_rvx (
    input        clock,
    input        reset_n,
    input        uart_rx,
    output       uart_tx,
    output       sclk,
    output       mosi,
    input        miso,
    output       cs,
    inout  [7:0] gpio,
    inout        i2c_sda,
    inout        i2c_scl
);

    // Parameters
    localparam TCM_SIZE_IN_BYTES      = 1024;
    localparam TCM_BOOT_IMAGE_PATH    = "";
    localparam SPI_BOOT_IMAGE_ADDRESS = 32'h00000000;
    localparam GPIO_WIDTH             = 8;
    localparam ENABLE_ZMMUL           = 1;

    // Internal wires (core side)
    wire        clock_c, reset_n_c, uart_rx_c, uart_tx_c;
    wire        sclk_c, mosi_c, miso_c, cs_c;
    wire [7:0]  gpio_in_c, gpio_oe_c, gpio_out_c;
    wire        sda_in_c, scl_in_c, sda_out_c, scl_out_c;

    // UM 19/08/2026: validate later
    wire        sda_oen  = sda_out_c;
    wire        scl_oen  = scl_out_c;
    wire [7:0]  gpio_oen = ~gpio_oe_c;

    //=====================
    // Power Pads
    //=====================
    // Left
    PVDD1CDG VDD_0(); PVSS1CDG VSS_0(); PVDD2CDG VDDPST_0(); PVSS2CDG VSSPST_0();
    
    // Top
    PVDD2CDG VDDPST_1(); PVSS2CDG VSSPST_1();
    
    // Right
    PVDD1CDG VDD_2(); PVSS1CDG VSS_2(); PVDD2CDG VDDPST_2(); PVSS2CDG VSSPST_2();
    
    // Bottom   
    PVDD2CDG VDDPST_3(); PVSS2CDG VSSPST_3();

    //=====================
    // Input Pads (only input)
    //=====================
    PDUW0204SCDG PAD_CLK (.I(), .DS(1'b0) , .OEN(1'b1), .PAD(clock), .C(clock_c), .PE(1'b0), .IE(1'b1));
    //ixc013_i16x PAD_CLK  (.PAD(clock),   .DOUT(clock_c));
    PDUW0204SCDG PAD_RSTN (.I(), .DS(1'b0) , .OEN(1'b1), .PAD(reset_n), .C(reset_n_c), .PE(1'b0), .IE(1'b1));
    //ixc013_i16x PAD_RSTN (.PAD(reset_n), .DOUT(reset_n_c));
    PDUW0204SCDG PAD_URX (.I(), .DS(1'b0) , .OEN(1'b1), .PAD(uart_rx), .C(uart_rx_c), .PE(1'b0), .IE(1'b1));
    //ixc013_i16x PAD_URX  (.PAD(uart_rx), .DOUT(uart_rx_c));
    PDUW0204SCDG PAD_MISO (.I(), .DS(1'b0) , .OEN(1'b1), .PAD(miso), .C(miso_c), .PE(1'b0), .IE(1'b1));
    //ixc013_i16x PAD_MISO (.PAD(miso),    .DOUT(miso_c));

    //=====================
    // Output Pads (inout)
    //=====================
    PDUW0204SCDG PAD_UTX (.I(uart_tx_c), .DS(1'b0) , .OEN(1'b0), .PAD(uart_tx), .C(), .PE(1'b0), .IE(1'b0));
    //ixc013_b16m PAD_UTX  (.DIN(uart_tx_c), .OEN(1'b0), .PAD(uart_tx), .DOUT());
    PDUW0204SCDG PAD_SCLK (.I(sclk_c), .DS(1'b0) , .OEN(1'b0), .PAD(sclk), .C(), .PE(1'b0), .IE(1'b0));
    //ixc013_b16m PAD_SCLK (.DIN(sclk_c),    .OEN(1'b0), .PAD(sclk),    .DOUT());
    PDUW0204SCDG PAD_MOSI (.I(mosi_c), .DS(1'b0) , .OEN(1'b0), .PAD(mosi), .C(), .PE(1'b0), .IE(1'b0));
    //ixc013_b16m PAD_MOSI (.DIN(mosi_c),    .OEN(1'b0), .PAD(mosi),    .DOUT());
    PDUW0204SCDG PAD_CS (.I(cs_c), .DS(1'b0) , .OEN(1'b0), .PAD(cs), .C(), .PE(1'b0), .IE(1'b0));
    //ixc013_b16m PAD_CS   (.DIN(cs_c),      .OEN(1'b0), .PAD(cs),      .DOUT());

    //=====================
    // InOut Pads
    //=====================
    PDUW0204SCDG PAD_SDA (.I(1'b0), .DS(1'b0) , .OEN(sda_oen), .PAD(i2c_sda), .C(sda_in_c), .PE(1'b0), .IE(sda_oen));
    //ixc013_b16m PAD_SDA (.PAD(i2c_sda), .DIN(1'b0), .OEN(sda_oen), .DOUT(sda_in_c));
    PDUW0204SCDG PAD_SCL (.I(1'b0), .DS(1'b0) , .OEN(scl_oen), .PAD(i2c_scl), .C(scl_in_c), .PE(1'b0), .IE(scl_oen));
    //ixc013_b16m PAD_SCL (.PAD(i2c_scl), .DIN(1'b0), .OEN(scl_oen), .DOUT(scl_in_c));

    PDUW0204SCDG PAD_GPIO_0 (.I(gpio_out_c[0]), .DS(1'b0) , .OEN(gpio_oen[0]), .PAD(gpio[0]), .C(gpio_in_c[0]), .PE(1'b0), .IE(gpio_oen[0]));
    //ixc013_b16m PAD_GPIO_0 (.PAD(gpio[0]), .DIN(gpio_out_c[0]), .OEN(gpio_oen[0]), .DOUT(gpio_in_c[0]));
    PDUW0204SCDG PAD_GPIO_1 (.I(gpio_out_c[1]), .DS(1'b0) , .OEN(gpio_oen[1]), .PAD(gpio[1]), .C(gpio_in_c[1]), .PE(1'b0), .IE(gpio_oen[1]));
    //ixc013_b16m PAD_GPIO_1 (.PAD(gpio[1]), .DIN(gpio_out_c[1]), .OEN(gpio_oen[1]), .DOUT(gpio_in_c[1]));
    PDUW0204SCDG PAD_GPIO_2 (.I(gpio_out_c[2]), .DS(1'b0) , .OEN(gpio_oen[2]), .PAD(gpio[2]), .C(gpio_in_c[2]), .PE(1'b0), .IE(gpio_oen[2]));
    //ixc013_b16m PAD_GPIO_2 (.PAD(gpio[2]), .DIN(gpio_out_c[2]), .OEN(gpio_oen[2]), .DOUT(gpio_in_c[2]));
    PDUW0204SCDG PAD_GPIO_3 (.I(gpio_out_c[3]), .DS(1'b0) , .OEN(gpio_oen[3]), .PAD(gpio[3]), .C(gpio_in_c[3]), .PE(1'b0), .IE(gpio_oen[3]));
    //ixc013_b16m PAD_GPIO_3 (.PAD(gpio[3]), .DIN(gpio_out_c[3]), .OEN(gpio_oen[3]), .DOUT(gpio_in_c[3]));
    PDUW0204SCDG PAD_GPIO_4 (.I(gpio_out_c[4]), .DS(1'b0) , .OEN(gpio_oen[4]), .PAD(gpio[4]), .C(gpio_in_c[4]), .PE(1'b0), .IE(gpio_oen[4]));
    //ixc013_b16m PAD_GPIO_4 (.PAD(gpio[4]), .DIN(gpio_out_c[4]), .OEN(gpio_oen[4]), .DOUT(gpio_in_c[4]));
    PDUW0204SCDG PAD_GPIO_5 (.I(gpio_out_c[5]), .DS(1'b0) , .OEN(gpio_oen[5]), .PAD(gpio[5]), .C(gpio_in_c[5]), .PE(1'b0), .IE(gpio_oen[5]));
    //ixc013_b16m PAD_GPIO_5 (.PAD(gpio[5]), .DIN(gpio_out_c[5]), .OEN(gpio_oen[5]), .DOUT(gpio_in_c[5]));
    PDUW0204SCDG PAD_GPIO_6 (.I(gpio_out_c[6]), .DS(1'b0) , .OEN(gpio_oen[6]), .PAD(gpio[6]), .C(gpio_in_c[6]), .PE(1'b0), .IE(gpio_oen[6]));
    //ixc013_b16m PAD_GPIO_6 (.PAD(gpio[6]), .DIN(gpio_out_c[6]), .OEN(gpio_oen[6]), .DOUT(gpio_in_c[6]));
    PDUW0204SCDG PAD_GPIO_7 (.I(gpio_out_c[7]), .DS(1'b0) , .OEN(gpio_oen[7]), .PAD(gpio[7]), .C(gpio_in_c[7]), .PE(1'b0), .IE(gpio_oen[7]));
    //ixc013_b16m PAD_GPIO_7 (.PAD(gpio[7]), .DIN(gpio_out_c[7]), .OEN(gpio_oen[7]), .DOUT(gpio_in_c[7]));

    // ----- Core -----
    rvx #(
        .TCM_SIZE_IN_BYTES      (TCM_SIZE_IN_BYTES),
        .TCM_BOOT_IMAGE_PATH    (TCM_BOOT_IMAGE_PATH),
        .SPI_BOOT_IMAGE_ADDRESS (SPI_BOOT_IMAGE_ADDRESS),
        .GPIO_WIDTH             (GPIO_WIDTH),
        .ENABLE_ZMMUL           (ENABLE_ZMMUL)
    ) u_core (
        .clock              (clock_c),
        .reset_n            (reset_n_c),
        .uart_rx            (uart_rx_c),
        .uart_tx            (uart_tx_c),
        .gpio_input         (gpio_in_c),
        .gpio_output_enable (gpio_oe_c),
        .gpio_output        (gpio_out_c),
        .sclk               (sclk_c),
        .mosi               (mosi_c),
        .miso               (miso_c),
        .cs                 (cs_c),
        .i2c_sda_input      (sda_in_c),
        .i2c_scl_input      (scl_in_c),
        .i2c_sda_output     (sda_out_c),
        .i2c_scl_output     (scl_out_c)
    );

endmodule
