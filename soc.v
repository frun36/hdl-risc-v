module soc (
    input clk,
    input rst,
    output reg [4:0] leds,
    input rxd,
    output txd
);

  wire [31:0] mem_addr;
  wire [31:0] mem_rdata;
  wire [31:0] mem_wdata;
  wire [3:0] mem_wmask;
  wire mem_rstrb;

  cpu proc (
      .clk(clk),
      .rst(rst),
      .mem_addr(mem_addr),
      .mem_rstrb(mem_rstrb),
      .mem_rdata(mem_rdata),
      .mem_wdata(mem_wdata),
      .mem_wmask(mem_wmask)
  );

  wire [31:0] ram_rdata;
  wire [29:0] mem_wordaddr = mem_addr[31:2];
  wire is_io = mem_addr[22];
  wire is_ram = !is_io;
  wire mem_wstrb = |mem_wmask;

  memory ram (
      .clk(clk),
      .mem_addr(mem_addr),
      .mem_rstrb(is_ram & mem_rstrb),
      .mem_rdata(ram_rdata),
      .mem_wdata(mem_wdata),
      .mem_wmask({4{is_ram}} & mem_wmask)
  );

  // memory mapped peripherals
  localparam IO_LEDS_EN_BIT = 0;  // address: 0x00400004
  localparam IO_UART_DAT_BIT = 1;
  localparam IO_UART_CTL_BIT = 2;
  always @(posedge clk) begin
    if (is_io & mem_wstrb & mem_wordaddr[IO_LEDS_EN_BIT]) begin
      leds <= mem_wdata;
    end
  end

  wire uart_valid = is_io & mem_wstrb & mem_wordaddr[IO_UART_DAT_BIT];
  wire uart_ready;

  uart_tx #(
      .CLK_FREQ_HZ(`BOARD_FREQ * 1000000),
      .BAUD_RATE  (115200)
  ) tx (
      .i_clk(clk),
      .i_rst(rst),
      .i_data(mem_wdata[7:0]),
      .i_valid(uart_valid),
      .o_ready(uart_ready),
      .o_uart_tx(txd)
  );

  wire [31:0] io_rdata = mem_wordaddr[IO_UART_CTL_BIT] ? {22'b0, !uart_ready, 9'b0} : 32'd0;

  assign mem_rdata = is_ram ? ram_rdata : io_rdata;

`ifdef BENCH
  always @(posedge clk) begin
    if (uart_valid) begin
      $write("%c", mem_wdata[7:0]);
      $fflush(32'h8000_0001);
    end
  end
`endif
endmodule
