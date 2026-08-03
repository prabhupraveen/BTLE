# ANTSDR E200 `SIGBUS` Troubleshooting for `btle_ll`

This guide is for the `Bus error` seen when running `firmware/udp/btle_ll.c` on ANTSDR E200 after flashing a different FPGA bitstream.

The most likely root cause is a mismatch between this program's hardcoded hardware assumptions and the new FPGA image. The first MMIO accesses in `main()` are:

- `fd_uio0 = open("/dev/uio0", O_RDWR);`
- `map_base = mmap(NULL, BTLE_LL_REG_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd_uio0, 0);`
- `fpga_regs[0] = (1<<15);`
- `fpga_regs[BTLE_LL_REG_RX_CHANNEL_NUMBER_IDX] = channel_number;`
- `fpga_regs[BTLE_LL_REG_RX_CRC_INIT_BIT_IDX] = crc_init;`
- `fpga_regs[BTLE_LL_REG_RX_PDU_MEM_ADDR_IDX] = 0;`
- `fpga_regs[BTLE_LL_REG_RX_UNIQUE_BIT_SEQ_IDX] = unique_bit_seq;`

If the new bitstream changed the UIO region, register map, or address width, one of those stores can raise `SIGBUS` immediately.

## 1. Confirm the crash location in `gdb`

Run the program under `gdb` and stop on `SIGBUS`:

```bash
gdb --args /root/vis/btle_ll
```

Inside `gdb`:

```gdb
catch signal SIGBUS
run
bt
x/i $pc
info registers
```

What to look for:

- If the backtrace stops in `main()` near the first `fpga_regs[...]` writes, this is an MMIO/register-map issue.
- If the PC is inside `host_intf()`, then the fault is more likely from the UDP packet parsing path.

## 2. Check whether `/dev/uio0` still matches the FPGA image

Run these commands on the ANTSDR:

```bash
ls -l /dev/uio*
cat /sys/class/uio/uio0/name
cat /sys/class/uio/uio0/maps/map0/size
cat /sys/class/uio/uio0/maps/map0/addr
```

If there are multiple UIO devices, inspect all of them:

```bash
for d in /sys/class/uio/uio*; do
  echo "== $d =="
  cat "$d/name"
  cat "$d/maps/map0/size"
  cat "$d/maps/map0/addr"
done
```

What to look for:

- `/dev/uio0` may no longer be the BTLE controller.
- `map0/size` may be smaller than the code expects.
- The new bitstream may expose the peripheral under a different UIO index.

## 3. Check the IIO device name used by the RF tuning path

This file also hardcodes:

```c
/sys/bus/iio/devices/iio:device0/out_altvoltage0_RX_LO_frequency
```

Verify that `iio:device0` still exists:

```bash
ls /sys/bus/iio/devices/
find /sys/bus/iio/devices -maxdepth 2 -name 'out_altvoltage0_RX_LO_frequency' -o -name 'name'
```

If the device numbering changed after the firmware update, the code may be talking to the wrong RF device.

## 4. Check `dmesg` for a hardware abort

Immediately after the crash, run:

```bash
dmesg -T | tail -n 100
```

Look for messages such as:

- `Unhandled fault: alignment fault`
- `Data abort`
- `external abort`
- `synchronous external abort`

Those messages confirm the process hit a hardware access fault rather than a normal software exception.

## 5. Build a debug binary before making code changes

The existing firmware build script uses an optimized, stripped binary. For debugging, build a non-stripped version with symbols and minimal optimization.

From `firmware/`:

```bash
source ~/Xilinx/Vitis/2022.2/settings64.sh
arm-linux-gnueabihf-gcc -static -pthread \
  -O0 -g3 -mcpu=cortex-a9 -mfpu=neon -mfloat-abi=hard \
  -fno-omit-frame-pointer -fno-optimize-sibling-calls \
  -Wall -Wextra -Wcast-align=strict -Wconversion \
  -o btle_ll_dbg udp/btle_ll.c
```

If you want undefined-behavior diagnostics on a suitable test environment:

```bash
arm-linux-gnueabihf-gcc -static -pthread \
  -O0 -g3 -mcpu=cortex-a9 -mfpu=neon -mfloat-abi=hard \
  -fsanitize=undefined -fno-omit-frame-pointer \
  -Wall -Wextra -Wcast-align=strict -Wconversion \
  -o btle_ll_ubsan udp/btle_ll.c
```

Note: sanitizer builds may be too heavy for the target image, so use them first on a test environment if needed.

## 6. Add a minimal MMIO test to isolate the exact failing store

The smallest useful experiment is to comment out the register writes in `main()` one at a time.

Test them in this order:

1. `fpga_regs[0] = (1<<15);`
2. `fpga_regs[BTLE_LL_REG_RX_CHANNEL_NUMBER_IDX] = channel_number;`
3. `fpga_regs[BTLE_LL_REG_RX_CRC_INIT_BIT_IDX] = crc_init;`
4. `fpga_regs[BTLE_LL_REG_RX_PDU_MEM_ADDR_IDX] = 0;`
5. `fpga_regs[BTLE_LL_REG_RX_UNIQUE_BIT_SEQ_IDX] = unique_bit_seq;`

If removing one line makes the crash disappear, that register offset is no longer valid in the new bitstream.

You can also add a temporary guard before each write:

```c
printf("write reg %u = 0x%08X\n", BTLE_LL_REG_RX_CHANNEL_NUMBER_IDX, channel_number);
fflush(stdout);
fpga_regs[BTLE_LL_REG_RX_CHANNEL_NUMBER_IDX] = channel_number;
```

## 7. Verify the register indices against the new bitstream

This program assumes the following register layout:

- `10` = unique bit sequence / access address
- `11` = channel number
- `12` = CRC init
- `13` = PDU memory address

If the new FPGA image moved or removed any of these registers, the software must be updated.

Check the HDL and the generated address map in the FPGA sources, then confirm the offsets still match the code in `firmware/udp/btle_ll.c`.

## 8. Check for alignment-sensitive accesses in the UDP path

These casts are unsafe on some ARM targets if the buffer address is not naturally aligned:

```c
((uint32_t*)(udp_tx_buffer + runtime_len))[0] = 0x05628562;
((uint64_t*)(udp_tx_buffer + runtime_len))[0] = timestamp;
magic_header = ((uint32_t*)(buffer_child + runtime_len))[0];
timestamp = ((uint64_t*)(buffer_child + runtime_len))[0];
unit_field0 = ((uint32_t*)(buffer_child + runtime_len))[0];
unit_field1 = ((uint32_t*)(buffer_child + runtime_len))[0];
```

That is a separate bug from the MMIO issue, but it is still worth testing if the crash moves into `host_intf()`.

To quickly test whether alignment is the problem, replace those raw casts with `memcpy()` in a debug build.

## 9. Collect one clean crash report

Run the program again under `gdb` and save the exact output:

```gdb
catch signal SIGBUS
run
bt full
info registers
x/8i $pc-8
```

Also save:

```bash
dmesg -T | tail -n 100
ls -l /dev/uio*
cat /sys/class/uio/uio0/name
cat /sys/class/uio/uio0/maps/map0/size
```

With those four outputs, you can usually tell whether the new bitstream changed:

- the UIO device index
- the MMIO size
- the register map
- the IIO device numbering

## 10. Practical fix path

If the crash happens on the first MMIO store, update the software to match the new FPGA address map before debugging anything else.

If the crash happens later inside `host_intf()`, switch the packet parsing and packing code to `memcpy()` and add bounds checks for `unit_field0` before `fpga_regs[unit_field0] = unit_field1;`.

If you need a one-line proof, comment out all `fpga_regs[...] = ...;` writes and rerun. If the program no longer bus-errors, the failure is definitely in the new FPGA interface rather than in UDP or signal handling.