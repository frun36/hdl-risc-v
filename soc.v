module soc (
    input clk,
    input rst,
    output [4:0] leds,
    input rxd,
    output txd
);

  wire [31:0] mem_addr;
  wire [31:0] mem_rdata;
  wire mem_rstrb;
  wire [31:0] x10;

  cpu proc (
      .clk(clk),
      .rst(rst),
      .mem_addr(mem_addr),
      .mem_rstrb(mem_rstrb),
      .mem_rdata(mem_rdata),
      .x10(x10)
  );

  memory mem (
      .clk(clk),
      .mem_addr(mem_addr),
      .mem_rstrb(mem_rstrb),
      .mem_rdata(mem_rdata)
  );

  assign leds = x10[4:0];

endmodule
