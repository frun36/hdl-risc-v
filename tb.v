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
  integer j;
  initial begin
    for (j = 'h800; j < 'h1000; j += 4) $display("%h: %h", j, uut.proc.data_ram[j[10:2]]);
  end
  always @(posedge clk) begin
    if (uut.proc.state == 2) begin
      if (uut.proc.is_alu_reg)
        $display(
            "PC=%3d: ALUreg rd=%2h rs1=%2h:%h rs2=%2h:%h funct3=%b",
            uut.proc.pc,
            uut.proc.rd_id,
            uut.proc.rs1_id,
            uut.proc.rs1,
            uut.proc.rs2_id,
            uut.proc.rs2,
            uut.proc.funct3
        );
      else if (uut.proc.is_alu_imm)
        $display(
            "PC=%3d: ALUimm rd=%2h rs1=%2h:%h imm=%h funct3=%b",
            uut.proc.pc,
            uut.proc.rd_id,
            uut.proc.rs1_id,
            uut.proc.rs1,
            uut.proc.i_imm,
            uut.proc.funct3
        );
      else if (uut.proc.is_branch)
        $display(
            "PC=%3d: BRANCH eq=%b lt=%b ltu=%b take=%b",
            uut.proc.pc,
            uut.proc.eq,
            uut.proc.lt,
            uut.proc.ltu,
            uut.proc.take_branch
        );
      else if (uut.proc.is_jal) begin
        $display("PC=%3d: JAL rd=%2h j_imm=%0d target=%h", uut.proc.pc, uut.proc.rd_id,
                 uut.proc.j_imm, uut.proc.pc + uut.proc.j_imm);
      end else if (uut.proc.is_jalr) begin
        $display("PC=%3d: JALR rd=%2h rs1=%2h:%h i_imm=%0d target=%h", uut.proc.pc, uut.proc.rd_id,
                 uut.proc.rs1_id, uut.proc.rs1, uut.proc.i_imm,
                 (uut.proc.rs1 + uut.proc.i_imm) & ~1);
      end else if (uut.proc.is_auipc) begin
        $display("PC=%3d: AUIPC rd=%2h u_imm=%h result=%h", uut.proc.pc, uut.proc.rd_id,
                 uut.proc.u_imm, uut.proc.pc + uut.proc.u_imm);
      end else if (uut.proc.is_lui) begin
        $display("PC=%3d: LUI rd=%2h u_imm=%0d", uut.proc.pc, uut.proc.rd_id, uut.proc.u_imm);
      end else if (uut.proc.is_load) begin
        // Assumes you have:       uut.proc.rd_id     (destination register)
        //                        uut.proc.rs1_id    (base register)
        //                        uut.proc.rs1       (value of rs1)
        //                        uut.proc.i_imm     (I‐type immediate / offset)
        //                        uut.proc.is_io     (flag → memory or I/O space)
        //                        uut.proc.mem_addr  (raw address)
        //                        uut.proc.mem_word_addr (aligned word address)
        //                        uut.proc.mem_rdata (data read back from memory)
        //                        uut.proc.funct3    (to know byte/half/word, signed/unsigned)
        $display(
            "PC=%3d: LOAD rd=%2h rs1=%2h:%h imm=%h funct3=%b is_io=%b raw_addr=%h word_addr=%h",
            uut.proc.pc, uut.proc.rd_id, uut.proc.rs1_id, uut.proc.rs1, uut.proc.i_imm,
            uut.proc.funct3, uut.proc.is_io, uut.proc.mem_addr, uut.proc.mem_word_addr);
      end else if (uut.proc.is_store) begin
        $display(
            "PC=%3d: STORE rs1=%2h:%h rs2=%2h:%h imm=%h funct3=%b is_io=%b raw_addr=%h word_addr=%h wdata=%h wmask=%b",
            uut.proc.pc, uut.proc.rs1_id, uut.proc.rs1, uut.proc.rs2_id, uut.proc.rs2,
            uut.proc.s_imm, uut.proc.funct3, uut.proc.is_io, uut.proc.mem_addr,
            uut.proc.mem_word_addr, uut.proc.mem_wdata, uut.proc.mem_wmask);
      end else if (uut.proc.is_system) begin
        $display("PC=%3d: SYSTEM funct3=%b", uut.proc.pc, uut.proc.funct3);
      end else begin
        $display("PC=%3d: <unknown instruction class>", uut.proc.pc);
      end
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

