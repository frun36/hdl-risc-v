module alu (
    input [31:0] alu_in_1,
    input [31:0] alu_in_2,
    input [31:0] instr,
    output reg [31:0] alu_out,
    output [31:0] alu_plus,
    output reg take_branch
);
  `include "instruction_decoder.v"

  wire [2:0] alu_funct3;
  wire [6:0] alu_funct7;

  wire [32:0] alu_minus = {1'b0, ~alu_in_2} + {1'b0, alu_in_1} + 33'd1;
  wire eq = (alu_minus[31:0] == 0);
  wire ltu = alu_minus[32];
  wire lt = (alu_in_1[31] ^ alu_in_2[31]) ? alu_in_1[31] : alu_minus[32];

  assign alu_plus = alu_in_1 + alu_in_2;

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

  wire [31:0] shifter_in = (alu_funct3 == 3'b001) ? flip32(alu_in_1) : alu_in_1;
  // optimization for left shift - reversed right shift of reversed value
  wire [31:0] leftshift = flip32(shifter);
  wire [31:0] shifter = $signed({instr[30] & alu_in_1[31], shifter_in}) >>> alu_in_2[4:0];
  always @* begin
    case (alu_funct3)
      3'b000: alu_out = (alu_funct7[5] & instr[5]) ? alu_minus[31:0] : alu_plus;
      3'b001: alu_out = leftshift;
      3'b010: alu_out = {31'd0, lt};
      3'b011: alu_out = {31'd0, ltu};
      3'b100: alu_out = (alu_in_1 ^ alu_in_2);
      3'b101: alu_out = shifter;
      3'b110: alu_out = (alu_in_1 | alu_in_2);
      3'b111: alu_out = (alu_in_1 & alu_in_2);
    endcase
  end

  always @* begin
    case (alu_funct3)
      3'b000:  take_branch = eq;
      3'b001:  take_branch = !eq;
      3'b100:  take_branch = lt;
      3'b101:  take_branch = !lt;
      3'b110:  take_branch = ltu;
      3'b111:  take_branch = !ltu;
      default: take_branch = 1'b0;
    endcase
  end
endmodule
