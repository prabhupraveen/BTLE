# gfsk_modulation

## Description
TODO: Add description

## Parameters
- SAMPLE_PER_SYMBOL = 8
- GAUSS_FILTER_BIT_WIDTH = 16
- NUM_TAP_GAUSS_FILTER = 17
- VCO_BIT_WIDTH = 16
- SIN_COS_ADDR_BIT_WIDTH = 11
- IQ_BIT_WIDTH = 8
- GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT = 1

## Inputs
- clk
- rst
- phy_2m_mode
- osr_16x_en
- gauss_filter_tap_index [3:0]
- gauss_filter_tap_value [(GAUSS_FILTER_BIT_WIDTH-1) : 0]
- cos_table_write_address [(SIN_COS_ADDR_BIT_WIDTH-1) : 0]
- cos_table_write_data [(IQ_BIT_WIDTH-1) : 0]
- sin_table_write_address [(SIN_COS_ADDR_BIT_WIDTH-1) : 0]
- sin_table_write_data [(IQ_BIT_WIDTH-1) : 0]
- phy_bit
- bit_valid
- bit_valid_last

## Outputs
- cos_out [(IQ_BIT_WIDTH-1) : 0]
- sin_out [(IQ_BIT_WIDTH-1) : 0]
- sin_cos_out_valid
- sin_cos_out_valid_last
- bit_upsample
- bit_upsample_valid
- bit_upsample_valid_last
- bit_upsample_gauss_filter [(GAUSS_FILTER_BIT_WIDTH-1) : 0]
- bit_upsample_gauss_filter_valid
- bit_upsample_gauss_filter_valid_last

## Inouts
- None

## Calls
- [bit_repeat_upsample](bit_repeat_upsample.md)
- [gauss_filter](gauss_filter.md)
- [vco](vco.md)

## Called By
- [btle_tx](btle_tx.md)
