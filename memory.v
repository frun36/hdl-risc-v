module memory (
    input clk,
    input [31:0] mem_addr,
    input mem_rstrb,
    output reg [31:0] mem_rdata
);

  `include "riscv_assembly.v"

  reg [31:0] mem[0:255];
`ifdef BENCH
  integer L0 = 8;
  initial begin
    ADD(x1, x0, x0);
    ADDI(x2, x0, 32);
    Label(L0);
    ADDI(x1, x1, 1);
    BNE(x1, x2, LabelRef(L0));
    LUI(x1, 32'b11111111111111111111111111111111);
    ORI(x1, x1, 32'b11111111111111111111111111111111);
    EBREAK();
    endASM();
  end
`endif

  always @(posedge clk) if (mem_rstrb) mem_rdata <= mem[mem_addr[31:2]];


endmodule
