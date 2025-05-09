`timescale 1ns / 1ps

module clkdiv #(
    parameter DIV = 100
) (
    input  clk,
    input  rst,
    output en
);

  reg [$clog2(DIV) - 1:0] ctr;

  always @(posedge clk, posedge rst)
    if (rst) ctr <= 0;
    else if (ctr == DIV - 1) ctr <= 0;
    else ctr <= ctr + 1;

  assign en = (ctr == DIV - 1);
endmodule

