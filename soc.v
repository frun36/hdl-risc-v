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
  cpu proc (.*);
  memory mem (.*);


endmodule
