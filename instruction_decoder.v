// verilog_format: off
function is_alu_reg; input [31:0] I; is_alu_reg = (I[6:0] == 7'b0110011); endfunction
function is_alu_imm; input [31:0] I; is_alu_imm = (I[6:0] == 7'b0010011); endfunction
function is_branch; input [31:0] I; is_branch = (I[6:0] == 7'b1100011); endfunction
function is_jalr; input [31:0] I; is_jalr = (I[6:0] == 7'b1100111); endfunction
function is_jal; input [31:0] I; is_jal = (I[6:0] == 7'b1101111); endfunction
function is_auipc; input [31:0] I; is_auipc = (I[6:0] == 7'b0010111); endfunction
function is_lui; input [31:0] I; is_lui = (I[6:0] == 7'b0110111); endfunction
function is_load; input [31:0] I; is_load = (I[6:0] == 7'b0000011); endfunction
function is_store; input [31:0] I; is_store = (I[6:0] == 7'b0100011); endfunction
function is_system; input [31:0] I; is_system = (I[6:0] == 7'b1110011); endfunction

function [4:0] rs1_id; input [31:0] I; rs1_id = I[19:15]; endfunction
function [4:0] rs2_id; input [31:0] I; rs2_id = I[24:20]; endfunction
function [4:0] shamt;  input [31:0] I; shamt = I[24:20]; endfunction
function [4:0] rd_id;  input [31:0] I; rd_id  = I[11:7]; endfunction
function [1:0] csr_id; input [31:0] I; csr_id = {I[27],I[21]}; endfunction

function [2:0] funct3; input [31:0] I; funct3 = I[14:12]; endfunction
function [6:0] funct7; input [31:0] I; funct7 = I[31:25]; endfunction

function is_ebreak; input [31:0] I;
  is_ebreak = (is_system(I) && funct3(I) == 3'b000); endfunction

function is_csrrs; input [31:0] I;
  is_csrrs = (is_system(I) && funct3(I) == 3'b010); endfunction

/* The 5 immediate formats */
function [31:0] u_imm; input [31:0] I;
  u_imm = {I[31:12],{12{1'b0}}}; endfunction
function [31:0] i_imm; input [31:0] I;
  i_imm = {{21{I[31]}},I[30:20]}; endfunction
function [31:0] s_imm; input [31:0] I;
  s_imm = {{21{I[31]}},I[30:25],I[11:7]}; endfunction
function [31:0] b_imm; input [31:0] I;
  b_imm = {{20{I[31]}},I[7],I[30:25],I[11:8],1'b0}; endfunction
function [31:0] j_imm; input [31:0] I;
  j_imm = {{12{I[31]}},I[19:12],I[20],I[30:21],1'b0}; endfunction
// verilog_format: on
