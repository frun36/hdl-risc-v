module memory (
    input clk,
    input [31:0] mem_addr,
    input mem_rstrb,
    output reg [31:0] mem_rdata
);


  reg [31:0] mem[0:255];
`ifdef BENCH
  `include "riscv_assembly.v"

  integer L0_ = 8;
  integer wait_ = 32;
  integer L1_ = 40;

  initial begin
    LI(s0, 0);
    LI(s1, 16);
    Label(L0_);
    LB(a0, s0, 400);
    CALL(LabelRef(wait_));
    ADDI(s0, s0, 1);
    BNE(s0, s1, LabelRef(L0_));
    EBREAK();

    Label(wait_);
    LI(t0, 1);
    SLLI(t0, t0, 10);
    Label(L1_);
    ADDI(t0, t0, -1);
    BNEZ(t0, LabelRef(L1_));
    RET();

    endASM();

    mem[100] = {8'h4, 8'h3, 8'h2, 8'h1};
    mem[101] = {8'h8, 8'h7, 8'h6, 8'h5};
    mem[102] = {8'hc, 8'hb, 8'ha, 8'h9};
    mem[103] = {8'hff, 8'h8f, 8'h8e, 8'h8d};
  end
`endif

  always @(posedge clk) if (mem_rstrb) mem_rdata <= mem[mem_addr[31:2]];


endmodule
