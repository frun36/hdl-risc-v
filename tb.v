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
      if (prev_leds != leds) begin
        $display("LEDS = %b", leds);
      end

      prev_leds <= leds;
    end
  end
endmodule

