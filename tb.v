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
      if (clk && uut.proc.state == uut.proc.WAIT_DATA) begin
        $display("ADDR = %d; B%b: %b, H%b: %b, S%b; DATA = %b", uut.proc.loadstore_addr,
                 uut.proc.mem_byte_access, uut.proc.loaded_byte, uut.proc.mem_halfword_access,
                 uut.proc.loaded_halfword, uut.proc.loaded_sign, uut.proc.loaded_data);
        $display("LEDS = %b", leds);
      end

      prev_leds <= leds;
    end
  end
endmodule

