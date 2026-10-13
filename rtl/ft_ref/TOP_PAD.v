
module TOP_PAD (
     clock, reset_n,
     uart_rx, uart_tx,
     rep_uart_rx, rep_uart_tx,
     sclk, mosi, miso, cs,
     i2c_sda_inout, i2c_scl_inout,
     gpio_inout
);

     input clock, reset_n, uart_rx, rep_uart_rx, miso;
     //input [7:0] gpio_input;
     output uart_tx, rep_uart_tx, sclk, mosi, cs;
     //output [7:0] gpio_output_enable, gpio_output;
     inout [7:0] gpio_inout;
     inout i2c_sda_inout, i2c_scl_inout;

     wire clock_I, reset_n_I, uart_rx_I, rep_uart_rx_I, miso_I, i2c_sda_input_I, i2c_scl_input_I;
     wire [7:0] gpio_input_I;
     wire uart_tx_O, rep_uart_tx_O, sclk_O, mosi_O, cs_O, i2c_sda_output_O, i2c_scl_output_O;
     wire [7:0] gpio_output_enable_O, gpio_output_O;

     wire i2c_sda_oe = ~i2c_sda_output_O;
     wire i2c_scl_oe = ~i2c_scl_output_O;
     wire [7:0] gpio_ie = ~gpio_output_enable_O;

     wire vddio, vssio, vdd, vss;

     rvx_ecc #(
    .TCM_SIZE_IN_BYTES(1024),
    .SPI_BOOT_IMAGE_ADDRESS (32'h00000000),
    .GPIO_WIDTH(8),
    .ENABLE_ZMMUL(1),
    .CLK_FREQ(38461538)
) uut (
         .clock(clock_I), .reset_n(reset_n_I), .uart_rx(uart_rx_I), .rep_uart_rx(rep_uart_rx_I), .uart_tx(uart_tx_O), .rep_uart_tx(rep_uart_tx_O),
         .gpio_input(gpio_input_I),.gpio_output_enable(gpio_output_enable_O), .gpio_output(gpio_output_O), .sclk(sclk_O), .mosi(mosi_O), .miso(miso_I),
         .cs(cs_O), .i2c_sda_input(i2c_sda_input_I), .i2c_scl_input(i2c_scl_input_I), .i2c_sda_output(i2c_sda_output_O), .i2c_scl_output(i2c_scl_output_O)
     );


     //Clock/RST
     //PIC PAD_clock(.P(clock), .Y(clock_I),.IE(1'b1));
     POSC4 CLK_PAD(.CK(clock_I), .E0(1'b0), .E1(1'b1), .PI(clock), .PO());


     PIC PAD_reset_n(.P(reset_n), .Y(reset_n_I),.IE(1'b1));

     //INPUT
     PIC PAD_uart_rx(.P(uart_rx), .Y(uart_rx_I),.IE(1'b1));
     PIC PAD_rep_uart_rx(.P(rep_uart_rx), .Y(rep_uart_rx_I),.IE(1'b1));
     PIC PAD_miso(.P(miso), .Y(miso_I), .IE(1'b1));


     //OUTPUT
     POCT2A PAD_uart_tx(.P(uart_tx),.A(uart_tx_O),.OE(1'b1));
     POCT2A PAD_rep_uart_tx(.P(rep_uart_tx),.A(rep_uart_tx_O),.OE(1'b1));
     POCT2A PAD_sclk(.P(sclk),.A(sclk_O),.OE(1'b1));
     POCT2A PAD_mosi(.P(mosi),.A(mosi_O),.OE(1'b1));
     POCT2A PAD_cs(.P(cs),.A(cs_O),.OE(1'b1));

     // I/O
     PBCCT2A PAD_sda_inout(.P(i2c_sda_inout), .Y(i2c_sda_input_I), .A(i2c_sda_output_O), .OE(i2c_sda_oe), .IE(1'b1));
     PBCCT2A PAD_scl_inout(.P(i2c_scl_inout), .Y(i2c_scl_input_I), .A(i2c_scl_output_O), .OE(i2c_scl_oe), .IE(1'b1));

     PBCCT2A PAD_gpio_inout_0(.P(gpio_inout[0]), .Y(gpio_input_I[0]) , .A(gpio_output_O[0]), .OE(gpio_output_enable_O[0]), .IE(gpio_ie[0]));
     PBCCT2A PAD_gpio_inout_1(.P(gpio_inout[1]), .Y(gpio_input_I[1]) , .A(gpio_output_O[1]), .OE(gpio_output_enable_O[1]), .IE(gpio_ie[1]));
     PBCCT2A PAD_gpio_inout_2(.P(gpio_inout[2]), .Y(gpio_input_I[2]) , .A(gpio_output_O[2]), .OE(gpio_output_enable_O[2]), .IE(gpio_ie[2]));
     PBCCT2A PAD_gpio_inout_3(.P(gpio_inout[3]), .Y(gpio_input_I[3]) , .A(gpio_output_O[3]), .OE(gpio_output_enable_O[3]), .IE(gpio_ie[3]));
     PBCCT2A PAD_gpio_inout_4(.P(gpio_inout[4]), .Y(gpio_input_I[4]) , .A(gpio_output_O[4]), .OE(gpio_output_enable_O[4]), .IE(gpio_ie[4]));
     PBCCT2A PAD_gpio_inout_5(.P(gpio_inout[5]), .Y(gpio_input_I[5]) , .A(gpio_output_O[5]), .OE(gpio_output_enable_O[5]), .IE(gpio_ie[5]));
     PBCCT2A PAD_gpio_inout_6(.P(gpio_inout[6]), .Y(gpio_input_I[6]) , .A(gpio_output_O[6]), .OE(gpio_output_enable_O[6]), .IE(gpio_ie[6]));
     PBCCT2A PAD_gpio_inout_7(.P(gpio_inout[7]), .Y(gpio_input_I[7]) , .A(gpio_output_O[7]), .OE(gpio_output_enable_O[7]), .IE(gpio_ie[7]));
endmodule
