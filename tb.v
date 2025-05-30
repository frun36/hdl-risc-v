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

  always @(posedge clk) begin
    if (uut.proc.state == 2) begin
      $display("PC=%0d", uut.proc.pc);
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
      else if (uut.proc.is_branch) $display("BRANCH");
      else if (uut.proc.is_jal) $display("JAL");
      else if (uut.proc.is_jalr) $display("JALR");
      else if (uut.proc.is_auipc) $display("AUIPC");
      else if (uut.proc.is_lui) $display("LUI");
      else if (uut.proc.is_load) $display("LOAD");
      else if (uut.proc.is_store) $display("STORE");
      else if (uut.proc.is_system) $display("SYSTEM");
    end
  end

  // initial begin
  //   rst = 0;
  //   #2 rst = 1;
  //   #2 rst = 0;
  // end

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

