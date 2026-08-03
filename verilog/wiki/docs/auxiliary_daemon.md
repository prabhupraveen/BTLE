# auxiliary_daemon

## Description
TODO: Add description

## Parameters
- RF_IQ_BIT_WIDTH = 64
- RF_I_OR_Q_BIT_WIDTH = (RF_IQ_BIT_WIDTH/4)  (= 16)
- IQ_BIT_WIDTH = 8
- GFSK_DEMODULATION_BIT_WIDTH = 16
- BRAM_DEPTH = 32768
- BRAM_ADDR_WIDTH = $clog2(BRAM_DEPTH) = 15
- BRAM_DATA_WIDTH = (2*RF_I_OR_Q_BIT_WIDTH)  (= 32)
- BRAM_ADDR_WIDTH_IN_BYTE = $clog2(BRAM_DEPTH*BRAM_DATA_WIDTH/8)  (unresolved)

## Inputs
- bb_clk
- bb_rst
- rx_i_signal [(RF_I_OR_Q_BIT_WIDTH-1) : 0]
- rx_q_signal [(RF_I_OR_Q_BIT_WIDTH-1) : 0]
- rx_iq_valid
- bb_gpio [7:0]
- bram_addr_a [BRAM_ADDR_WIDTH_IN_BYTE-1 : 0]
- bram_clk_a
- bram_wrdata_a [BRAM_DATA_WIDTH-1 : 0]
- bram_en_a
- bram_rst_a
- bram_we_a

## Outputs
- i_abs_add_q_abs [RF_I_OR_Q_BIT_WIDTH : 0]
- agc_lock_change
- agc_lock_state
- rf_gain [6:0]
- bram_addr_b_half_flag
- bram_addr_b [BRAM_ADDR_WIDTH-1 : 0]
- bram_rddata_a [BRAM_DATA_WIDTH-1 : 0]

## Inouts
- None

## Calls
- [sdpram_two_clk](sdpram_two_clk.md)
- [sdpram_two_clk_xilinx](sdpram_two_clk_xilinx.md)

## Called By
- [btle_controller](btle_controller.md)
