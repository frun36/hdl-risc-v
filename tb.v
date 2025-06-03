module tb ();
  reg clk;
  reg rst = 0;
  wire [4:0] leds;
  reg rxd = 1'b0;
  wire txd;

  `include "instruction_decoder.v"
  `include "riscv_disasm.v"


soc uut (
      .clk (clk),
      .rst (rst),
      .leds(leds),
      .rxd (rxd),
      .txd (txd)
  );

`ifdef DEBUG
  always @(posedge clk) begin
    if (!rst & uut.proc.state[2]) begin
      $write("[E] PC=%h ", uut.proc.de_pc);
      $write(" ");
      riscv_disasm(uut.proc.de_instr, uut.proc.de_pc);
      $write("  rs1=0x%h  rs2=0x%h  ", uut.proc.de_rs1, uut.proc.de_rs2);
      $write("  JoB=%d ", uut.proc.jump_or_branch);
      $write("\n");
    end
  end
`endif

  integer i;
  initial begin
    uut.proc.cycle   = 0;
    uut.proc.instret = 0;
    for (i = 0; i < 32; i++) uut.proc.register_bank[i] = 0;
  end

  initial begin
    rst = 0;
    #1 rst = 1;
    #10 rst = 0;
  end

  always @(posedge clk) begin
    if (uut.proc.halt) $finish();
  end

  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end
endmodule

