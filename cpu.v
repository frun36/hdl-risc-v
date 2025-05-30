module cpu (
    input clk,
    input rst,
    output [31:0] io_mem_addr,
    input [31:0] io_mem_rdata,
    output [31:0] io_mem_wdata,
    output io_mem_wr
);
  // --- Memory ---
  (* ram_style = "block" *)
  reg [31:0] prog_rom[0:511];
  (* ram_style = "block" *)
  reg [31:0] data_ram[0:511];
  initial begin
    $readmemh("programs/target/prog_rom.mem", prog_rom);
    $readmemh("programs/target/data_ram.mem", data_ram);
  end

  wire [31:0] mem_addr;
  wire [31:0] mem_rdata;
  wire [31:0] mem_wdata;
  wire [3:0] mem_wmask;

  wire is_io = mem_addr[22];
  wire is_ram = !is_io;

  // wire [13:0] mem_word_addr = mem_addr[15:2];
  wire [6:0] mem_word_addr = mem_addr[8:2];

  // RAM access
  reg [31:0] data_ram_rdata;
  wire [3:0] data_ram_wmask = mem_wmask & {4{is_ram}};
  always @(posedge clk) begin
    data_ram_rdata <= data_ram[mem_word_addr];
    if (data_ram_wmask[0]) data_ram[mem_word_addr][7:0] <= mem_wdata[7:0];
    if (data_ram_wmask[1]) data_ram[mem_word_addr][15:8] <= mem_wdata[15:8];
    if (data_ram_wmask[2]) data_ram[mem_word_addr][23:16] <= mem_wdata[23:16];
    if (data_ram_wmask[3]) data_ram[mem_word_addr][31:24] <= mem_wdata[31:24];
  end

  assign mem_rdata = is_ram ? data_ram_rdata : io_mem_rdata;
  assign io_mem_addr = mem_addr;
  assign io_mem_wdata = mem_wdata;
  assign io_mem_wr = is_io & mem_wmask[0];

  reg [31:0] pc = 0;
  reg [31:0] instr;


  // --- Instruction decoder ---
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

  // Immediate formats
  wire [31:0] u_imm = {instr[31], instr[30:12], {12{1'b0}}};
  wire [31:0] i_imm = {{21{instr[31]}}, instr[30:20]};
  wire [31:0] s_imm = {{21{instr[31]}}, instr[30:25], instr[11:7]};
  wire [31:0] b_imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
  wire [31:0] j_imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

  // Source and destination register addresses
  wire [4:0] rs1_id = instr[19:15];
  wire [4:0] rs2_id = instr[24:20];
  wire [4:0] rd_id = instr[11:7];

  // Function codes
  wire [2:0] funct3 = instr[14:12];
  wire [6:0] funct7 = instr[31:25];

  wire is_ebreak = is_system & (funct3 == 3'b000);

  // --- Register bank ---
  (* ram_style = "block" *)
  reg [31:0] register_bank[0:31];
  reg [31:0] rs1;
  reg [31:0] rs2;
  wire [31:0] write_back_data;
  wire write_back_en;

  reg [63:0] cycle;
  reg [63:0] instret;

  always @(posedge clk) cycle <= rst ? 0 : cycle + 1;

`ifdef BENCH
`endif

  // --- ALU ---
  wire [31:0] alu_in_1 = rs1;
  wire [31:0] alu_in_2 = is_alu_reg | is_branch ? rs2 : i_imm;
  reg [31:0] alu_out;

  wire [32:0] alu_minus = {1'b0, ~alu_in_2} + {1'b0, alu_in_1} + 33'd1;
  wire eq = (alu_minus[31:0] == 0);
  wire ltu = alu_minus[32];
  wire lt = (alu_in_1[31] ^ alu_in_2[31]) ? alu_in_1[31] : alu_minus[32];

  wire [31:0] alu_plus = alu_in_1 + alu_in_2;

  // verilog_format: off
  function [31:0] flip32;
    input [31:0] x;
    flip32 = {
      x[0],  x[1],  x[2],  x[3],  x[4],  x[5],  x[6],  x[7],
      x[8],  x[9],  x[10], x[11], x[12], x[13], x[14], x[15],
      x[16], x[17], x[18], x[19], x[20], x[21], x[22], x[23],
      x[24], x[25], x[26], x[27], x[28], x[29], x[30], x[31]
    };
  endfunction
  // verilog_format: on

  wire [31:0] shifter_in = (funct3 == 3'b001) ? flip32(alu_in_1) : alu_in_1;
  // optimization for left shift - reversed right shift of reversed value
  wire [31:0] leftshift = flip32(shifter);
  wire [31:0] shifter = $signed({instr[30] & alu_in_1[31], shifter_in}) >>> alu_in_2[4:0];
  always @* begin
    case (funct3)
      3'b000: alu_out = (funct7[5] & instr[5]) ? alu_minus[31:0] : alu_plus;
      3'b001: alu_out = leftshift;
      3'b010: alu_out = {31'd0, lt};
      3'b011: alu_out = {31'd0, ltu};
      3'b100: alu_out = (alu_in_1 ^ alu_in_2);
      3'b101: alu_out = shifter;
      3'b110: alu_out = (alu_in_1 | alu_in_2);
      3'b111: alu_out = (alu_in_1 & alu_in_2);
    endcase
  end

  reg take_branch;
  always @* begin
    case (funct3)
      3'b000:  take_branch = eq;
      3'b001:  take_branch = !eq;
      3'b100:  take_branch = lt;
      3'b101:  take_branch = !lt;
      3'b110:  take_branch = ltu;
      3'b111:  take_branch = !ltu;
      default: take_branch = 1'b0;
    endcase
  end

  // Address computation
  wire [31:0] pc_plus_imm = pc + (instr[3] ? j_imm[31:0] : instr[4] ? u_imm[31:0] : b_imm[31:0]);
  wire [31:0] pc_plus_4 = pc + 4;

  wire [31:0] next_pc = ((is_branch && take_branch) || is_jal) ? pc_plus_imm
      : is_jalr ? {alu_plus[31:1], 1'b0}
      : pc_plus_4;

  wire [31:0] loadstore_addr = rs1 + (is_store ? s_imm : i_imm);

  assign write_back_data = (is_jal || is_jalr) ? (pc_plus_4)
      : is_lui ? u_imm
      : is_auipc ? pc_plus_imm
      : is_load ? loaded_data
      : alu_out;

  // --- LOAD ---
  wire mem_byte_access = (funct3[1:0] == 2'b00);
  wire mem_halfword_access = (funct3[1:0] == 2'b01);

  wire [15:0] loaded_halfword = loadstore_addr[1] ? mem_rdata[31:16] : mem_rdata[15:0];
  wire [7:0] loaded_byte = loadstore_addr[0] ? loaded_halfword[15:8] : loaded_halfword[7:0];
  wire loaded_sign = !funct3[2] & (mem_byte_access ? loaded_byte[7] : loaded_halfword[15]);

  wire [31:0] loaded_data = mem_byte_access ? {{24{loaded_sign}}, loaded_byte}
      : mem_halfword_access ? {{16{loaded_sign}}, loaded_halfword}
      : mem_rdata;

  // --- STORE ---
  assign mem_wdata[7:0] = rs2[7:0];
  assign mem_wdata[15:8] = loadstore_addr[0] ? rs2[7:0] : rs2[15:8];
  assign mem_wdata[23:16] = loadstore_addr[1] ? rs2[7:0] : rs2[23:16];
  assign mem_wdata[31:24] = loadstore_addr[0] ? rs2[7:0]
      : loadstore_addr[1] ? rs2[15:8]
      : rs2[31:24];

  wire [3:0] store_wmask = mem_byte_access ? (
            loadstore_addr[1] ? (loadstore_addr[0] ? 4'b1000 : 4'b0100)
                : (loadstore_addr[0] ? 4'b0010 : 4'b0001)
        ) : mem_halfword_access ? (loadstore_addr[1] ? 4'b1100 : 4'b0011) : 4'b1111;

  // --- FSM ---
  localparam FETCH_INSTR = 0;
  localparam WAIT_INSTR = 1;
  localparam EXECUTE = 2;
  localparam WAIT_DATA = 3;
  reg [1:0] state = FETCH_INSTR;

  always @(posedge clk) begin
    if (rst) begin
      pc <= 0;
      state <= WAIT_DATA;
      instret <= 0;
    end else begin
      if (write_back_en && rd_id != 0) begin
        register_bank[rd_id] <= write_back_data;

`ifdef BENCH
        // $display("x%0d <= %b", rd_id, write_back_data);
`endif
      end

      case (state)
        FETCH_INSTR: begin
          instr <= prog_rom[pc[8:2]];
          state <= WAIT_INSTR;

`ifdef BENCH
          if (pc >= 32'd2048) begin
            $display("invalid PC, out of range: %h", pc);
            $finish();
          end
`endif
        end
        WAIT_INSTR: begin
          rs1 <= register_bank[rs1_id];
          rs2 <= register_bank[rs2_id];
          state <= EXECUTE;
          instret <= instret + 1;
        end
        EXECUTE: begin
          if (!is_ebreak) pc <= next_pc;
          state <= is_load ? WAIT_DATA : FETCH_INSTR;
`ifdef BENCH
          if (is_ebreak) $finish();

          if (is_load || is_store) begin
            if (mem_addr < 32'd512) begin
              $display("invalid data addr: %h", mem_addr);
              $finish();
            end
          end
`endif
        end
        WAIT_DATA: begin
          state <= FETCH_INSTR;
        end
      endcase
    end
  end

  assign mem_addr = loadstore_addr;
  assign mem_wmask = {4{(state == EXECUTE) & is_store}} & store_wmask;
  assign write_back_en = (state == EXECUTE && !is_branch && !is_store) || (state == WAIT_DATA);

endmodule

