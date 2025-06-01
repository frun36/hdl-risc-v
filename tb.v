module tb ();
  reg clk;
  reg rst = 0;
  wire [4:0] leds;
  reg rxd = 1'b0;
  wire txd;

  soc uut (
      .clk (clk),
      .rst (rst),
      .leds(leds),
      .rxd (rxd),
      .txd (txd)
  );

`ifdef DEBUG
  always @(posedge clk) begin
    if (uut.proc.state == 2) begin
      // $display("%b", uut.proc.register_bank[5]);
      $display("PC=%3d rd %2d rs1 %h:%b rs2 %h:%b", uut.proc.pc, uut.proc.rd_id, uut.proc.rs1_id,
               uut.proc.rs1, uut.proc.rs2_id, uut.proc.rs2);
      if (uut.proc.is_alu_reg)
        $display(
            "ALUreg rd=%d rs1=%d rs2=%d funct3=%b",
            uut.proc.rd_id,
            uut.proc.rs1_id,
            uut.proc.rs2_id,
            uut.proc.funct3
        );
      else if (uut.proc.is_alu_imm)
        $display(
            "ALUimm rd=%d rs1=%d imm=%0d funct3=%b",
            uut.proc.rd_id,
            uut.proc.rs1_id,
            uut.proc.i_imm,
            uut.proc.funct3
        );
      else if (uut.proc.is_branch)
        $display(
            "BRANCH eq %b lt %b ltu %b take %b",
            uut.proc.eq,
            uut.proc.lt,
            uut.proc.ltu,
            uut.proc.take_branch
        );
      else if (uut.proc.is_jal) $display("JAL");
      else if (uut.proc.is_jalr) $display("JALR");
      else if (uut.proc.is_auipc) $display("AUIPC");
      else if (uut.proc.is_lui) $display("LUI imm=%0d", uut.proc.j_imm);
      else if (uut.proc.is_load)
        $display(
            "LOAD is_io=%h raw_addr=%h word_addr=%h",
            uut.proc.is_io,
            uut.proc.mem_addr,
            uut.proc.mem_word_addr
        );
      else if (uut.proc.is_store)
        $display(
            "STORE is_io=%h raw_addr=%h word_addr=%h, wdata=%h, wmask=%b",
            uut.proc.is_io,
            uut.proc.mem_addr,
            uut.proc.mem_word_addr,
            uut.proc.mem_wdata,
            uut.proc.mem_wmask
        );
      else if (uut.proc.is_system) $display("SYSTEM");
      $display("");
    end
  end
`endif

  integer i;
  initial begin
    uut.proc.pc = 0;
    uut.proc.cycle = 0;
    uut.proc.instret = 0;
    for (i = 0; i < 32; i++) uut.proc.register_bank[i] = 0;

    uut.proc.register_bank[2] = 32'h1000;
  end

  initial begin
    rst = 0;
    #1 rst = 1;
    #10 rst = 0;
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

