module soc (
    input clk,
    input rst,
    output [4:0] leds,
    input rxd,
    output txd
);

  wire [31:0] mem_addr;
  wire [31:0] mem_rdata;
  wire [31:0] mem_wdata;
  wire [3:0] mem_wmask;
  wire mem_rstrb;
  wire [31:0] x10;

  cpu proc (
      .clk(clk),
      .rst(rst),
      .mem_addr(mem_addr),
      .mem_rstrb(mem_rstrb),
      .mem_rdata(mem_rdata),
      .mem_wdata(mem_wdata),
      .mem_wmask(mem_wmask),
      .x10(x10)
  );

  memory mem (
      .clk(clk),
      .mem_addr(mem_addr),
      .mem_rstrb(mem_rstrb),
      .mem_rdata(mem_rdata),
      .mem_wdata(mem_wdata),
      .mem_wmask(mem_wmask)
  );

  assign leds = x10[4:0];

endmodule
