// iverilog -o aa_correlator_threshold_tb.vvp aa_correlator_threshold_tb.v ../aa_correlator_threshold.v  

`timescale 1ns/1ps

module aa_correlator_threshold_tb;

  localparam LEN = 32;
  localparam THRESH_W = 6;

  reg clk;
  reg rst;
  reg phy_bit;
  reg bit_valid;

  reg  [LEN-1:0] aa_target;
  reg  [THRESH_W-1:0] aa_threshold;

  wire hit_flag;
  wire [THRESH_W-1:0] score;

  // DUT
  aa_correlator_threshold #(
    .LEN(LEN),
    .THRESH_W(THRESH_W)
  ) dut (
    .clk(clk),
    .rst(rst),
    .phy_bit(phy_bit),
    .bit_valid(bit_valid),
    .aa_target(aa_target),
    .aa_threshold(aa_threshold),
    .hit_flag(hit_flag),
    .score(score)
  );

  // clock
  initial clk = 0;
  always #5 clk = ~clk;

  // reference model
  reg [LEN-1:0] ref_shift;
  integer i;

  function [THRESH_W-1:0] popcount;
    input [LEN-1:0] a;
    input [LEN-1:0] b;
    integer j;
    begin
      popcount = 0;
      for (j = 0; j < LEN; j = j + 1)
        popcount = popcount + (a[j] ^ b[j]);
    end
  endfunction

  function [THRESH_W-1:0] matches;
    input [LEN-1:0] a;
    input [LEN-1:0] b;
    begin
      matches = LEN - popcount(a,b);
    end
  endfunction

  // shift model
  always @(posedge clk) begin
    if (rst) begin
      ref_shift <= 0;
    end else if (bit_valid) begin
      ref_shift[LEN-1] <= phy_bit;
      ref_shift[LEN-2:0] <= ref_shift[LEN-1:1];
    end
  end

  // checker (1-cycle delayed like DUT)
  reg bit_valid_d;
  reg [THRESH_W-1:0] exp_score;
  reg exp_hit;

  always @(posedge clk) begin
    if (rst) begin
      bit_valid_d <= 0;
      exp_score <= 0;
      exp_hit <= 0;
    end else begin
      bit_valid_d <= bit_valid;
      exp_hit <= 0;

      if (bit_valid_d) begin
        exp_score <= matches(ref_shift, aa_target);
        if (matches(ref_shift, aa_target) >= aa_threshold)
          exp_hit <= 1;
      end
    end
  end

  // compare
  always @(posedge clk) begin
    if (!rst && bit_valid_d) begin
      if (score !== exp_score) begin
        $display("ERROR score mismatch t=%0t got=%0d exp=%0d",
                 $time, score, exp_score);
        $stop;
      end
      if (hit_flag !== exp_hit) begin
        $display("ERROR hit mismatch t=%0t got=%0d exp=%0d",
                 $time, hit_flag, exp_hit);
        $stop;
      end
    end
  end

  // drive one bit
  task send_bit;
    input b;
    begin
      @(posedge clk);
      phy_bit <= b;
      bit_valid <= 1;
      @(posedge clk);
      bit_valid <= 0;
    end
  endtask

  // send vector MSB->LSB
  task send_word;
    input [LEN-1:0] w;
    integer k;
    begin
      for (k = LEN-1; k >= 0; k = k - 1)
        send_bit(w[k]);
    end
  endtask

  // random stream
  task random_stream;
    input integer n;
    integer k;
    begin
      for (k = 0; k < n; k = k + 1)
        send_bit($random);
    end
  endtask

  // inject pattern with errors
  task send_with_errors;
    input [LEN-1:0] w;
    input integer errors;
    reg [LEN-1:0] tmp;
    integer k;
    begin
      tmp = w;
      for (k = 0; k < errors; k = k + 1)
        tmp[$urandom % LEN] = ~tmp[$urandom % LEN];
      send_word(tmp);
    end
  endtask

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, aa_correlator_threshold_tb);

    clk = 0;
    rst = 1;
    phy_bit = 0;
    bit_valid = 0;
    aa_target = 32'hA5A5_F0F0;
    aa_threshold = 32; // exact

    repeat(5) @(posedge clk);
    rst = 0;

    // 1. fill pipeline
    random_stream(64);

    // 2. exact match
    send_word(aa_target);

    // 3. no hit below threshold
    aa_threshold = 32;
    send_with_errors(aa_target, 3);

    // 4. allow errors
    aa_threshold = 28;
    send_with_errors(aa_target, 3);

    // 5. threshold boundary
    aa_threshold = 30;
    send_with_errors(aa_target, 2); // hit
    send_with_errors(aa_target, 3); // no hit

    // 6. continuous streaming with embedded AA
    aa_threshold = 30;
    random_stream(50);
    send_with_errors(aa_target, 1);
    random_stream(50);

    // 7. bit_valid gaps
    repeat(20) begin
      @(posedge clk);
      bit_valid <= 0;
    end
    send_word(aa_target);

    // 8. reset mid-stream
    random_stream(20);
    rst = 1;
    @(posedge clk);
    rst = 0;
    random_stream(40);

    // 9. stress random
    aa_threshold = 25;
    repeat(200) send_bit($random);

    $display("PASS");
    $finish;
  end

endmodule