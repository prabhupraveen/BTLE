#!/bin/bash
#
# Toolchain environment configuration
# Each developer may edit this file locally if needed.
#

# Vivado installation root
export XILINX_VIVADO_ROOT=/opt/Xilinx/2025.1/Vivado

# Vitis installation root
export XILINX_VITIS_ROOT=/opt/Xilinx/2025.1/Vitis

# Prevent nounset failures when sourcing Xilinx settings
export PYTHONPATH="${PYTHONPATH:-}"
export MATLABPATH="${MATLABPATH:-}"
