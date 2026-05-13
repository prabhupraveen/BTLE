// Testbench: sdpram_one_clk
//
// Run:
//   iverilog -g2012 -o sdpram_one_clk_tb.vvp sdpram_one_clk_tb.v sdpram_one_clk.v
//   vvp sdpram_one_clk_tb
//
// What it tests (small but more comprehensive than smoke):
// - Read-after-write behavior with same clock (sync read): write pattern, then read back next cycles.
// - Randomized writes and reads.
// - Corner addresses: 0 and max.
// Notes:
// - DUT has synchronous read: read_data updates on posedge clk with memory[read_address].
//   So we check read_data one cycle after setting read_address.

`timescale 1ns/1ps

module sdpram_one_clk_tb;

  localparam int DATA_WIDTH    = 8;
  localparam int ADDRESS_WIDTH = 6; // small for TB speed
  localparam int DEPTH         = (1 << ADDRESS_WIDTH);

  reg clk;
  reg rst;

  reg  [ADDRESS_WIDTH-1:0] write_address;
  reg  [DATA_WIDTH-1:0]    write_data;
  reg                      write_enable;

  reg  [ADDRESS_WIDTH-1:0] read_address;
  wire [DATA_WIDTH-1:0]    read_data;

  sdpram_one_clk #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDRESS_WIDTH(ADDRESS_WIDTH)
  ) dut (
    .clk(clk),
    .rst(rst),
    .write_address(write_address),
    .write_data(write_data),
    .write_enable(write_enable),
    .read_address(read_address),
    .read_data(read_data)
  );

  reg [DATA_WIDTH-1:0] golden [0:DEPTH-1];

  integer i;
  integer seed;

  task automatic tb_fatal(input [1023:0] msg);
    begin
      $display("TB_FATAL: %0s @ t=%0t", msg, $time);
      $finish;
    end
  endtask

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic do_write(
    input [ADDRESS_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0]    data
  );
    begin
      write_address <= addr;
      write_data    <= data;
      write_enable  <= 1'b1;
      tick();
      write_enable  <= 1'b0;
      golden[addr]  = data;
    end
  endtask

  task automatic do_read_check(
    input [ADDRESS_WIDTH-1:0] addr
  );
    reg [DATA_WIDTH-1:0] exp;
    begin
      exp = golden[addr];
      read_address <= addr;
      tick(); // sync read latency 1 cycle
      if (read_data !== exp) begin
        $display("Read mismatch addr=%0d exp=%0h got=%0h", addr, exp, read_data);
        tb_fatal("sdpram_one_clk read check failed");
      end
    end
  endtask

  initial begin
    $dumpfile("sdpram_one_clk_tb.vcd");
    $dumpvars(0, sdpram_one_clk_tb);

    clk = 0;
    rst = 1;

    write_address = '0;
    write_data    = '0;
    write_enable  = 1'b0;
    read_address  = '0;

    for (i = 0; i < DEPTH; i = i + 1) golden[i] = '0;

    seed = 32'h1234_5678;

    repeat (4) tick();
    rst = 0;

    // Deterministic fill: addr -> (addr*3 + 5)
    for (i = 0; i < DEPTH; i = i + 1) begin
      do_write(i[ADDRESS_WIDTH-1:0], ((i*3)+5) & ((1<<DATA_WIDTH)-1));
    end

    // Readback sweep
    for (i = 0; i < DEPTH; i = i + 1) begin
      do_read_check(i[ADDRESS_WIDTH-1:0]);
    end

    // Corner overwrite + immediate readback
    do_write({ADDRESS_WIDTH{1'b0}}, 8'hA5);
    do_write({ADDRESS_WIDTH{1'b1}}, 8'h5A);
    do_read_check({ADDRESS_WIDTH{1'b0}});
    do_read_check({ADDRESS_WIDTH{1'b1}});

    // Random transactions
    for (i = 0; i < 200; i = i + 1) begin
      if ($random(seed) & 1) begin
        do_write($random(seed), $random(seed));
      end else begin
        do_read_check($random(seed));
      end
    end

    // Final full sweep
    for (i = 0; i < DEPTH; i = i + 1) begin
      do_read_check(i[ADDRESS_WIDTH-1:0]);
    end

    $display("PASS: sdpram_one_clk_tb");
    $finish;
  end

  always #31.25 clk = ~clk; // ~16MHz

endmodule