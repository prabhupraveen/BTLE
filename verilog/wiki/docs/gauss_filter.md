# gauss_filter

## Description
TODO: Add description

## Parameters
- GAUSS_FILTER_BIT_WIDTH = 16
- NUM_TAP_GAUSS_FILTER = 17

## Inputs
- clk
- rst
- tap_index [3:0]
- tap_value [(GAUSS_FILTER_BIT_WIDTH-1) : 0]
- bit_upsample
- bit_upsample_valid
- bit_upsample_valid_last

## Outputs
- bit_upsample_gauss_filter [(GAUSS_FILTER_BIT_WIDTH-1) : 0]
- bit_upsample_gauss_filter_valid
- bit_upsample_gauss_filter_valid_last

## Inouts
- None

## Calls
- None

## Called By
- [gfsk_modulation](gfsk_modulation.md)
