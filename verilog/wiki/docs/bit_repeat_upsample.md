# bit_repeat_upsample

## Description
TODO: Add description

## Parameters
- SAMPLE_PER_SYMBOL = 8
- SAMPLE_PER_SYMBOL_2M = 8
- SAMPLE_PER_SYMBOL_16X = 16

## Inputs
- clk
- rst
- phy_2m_mode
- phy_bit
- bit_valid
- bit_valid_last
- osr_16x_en

## Outputs
- bit_upsample
- bit_upsample_valid
- bit_upsample_valid_last

## Inouts
- None

## Calls
- None

## Called By
- [gfsk_modulation](gfsk_modulation.md)
