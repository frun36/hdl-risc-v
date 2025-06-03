module soc (
    input clk,
    input rst,
    output reg [4:0] leds,
    input rxd,
    output txd
);

  wire [31:0] io_mem_addr;
  wire [31:0] io_mem_rdata;
  wire [31:0] io_mem_wdata;
  wire        io_mem_wr;


  cpu proc (
      .clk(clk),
      .rst(rst),
      .io_mem_addr(io_mem_addr),
      .io_mem_rdata(io_mem_rdata),
      .io_mem_wdata(io_mem_wdata),
      .io_mem_wr(io_mem_wr)
  );

  wire [13:0] io_wordaddr = io_mem_addr[15:2];

  // memory mapped peripherals
  localparam IO_LEDS_EN_BIT = 0;  // address: 0x00400004
  localparam IO_UART_DAT_BIT = 1;
  localparam IO_UART_CTL_BIT = 2;
  always @(posedge clk) begin
    if (io_mem_wr & io_wordaddr[IO_LEDS_EN_BIT]) begin
      leds <= io_mem_wdata;
`ifdef BENCH
      $display("LEDS: %b", io_mem_wdata[5:0]);
`endif
    end
  end

  wire uart_valid = io_mem_wr & io_wordaddr[IO_UART_DAT_BIT];
  wire uart_ready;

  uart_tx #(
      .CLK_FREQ_HZ(`BOARD_FREQ * 1000000),
      .BAUD_RATE  (115200)
  ) tx (
      .i_clk(clk),
      .i_rst(rst),
      .i_data(io_mem_wdata[7:0]),
      .i_valid(uart_valid),
      .o_ready(uart_ready),
      .o_uart_tx(txd)
  );

  assign io_mem_rdata = io_wordaddr[IO_UART_CTL_BIT] ? {22'b0, !uart_ready, 9'b0} : 32'd0;

`ifdef BENCH
  always @(posedge clk) begin
    if (uart_valid) begin
      $display("UART: %c", io_mem_wdata[7:0]);
    end
  end
`endif
endmodule
