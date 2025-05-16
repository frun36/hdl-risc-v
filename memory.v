module memory (
    input clk,
    input [31:0] mem_addr,
    output reg [31:0] mem_rdata,
    input mem_rstrb,
    input [31:0] mem_wdata,
    input [3:0] mem_wmask
);


  reg [31:0] mem[0:255];
`ifdef BENCH
  `include "riscv_assembly.v"

  integer L0_ = 12;
  integer L1_ = 40;
  integer wait_ = 64;
  integer L2_ = 72;

  initial begin
    LI(a0, 0);
    // Copy 16 bytes from adress 400
    // to address 800
    LI(s1, 16);
    LI(s0, 0);
    Label(L0_);
    LB(a1, s0, 400);
    SB(a1, s0, 800);
    CALL(LabelRef(wait_));
    ADDI(s0, s0, 1);
    BNE(s0, s1, LabelRef(L0_));

    // Read 16 bytes from adress 800
    LI(s0, 0);
    Label(L1_);
    LB(a0, s0, 800);  // a0 (=x10) is plugged to the LEDs
    CALL(LabelRef(wait_));
    ADDI(s0, s0, 1);
    BNE(s0, s1, LabelRef(L1_));
    EBREAK();

    Label(wait_);
    LI(t0, 1);
    SLLI(t0, t0, 3);
    Label(L2_);
    ADDI(t0, t0, -1);
    BNEZ(t0, LabelRef(L2_));
    RET();

    endASM();

    // Note: index 100 (word address)
    //     corresponds to
    // address 400 (byte address)
    mem[100] = {8'h4, 8'h3, 8'h2, 8'h1};
    mem[101] = {8'h8, 8'h7, 8'h6, 8'h5};
    mem[102] = {8'hc, 8'hb, 8'ha, 8'h9};
    mem[103] = {8'hff, 8'hf, 8'he, 8'hd};
  end
`endif

  wire [29:0] word_addr = mem_addr[31:2];
  always @(posedge clk) begin
    if (mem_rstrb) mem_rdata <= mem[word_addr];
    if (mem_wmask[0]) mem[word_addr][7:0] <= mem_wdata[7:0];
    if (mem_wmask[1]) mem[word_addr][15:8] <= mem_wdata[15:8];
    if (mem_wmask[2]) mem[word_addr][23:16] <= mem_wdata[23:16];
    if (mem_wmask[3]) mem[word_addr][31:24] <= mem_wdata[31:24];
  end


endmodule
