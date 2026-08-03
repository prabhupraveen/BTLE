# vco

## Description
TODO: Add description

## Parameters
- VCO_BIT_WIDTH = 16
- SIN_COS_ADDR_BIT_WIDTH = 11
- IQ_BIT_WIDTH = 8

## Inputs
- clk
- rst
- cos_table_write_address [(SIN_COS_ADDR_BIT_WIDTH-1) : 0]
- cos_table_write_data [(IQ_BIT_WIDTH-1) : 0]
- sin_table_write_address [(SIN_COS_ADDR_BIT_WIDTH-1) : 0]
- sin_table_write_data [(IQ_BIT_WIDTH-1) : 0]
- voltage_signal [(VCO_BIT_WIDTH-1) : 0]
- voltage_signal_valid
- voltage_signal_valid_last

## Outputs
- cos_out [(IQ_BIT_WIDTH-1) : 0]
- sin_out [(IQ_BIT_WIDTH-1) : 0]
- sin_cos_out_valid
- sin_cos_out_valid_last

## Inouts
- None

## Calls
- [sdpram_one_clk](sdpram_one_clk.md)

## Called By
- [gfsk_modulation](gfsk_modulation.md)
