module cpu (
    input clk,
    input rst,
    output [31:0] io_mem_addr,
    input [31:0] io_mem_rdata,
    output [31:0] io_mem_wdata,
    output io_mem_wr
);
  `include "instruction_decoder.v"

  // --- State machine ---
  localparam F_BIT = 0;
  localparam D_BIT = 1;
  localparam E_BIT = 2;
  localparam M_BIT = 3;
  localparam W_BIT = 4;

  reg [4:0] state;
  reg       halt;

  always @(posedge clk) begin
    if (rst) begin
      halt  <= 0;
      state <= (1 << F_BIT);
    end else if (!halt) begin
      state <= {state[3:0], state[4]};
    end
  end
  reg [63:0] cycle;
  reg [63:0] instret;

  always @(posedge clk) begin
    cycle <= rst ? 0 : cycle + 1;
  end

  localparam NOP = 32'b0000000_00000_00000_000_00000_0110011;

  // --- 1. Instruction fetch (F) ---
  (* ram_style = "block" *)
  reg [31:0] prog_rom[0:511];
  initial begin
    $readmemh("programs/target/prog_rom.mem", prog_rom);
  end

  reg [31:0] f_pc;

  // from the execute stage
  wire [31:0] jump_or_branch_address;
  wire jump_or_branch;

  always @(posedge clk) begin
    if (rst) begin
      f_pc <= 0;
    end else if (state[F_BIT]) begin
      fd_instr <= prog_rom[f_pc[10:2]];
      fd_pc    <= f_pc;
      f_pc     <= f_pc + 4;
    end else if (state[M_BIT] & jump_or_branch) begin
      f_pc <= jump_or_branch_address;
    end
  end

  reg  [31:0] fd_pc;
  reg  [31:0] fd_instr;

  // --- 2. Instruction decode (D) ---
  (* ram_style="block" *)
  reg  [31:0] register_bank[0:31];

  wire        wb_enable;
  wire [31:0] wb_data;
  wire [ 4:0] wb_rd_id;

  always @(posedge clk) begin
    if (state[D_BIT]) begin
      de_pc    <= fd_pc;
      de_instr <= fd_instr;
      de_rs1 <= register_bank[rs1_id(fd_instr)];
      de_rs2 <= register_bank[rs2_id(fd_instr)];
    end
  end

  always @(posedge clk) begin
    if (wb_enable) begin
      register_bank[wb_rd_id] <= wb_data;
    end
  end

  reg [31:0] de_pc;
  reg [31:0] de_instr;
  reg [31:0] de_rs1;
  reg [31:0] de_rs2;

  // --- 3. Execute (E) ---
  wire [31:0] e_alu_out;
  wire [31:0] e_alu_plus;
  wire e_take_branch;
  alu a (
      .alu_in_1(de_rs1),
      .alu_in_2(is_alu_reg(de_instr) | is_branch(de_instr) ? de_rs2 : i_imm(de_instr)),
      .instr(de_instr),
      .alu_out(e_alu_out),
      .alu_plus(e_alu_plus),
      .take_branch(e_take_branch)
  );

  wire e_jump_or_branch = (is_jal(
      de_instr
  ) || is_jalr(
      de_instr
  ) || (is_branch(
      de_instr
  ) && e_take_branch));

  wire [31:0] e_jump_or_branch_addr = is_branch(
      de_instr
  ) ? de_pc + b_imm(
      de_instr
  ) : is_jal(
      de_instr
  ) ? de_pc + j_imm(
      de_instr
  ) : {e_alu_plus[31:1], 1'b0};

  wire [31:0] e_result = (is_jal(
      de_instr
  ) | is_jalr(
      de_instr
  )) ? de_pc + 4 : is_lui(
      de_instr
  ) ? u_imm(
      de_instr
  ) : is_auipc(
      de_instr
  ) ? de_pc + u_imm(
      de_instr
  ) : e_alu_out;

  always @(posedge clk) begin
    if (state[E_BIT]) begin
      em_pc       <= de_pc;
      em_instr    <= de_instr;
      em_rs2      <= de_rs2;
      em_e_result <= e_result;
      em_addr     <= is_store(de_instr) ? de_rs1 + s_imm(de_instr) : de_rs1 + i_imm(de_instr);
    end
  end

  always @* halt <= !rst & is_ebreak(de_instr);

  reg [31:0] em_pc;
  reg [31:0] em_instr;
  reg [31:0] em_rs2;
  reg [31:0] em_e_result;
  reg [31:0] em_addr;

  // --- 4. Memory (M) ---
  wire [2:0] m_funct3 = funct3(em_instr);
  wire m_is_b = (m_funct3[1:0] == 2'b00);
  wire m_is_h = (m_funct3[1:0] == 2'b01);

  wire [31:0] m_store_data;
  assign m_store_data[7:0] = em_rs2[7:0];
  assign m_store_data[15:8] = em_addr[0] ? em_rs2[7:0] : em_rs2[15:8];
  assign m_store_data[23:16] = em_addr[1] ? em_rs2[7:0] : em_rs2[23:16];
  assign m_store_data[31:24] = em_addr[0] ? em_rs2[7:0] : em_addr[1] ? em_rs2[15:8] : em_rs2[31:24];

  wire [3:0] m_store_wmask = m_is_b ? (em_addr[1] ?
                (em_addr[0] ? 4'b1000 : 4'b0100) :
                (em_addr[0] ? 4'b0010 : 4'b0001)) :
                     m_is_h ? (em_addr[1] ? 4'b1100 : 4'b0011) : 4'b1111;

  (* ram_style = "block" *)
  reg [31:0] data_ram[0:511];
  initial begin
    $readmemh("programs/target/data_ram.mem", data_ram);
  end

  wire m_is_io = em_addr[22];
  wire m_is_ram = !m_is_io;

  assign io_mem_addr = em_addr;
  assign io_mem_wr = state[M_BIT] & is_store(em_instr) && m_is_io;
  assign io_mem_wdata = em_rs2;

  wire [ 3:0] m_wmask = {4{is_store(em_instr) & m_is_ram & state[M_BIT]}} & m_store_wmask;

  wire [ 8:0] m_word_addr = em_addr[10:2];

  reg  [31:0] data_ram_rdata;
  wire [ 3:0] data_ram_wmask = m_wmask & {4{m_is_ram}};
  always @(posedge clk) begin
    mw_m_data <= data_ram[m_word_addr];
    if (m_wmask[0]) data_ram[m_word_addr][7:0] <= m_store_data[7:0];
    if (m_wmask[1]) data_ram[m_word_addr][15:8] <= m_store_data[15:8];
    if (m_wmask[2]) data_ram[m_word_addr][23:16] <= m_store_data[23:16];
    if (m_wmask[3]) data_ram[m_word_addr][31:24] <= m_store_data[31:24];
  end

  always @(posedge clk) begin
    if (state[M_BIT]) begin
      mw_pc        <= em_pc;
      mw_instr     <= em_instr;
      mw_e_result  <= em_e_result;
      mw_io_result <= io_mem_rdata;
      mw_addr      <= em_addr;
      case (csr_id(
          em_instr
      ))
        2'b00: mw_csr_result = cycle[31:0];
        2'b10: mw_csr_result = cycle[63:32];
        2'b01: mw_csr_result = instret[31:0];
        2'b11: mw_csr_result = instret[63:32];
      endcase
      if (rst) begin
        instret <= 0;
      end else begin
        instret <= instret + 1;
      end
    end
  end


  reg [31:0] mw_pc;
  reg [31:0] mw_instr;
  reg [31:0] mw_e_result;
  reg [31:0] mw_addr;
  reg [31:0] mw_m_data;
  reg [31:0] mw_io_result;
  reg [31:0] mw_csr_result;

  // --- 5. Write back (W) ---
  wire [2:0] w_funct3 = funct3(mw_instr);
  wire w_is_b = (w_funct3[1:0] == 2'b00);
  wire w_is_h = (w_funct3[1:0] == 2'b01);
  wire w_sext = !w_funct3[2];
  wire w_is_io = mw_addr[22];

  wire [15:0] w_load_h = mw_addr[1] ? mw_m_data[31:16] : mw_m_data[15:0];
  wire [7:0] w_load_b = mw_addr[0] ? w_load_h[15:8] : w_load_h[7:0];
  wire w_load_sign = w_sext & (w_is_b ? w_load_b[7] : w_load_h[15]);

  wire [31:0] w_m_result = w_is_b ? {{24{w_load_sign}},w_load_b} :
                   w_is_h ? {{16{w_load_sign}}, w_load_h} : mw_m_data ;

  assign wb_data = is_load(
      mw_instr
  ) ? (w_is_io ? mw_io_result : w_m_result) : is_csrrs(
      mw_instr
  ) ? mw_csr_result : mw_e_result;

  assign wb_enable = !is_branch(mw_instr) && !is_store(mw_instr) && (rd_id(mw_instr) != 0);

  assign wb_rd_id = rd_id(mw_instr);

  assign jump_or_branch_address = e_jump_or_branch_addr;
  assign jump_or_branch = e_jump_or_branch;
endmodule

