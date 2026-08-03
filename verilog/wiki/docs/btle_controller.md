# btle_controller

## Description
TODO: Add description

## Parameters
- C_S00_AXI_DATA_WIDTH  = 32
- C_S00_AXI_ADDR_WIDTH  = 8
- CLK_FREQUENCE = 100_000_000  (= 100000000)
- BAUD_RATE		= 115200
- PARITY = "NONE"  (unresolved)
- FRAME_WD		= 8
- RF_IQ_BIT_WIDTH = 64
- RF_I_OR_Q_BIT_WIDTH = (RF_IQ_BIT_WIDTH/4)  (= 16)
- CRC_STATE_BIT_WIDTH = 24
- CHANNEL_NUMBER_BIT_WIDTH = 6
- SAMPLE_PER_SYMBOL = 8
- GAUSS_FILTER_BIT_WIDTH = 16
- NUM_TAP_GAUSS_FILTER = 17
- VCO_BIT_WIDTH = 16
- SIN_COS_ADDR_BIT_WIDTH = 11
- IQ_BIT_WIDTH = 8
- GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT = 1
- GFSK_DEMODULATION_BIT_WIDTH = 16
- LEN_UNIQUE_BIT_SEQUENCE = 32
- NUM_BIT_PAYLOAD_LENGTH = 8
- BRAM_DEPTH = 32768
- BRAM_ADDR_WIDTH = $clog2(BRAM_DEPTH) = 15
- BRAM_DATA_WIDTH = (2*RF_I_OR_Q_BIT_WIDTH)  (= 32)
- BRAM_ADDR_WIDTH_IN_BYTE = $clog2(BRAM_DEPTH*BRAM_DATA_WIDTH/8)  (unresolved)

## Inputs
- rf_clk
- rf_rst
- bb_clk
- bb_rst
- gpio [7:0]
- bram_addr_a [BRAM_ADDR_WIDTH_IN_BYTE-1 : 0]
- bram_clk_a
- bram_wrdata_a [BRAM_DATA_WIDTH-1 : 0]
- bram_en_a
- bram_rst_a
- bram_we_a
- uart_rx
- rf_gpio [7:0]
- rx_iq_signal_ext [(RF_IQ_BIT_WIDTH-1) : 0]
- rx_iq_valid_ext
- s00_axi_aclk
- s00_axi_aresetn
- s00_axi_awaddr [C_S00_AXI_ADDR_WIDTH-1 : 0]
- s00_axi_awprot [2 : 0]
- s00_axi_awvalid
- s00_axi_wdata [C_S00_AXI_DATA_WIDTH-1 : 0]
- s00_axi_wstrb [(C_S00_AXI_DATA_WIDTH/8)-1 : 0]
- s00_axi_wvalid
- s00_axi_bready
- s00_axi_araddr [C_S00_AXI_ADDR_WIDTH-1 : 0]
- s00_axi_arprot [2 : 0]
- s00_axi_arvalid
- s00_axi_rready
- baremetal_phy_intf_mode
- ext_tx_gauss_filter_tap_index [3:0]
- ext_tx_gauss_filter_tap_value [(GAUSS_FILTER_BIT_WIDTH-1) : 0]
- ext_tx_cos_table_write_address [(SIN_COS_ADDR_BIT_WIDTH-1) : 0]
- ext_tx_cos_table_write_data [(IQ_BIT_WIDTH-1) : 0]
- ext_tx_sin_table_write_address [(SIN_COS_ADDR_BIT_WIDTH-1) : 0]
- ext_tx_sin_table_write_data [(IQ_BIT_WIDTH-1) : 0]
- ext_tx_preamble [7:0]
- ext_tx_access_address [31:0]
- ext_tx_crc_state_init_bit [(CRC_STATE_BIT_WIDTH-1) : 0]
- ext_tx_crc_state_init_bit_load
- ext_tx_channel_number [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0]
- ext_tx_channel_number_load
- ext_tx_pdu_octet_mem_data [7:0]
- ext_tx_pdu_octet_mem_addr [NUM_BIT_PAYLOAD_LENGTH:0]
- ext_tx_start
- ext_rx_unique_bit_sequence [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0]
- ext_rx_channel_number [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0]
- ext_rx_crc_state_init_bit [(CRC_STATE_BIT_WIDTH-1) : 0]
- ext_rx_pdu_octet_mem_addr [NUM_BIT_PAYLOAD_LENGTH:0]

## Outputs
- ll_gpio [15:0]
- ll_itrpt0
- ll_itrpt1
- ll_itrpt2
- ll_itrpt3
- ll_itrpt4
- ll_itrpt5
- ll_itrpt6
- ll_itrpt7
- bram_rddata_a [BRAM_DATA_WIDTH-1 : 0]
- uart_tx
- tx_iq_signal_ext [(RF_IQ_BIT_WIDTH-1) : 0]
- tx_iq_valid_ext
- tx_iq_valid_last_ext
- s00_axi_awready
- s00_axi_wready
- s00_axi_bresp [1 : 0]
- s00_axi_bvalid
- s00_axi_arready
- s00_axi_rdata [C_S00_AXI_DATA_WIDTH-1 : 0]
- s00_axi_rresp [1 : 0]
- s00_axi_rvalid
- ext_tx_phy_bit
- ext_tx_phy_bit_valid
- ext_tx_phy_bit_valid_last
- ext_tx_bit_upsample
- ext_tx_bit_upsample_valid
- ext_tx_bit_upsample_valid_last
- ext_tx_bit_upsample_gauss_filter [(GAUSS_FILTER_BIT_WIDTH-1) : 0]
- ext_tx_bit_upsample_gauss_filter_valid
- ext_tx_bit_upsample_gauss_filter_valid_last
- ext_rx_hit_flag
- ext_rx_decode_run
- ext_rx_decode_end
- ext_rx_crc_ok
- ext_rx_best_phase [2:0]
- ext_rx_payload_length [(NUM_BIT_PAYLOAD_LENGTH-1):0]
- ext_rx_pdu_octet_mem_data [7:0]

## Inouts
- None

## Calls
- [auxiliary_daemon](auxiliary_daemon.md)
- [btle_ll](btle_ll.md)
- [btle_phy](btle_phy.md)
- [clock_domain_conversion_iq](clock_domain_conversion_iq.md)

## Called By
- [btle_controller_wrapper](btle_controller_wrapper.md)
