// Testbench: sdpram_two_clk
//
// Run:
//   iverilog -g2012 -o sdpram_two_clk_tb.vvp sdpram_two_clk_tb.v sdpram_two_clk.v
//   vvp sdpram_two_clk_tb
//
// What it tests:
// - Independent write/read clocks.
// - Write burst then readback with sync read on clkb.
// - Randomized concurrent writes and reads.
// Notes:
// - Read port is synchronous to clkb: read_data updates on posedge clkb with memory[read_address].
//   So we check read_data one clkb edge after setting read_address.

`timescale 1ns/1ps

module sdpram_two_clk_tb;

  localparam int DATA_WIDTH    = 8;
  localparam int ADDRESS_WIDTH = 6;
  localparam int DEPTH         = (1 << ADDRESS_WIDTH);

  reg clk;   // write clock
  reg clkb;  // read clock
  reg rst;

  reg  [ADDRESS_WIDTH-1:0] write_address;
  reg  [DATA_WIDTH-1:0]    write_data;
  reg                      write_enable;

  reg  [ADDRESS_WIDTH-1:0] read_address;
  wire [DATA_WIDTH-1:0]    read_data;

  sdpram_two_clk #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDRESS_WIDTH(ADDRESS_WIDTH)
  ) dut (
    .clk(clk),
    .rst(rst),
    .write_address(write_address),
    .write_data(write_data),
    .write_enable(write_enable),
    .clkb(clkb),
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

  initial begin
    $dumpfile("sdpram_two_clk_tb.vcd");
    $dumpvars(0, sdpram_two_clk_tb);

    clk = 0;
    clkb = 0;
    rst = 1;

    write_address = '0;
    write_data    = '0;
    write_enable  = 1'b0;
    read_address  = '0;

    for (i = 0; i < DEPTH; i = i + 1) golden[i] = '0;

    seed = 32'hCAFE_BABE;

    // reset for a few cycles
    repeat (5) @(posedge clk);
    rst = 0;

    // Write deterministic pattern on write clock
    for (i = 0; i < DEPTH; i = i + 1) begin
      @(posedge clk);
      write_enable  <= 1'b1;
      write_address <= i[ADDRESS_WIDTH-1:0];
      write_data    <= (8'h11 ^ i[7:0]);
      golden[i]     = (8'h11 ^ i[7:0]);
    end
    @(posedge clk);
    write_enable <= 1'b0;

    // Readback sweep on read clock
    for (i = 0; i < DEPTH; i = i + 1) begin
      read_address = i[ADDRESS_WIDTH-1:0];
      @(posedge clkb);
      #1;
      if (read_data !== golden[i[ADDRESS_WIDTH-1:0]]) begin
        $display("Read mismatch addr=%0d exp=%0h got=%0h",
                 i[ADDRESS_WIDTH-1:0], golden[i[ADDRESS_WIDTH-1:0]], read_data);
        tb_fatal("sdpram_two_clk readback sweep failed");
      end
    end

    // Random write phase on clk
    for (i = 0; i < 300; i = i + 1) begin
      reg [ADDRESS_WIDTH-1:0] wr_addr;
      reg [DATA_WIDTH-1:0]    wr_data;
      @(posedge clk);
      if ($random(seed) & 1) begin
        wr_addr = $random(seed);
        wr_data = $random(seed);
        write_enable  <= 1'b1;
        write_address <= wr_addr;
        write_data    <= wr_data;
        golden[wr_addr] = wr_data;
      end else begin
        write_enable <= 1'b0;
      end
    end
    @(posedge clk);
    write_enable <= 1'b0;

    // Random read/check phase on clkb
    begin : rd_thread
      integer k;
      reg [ADDRESS_WIDTH-1:0] addr;
      for (k = 0; k < 400; k = k + 1) begin
        addr = $random(seed);
        read_address = addr;
        @(posedge clkb);
        #1;
        if (read_data !== golden[addr]) begin
          $display("Read mismatch addr=%0d exp=%0h got=%0h",
                   addr, golden[addr], read_data);
          tb_fatal("sdpram_two_clk random phase failed");
        end
      end
    end

    $display("PASS: sdpram_two_clk_tb");
    $finish;
  end

  // 16 MHz write clock
  always #31.25 clk = ~clk;
  // ~12.5 MHz read clock (different to exercise CDC-ish behavior)
  always #40.0  clkb = ~clkb;

endmodule