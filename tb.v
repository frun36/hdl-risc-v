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
  // integer j;
  // initial begin
  //   for (j = 'h800; j < 'h1000; j += 4) $display("%h: %h", j, uut.proc.data_ram[j[10:2]]);
  // end
  always @(posedge clk) begin
    if (uut.proc.state[2]) begin
      if (is_alu_reg(uut.proc.de_instr)) begin
        $display("de_pc=%3d: ALUreg", uut.proc.de_pc);
      end else if (is_alu_imm(uut.proc.de_instr)) begin
        $display("de_pc=%3d: ALUimm", uut.proc.de_pc);
      end else if (is_branch(uut.proc.de_instr)) begin
        $display("de_pc=%3d: BRANCH", uut.proc.de_pc);
      end else if (is_jal(uut.proc.de_instr)) begin
        $display("de_pc=%3d: JAL", uut.proc.de_pc);
      end else if (is_jalr(uut.proc.de_instr)) begin
        $display("de_pc=%3d: JALR", uut.proc.de_pc);
      end else if (is_auipc(uut.proc.de_instr)) begin
        $display("de_pc=%3d: AUIPC", uut.proc.de_pc);
      end else if (is_lui(uut.proc.de_instr)) begin
        $display("de_pc=%3d: LUI", uut.proc.de_pc);
      end else if (is_load(uut.proc.de_instr)) begin
        $display("de_pc=%3d: LOAD", uut.proc.de_pc);
      end else if (is_store(uut.proc.de_instr)) begin
        $display("de_pc=%3d: STORE", uut.proc.de_pc);
      end else if (is_system(uut.proc.de_instr)) begin
        $display("de_pc=%3d: SYSTEM", uut.proc.de_pc);
      end else begin
        $display("de_pc=%3d: <unknown>", uut.proc.de_pc);
      end
    end
  end
`endif

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

  reg [4:0] prev_leds = 5'bxxxxx;
  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
      if (prev_leds != leds) begin
        $display("LEDS = %b", leds);
      end

      prev_leds <= leds;
    end
  end
endmodule

