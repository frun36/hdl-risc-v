module soc (
    input clk,
    input rst,
    output [4:0] leds,
    input rxd,
    output txd
);
  reg [31:0] pc;
  reg [31:0] instr;

  // --- instruction decoder ---
  wire is_alu_reg = (instr[6:0] == 7'b0110011);  // rd <- rs1 OP rs2
  wire is_alu_imm = (instr[6:0] == 7'b0010011);  // rd <- rs1 OP Iimm
  wire is_branch = (instr[6:0] == 7'b1100011);  // if(rs1 OP rs2) PC<-PC+Bimm
  wire is_jalr = (instr[6:0] == 7'b1100111);  // rd <- PC+4; PC<-rs1+Iimm
  wire is_jal = (instr[6:0] == 7'b1101111);  // rd <- PC+4; PC<-PC+Jimm
  wire is_auipc = (instr[6:0] == 7'b0010111);  // rd <- PC + Uimm
  wire is_lui = (instr[6:0] == 7'b0110111);  // rd <- Uimm
  wire is_load = (instr[6:0] == 7'b0000011);  // rd <- mem[rs1+Iimm]
  wire is_store = (instr[6:0] == 7'b0100011);  // mem[rs1+Simm] <- rs2
  wire is_system = (instr[6:0] == 7'b1110011);  // special

`ifdef BENCH
  always @(posedge clk) begin
    if (state == EXECUTE) begin
      $display("PC=%0d", pc);
      if (is_alu_reg)
        $display("ALUreg rd=%d rs1=%d rs2=%d funct3=%b", rd_id, rs1_id, rs2_id, funct3);
      else if (is_alu_imm)
        $display("ALUimm rd=%d rs1=%d imm=%0d funct3=%b", rd_id, rs1_id, i_imm, funct3);
      else if (is_branch) $display("BRANCH");
      else if (is_jal) $display("JAL");
      else if (is_jalr) $display("JALR");
      else if (is_auipc) $display("AUIPC");
      else if (is_lui) $display("LUI");
      else if (is_load) $display("LOAD");
      else if (is_store) $display("STORE");
      else if (is_system) $display("SYSTEM");
    end
  end
`endif

  // Source and destination registers
  wire [4:0] rs1_id = instr[19:15];
  wire [4:0] rs2_id = instr[24:20];
  wire [4:0] rd_id = instr[11:7];

  // Function codes
  wire [2:0] funct3 = instr[14:12];
  wire [6:0] funct7 = instr[31:25];

  // The register bank
  wire [31:0] u_imm = {instr[31], instr[30:12], {12{1'b0}}};
  wire [31:0] i_imm = {{21{instr[31]}}, instr[30:20]};
  wire [31:0] s_imm = {{21{instr[31]}}, instr[30:25], instr[11:7]};
  wire [31:0] b_imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
  wire [31:0] j_imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

  // --- FSM ---
  reg [31:0] register_bank[0:31];
  reg [31:0] rs1;
  reg [31:0] rs2;

`ifdef BENCH
  integer i;
  initial begin
    for (i = 0; i < 32; i++) register_bank[i] = 0;

  end
`endif

  localparam FETCH_INSTR = 0;
  localparam FETCH_REGS = 1;
  localparam EXECUTE = 2;
  reg [1:0] state = FETCH_INSTR;

  wire [31:0] write_back_data;
  wire write_back_en;

  always @(posedge rst, posedge clk) begin
    if (rst) begin
      pc <= 0;
      state <= FETCH_INSTR;
      instr <= 32'b00000000000000000000000000110011;
    end else begin
      if (write_back_en && rd_id != 0) begin
        register_bank[rd_id] <= write_back_data;

`ifdef BENCH
        $display("x%0d <= %b", rd_id, write_back_data);
`endif
      end

      case (state)
        FETCH_INSTR: begin
          instr <= mem[pc[31:2]];
          state <= FETCH_REGS;
        end
        FETCH_REGS: begin
          rs1   <= register_bank[rs1_id];
          rs2   <= register_bank[rs2_id];
          state <= EXECUTE;
        end
        EXECUTE: begin
          if (!is_system) pc <= next_pc;
          state <= FETCH_INSTR;
`ifdef BENCH
          if (is_system) $finish();
`endif
        end
      endcase
    end
  end

  // --- ALU ---
  wire [31:0] alu_in_1 = rs1;
  wire [31:0] alu_in_2 = is_alu_reg ? rs2 : i_imm;
  reg  [31:0] alu_out;
  wire [ 4:0] shamt = is_alu_reg ? rs2[4:0] : instr[24:20];
  always @(*) begin
    case (funct3)
      3'b000: alu_out = (funct7[5] & instr[5]) ? (alu_in_1 - alu_in_2) : (alu_in_1 + alu_in_2);
      3'b001: alu_out = (alu_in_1 << shamt);
      3'b010: alu_out = ($signed(alu_in_1) < $signed(alu_in_2));
      3'b011: alu_out = (alu_in_1 < alu_in_2);
      3'b100: alu_out = (alu_in_1 ^ alu_in_2);
      3'b101: alu_out = funct7[5] ? ($signed(alu_in_1) >>> shamt) : (alu_in_1 >> shamt);
      3'b110: alu_out = (alu_in_1 | alu_in_2);
      3'b111: alu_out = (alu_in_1 & alu_in_2);
    endcase
  end

  reg take_branch;
  always @(*) begin
    case (funct3)
      3'b000:  take_branch = (rs1 == rs2);
      3'b001:  take_branch = (rs1 != rs2);
      3'b100:  take_branch = ($signed(rs1) < $signed(rs2));
      3'b101:  take_branch = ($signed(rs1) >= $signed(rs2));
      3'b110:  take_branch = rs1 < rs2;
      3'b111:  take_branch = rs1 >= rs2;
      default: take_branch = 1'b0;
    endcase
  end

  wire [31:0] next_pc = (is_branch && take_branch) ? pc + b_imm
      : is_jal ? pc + j_imm
      : is_jalr ? rs1 + i_imm
      : pc + 4;
  assign write_back_data = (is_jal || is_jalr) ? (pc + 4)
      : (is_lui) ? u_imm
      : (is_auipc) ? (pc + u_imm)
      : alu_out;
  assign write_back_en =
      (state == EXECUTE && (is_alu_reg || is_alu_imm || is_jal || is_jalr || is_lui || is_auipc));



endmodule
