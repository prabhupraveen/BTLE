#!/bin/bash
set -euo pipefail
set -x

###############################################################################
# Load toolchain environment
###############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ENV_FILE="$SCRIPT_DIR/env.sh"

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: env.sh not found in repo root"
    echo "Expected: $ENV_FILE"
    exit 1
fi

source "$ENV_FILE"

###############################################################################
# Environment validation
###############################################################################
: "${XILINX_VIVADO_ROOT:?env.sh must define XILINX_VIVADO_ROOT}"
: "${XILINX_VITIS_ROOT:?env.sh must define XILINX_VITIS_ROOT}"

VIVADO_SETTINGS="$XILINX_VIVADO_ROOT/settings64.sh"
VITIS_SETTINGS="$XILINX_VITIS_ROOT/settings64.sh"

if [ ! -f "$VIVADO_SETTINGS" ]; then
    echo "ERROR: Vivado settings not found: $VIVADO_SETTINGS"
    exit 1
fi

if [ ! -f "$VITIS_SETTINGS" ]; then
    echo "ERROR: Vitis settings not found: $VITIS_SETTINGS"
    exit 1
fi

#echo "Using Vivado: $XILINX_VIVADO_ROOT"
echo "Using Vitis : $XILINX_VITIS_ROOT"

###############################################################################
# Source tools
###############################################################################
source "$VIVADO_SETTINGS"
source "$VITIS_SETTINGS"

###############################################################################
# Tool sanity checks
###############################################################################
command -v vitis   >/dev/null 2>&1 || { echo "ERROR: vitis not in PATH"; exit 1; }
command -v bootgen >/dev/null 2>&1 || { echo "ERROR: bootgen not in PATH"; exit 1; }

###############################################################################
# Arguments
###############################################################################
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <hardware>"
  echo "  hardware: antsdr | sdrpi | antsdr_e200"
  exit 1
fi

HARDWARE=$1

# HW_BASE_DIR=../../BTLE-hw-img/fpga
HW_BASE_DIR=..
UBOOT_IMAGE=./u-boot.elf

BUILD_DIR=build_boot_bin
OUTPUT_DIR=output_boot_bin

XSA_FILE=${HW_BASE_DIR}/${HARDWARE}/btle_${HARDWARE}/system_top.xsa

###############################################################################
# Sanity checks
###############################################################################
if [ ! -f "$XSA_FILE" ]; then
    echo "ERROR: XSA not found: $XSA_FILE"
    exit 1
fi

if [ ! -f "$UBOOT_IMAGE" ]; then
    echo "ERROR: u-boot image not found: $UBOOT_IMAGE"
    exit 1
fi

###############################################################################
# Prepare directories
###############################################################################
rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"

cp "$XSA_FILE"      "$BUILD_DIR/"
cp "$XSA_FILE"      "$OUTPUT_DIR/"
cp "$UBOOT_IMAGE"   "$OUTPUT_DIR/u-boot.elf"

XSA_BASENAME=$(basename "$XSA_FILE")

###############################################################################
# Build FSBL using Vitis Python API
###############################################################################
echo "==== Building FSBL using Vitis Python ===="

vitis -s build_fsbl.py "$BUILD_DIR" "$XSA_BASENAME"

###############################################################################
# Locate generated outputs
###############################################################################
FSBL_PATH=$(find "$BUILD_DIR" -name fsbl.elf | head -n 1)
BIT_PATH=$(find "$BUILD_DIR" -name "*.bit" | grep system_top | head -n 1)

if [ -z "$FSBL_PATH" ]; then
    echo "ERROR: fsbl.elf not found!"
    exit 1
fi

if [ -z "$BIT_PATH" ]; then
    echo "ERROR: system_top.bit not found!"
    exit 1
fi

echo "FSBL      : $FSBL_PATH"
echo "BITSTREAM : $BIT_PATH"

cp "$FSBL_PATH" "$OUTPUT_DIR/fsbl.elf"
cp "$BIT_PATH"  "$OUTPUT_DIR/system_top.bit"

###############################################################################
# Create BIF
###############################################################################
cat > "$OUTPUT_DIR/zynq.bif" <<EOF
the_ROM_image:
{
    [bootloader] fsbl.elf
    system_top.bit
    u-boot.elf
}
EOF

###############################################################################
# Build BOOT.BIN
###############################################################################
echo "==== Generating BOOT.BIN ===="

(
    cd "$OUTPUT_DIR"
    bootgen -arch zynq -image zynq.bif -o BOOT.BIN -w
)

###############################################################################
# Publish result
###############################################################################
cp "$OUTPUT_DIR/BOOT.BIN" ./

echo "===================================================="
echo "BOOT.BIN generated successfully for hardware: $HARDWARE"
echo "===================================================="
