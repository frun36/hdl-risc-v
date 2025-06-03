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
  localparam NOP = 32'b0000000_00000_00000_000_00000_0110011;

  always @(posedge clk) begin
    if (!rst) begin
      $display("");

      $write("[W] pc=%h ", uut.proc.mw_pc);
      $write("     ");
      riscv_disasm(uut.proc.mw_instr, uut.proc.mw_pc);
      if (uut.proc.wb_enable)
        $write("    x%0d <- 0x%0h", rd_id(uut.proc.mw_instr), uut.proc.wb_data);
      $write("\n");

      $write("[M] pc=%h ", uut.proc.em_pc);
      $write("     ");
      riscv_disasm(uut.proc.em_instr, uut.proc.em_pc);
      $write("\n");

      $write("[E] pc=%h ", uut.proc.de_pc);
      $write("     ");
      riscv_disasm(uut.proc.de_instr, uut.proc.de_pc);
      if (uut.proc.de_instr != NOP) begin
        $write("  rs1=0x%h  rs2=0x%h  ", uut.proc.de_rs1, uut.proc.de_rs2);
      end
      $write("\n");

      $write("[D] pc=%h ", uut.proc.fd_pc);
      $write("[%s%s] ", uut.proc.rs1_hazard ? "*" : " ", uut.proc.rs2_hazard ? "*" : " ");
      riscv_disasm(uut.proc.fd_nop ? NOP : uut.proc.fd_instr, uut.proc.fd_pc);
      $write("\n");

      $write("[F] pc=%h ", uut.proc.f_pc);
      if (uut.proc.jump_or_branch) $write(" pc <- 0x%0h", uut.proc.jump_or_branch_address);
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

