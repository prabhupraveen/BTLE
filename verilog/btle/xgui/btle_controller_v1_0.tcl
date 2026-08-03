# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "BAUD_RATE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "BRAM_ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "BRAM_ADDR_WIDTH_IN_BYTE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "BRAM_DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "BRAM_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "CHANNEL_NUMBER_BIT_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "CLK_FREQUENCE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "CRC_STATE_BIT_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "FRAME_WD" -parent ${Page_0}
  ipgui::add_param $IPINST -name "GAUSS_FILTER_BIT_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "GFSK_DEMODULATION_BIT_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "IQ_BIT_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "LEN_UNIQUE_BIT_SEQUENCE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "NUM_BIT_PAYLOAD_LENGTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "NUM_TAP_GAUSS_FILTER" -parent ${Page_0}
  ipgui::add_param $IPINST -name "PARITY" -parent ${Page_0}
  ipgui::add_param $IPINST -name "RF_IQ_BIT_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "RF_I_OR_Q_BIT_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SAMPLE_PER_SYMBOL" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SIN_COS_ADDR_BIT_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "VCO_BIT_WIDTH" -parent ${Page_0}


}

proc update_PARAM_VALUE.BAUD_RATE { PARAM_VALUE.BAUD_RATE } {
	# Procedure called to update BAUD_RATE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BAUD_RATE { PARAM_VALUE.BAUD_RATE } {
	# Procedure called to validate BAUD_RATE
	return true
}

proc update_PARAM_VALUE.BRAM_ADDR_WIDTH { PARAM_VALUE.BRAM_ADDR_WIDTH } {
	# Procedure called to update BRAM_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BRAM_ADDR_WIDTH { PARAM_VALUE.BRAM_ADDR_WIDTH } {
	# Procedure called to validate BRAM_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.BRAM_ADDR_WIDTH_IN_BYTE { PARAM_VALUE.BRAM_ADDR_WIDTH_IN_BYTE } {
	# Procedure called to update BRAM_ADDR_WIDTH_IN_BYTE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BRAM_ADDR_WIDTH_IN_BYTE { PARAM_VALUE.BRAM_ADDR_WIDTH_IN_BYTE } {
	# Procedure called to validate BRAM_ADDR_WIDTH_IN_BYTE
	return true
}

proc update_PARAM_VALUE.BRAM_DATA_WIDTH { PARAM_VALUE.BRAM_DATA_WIDTH } {
	# Procedure called to update BRAM_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BRAM_DATA_WIDTH { PARAM_VALUE.BRAM_DATA_WIDTH } {
	# Procedure called to validate BRAM_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.BRAM_DEPTH { PARAM_VALUE.BRAM_DEPTH } {
	# Procedure called to update BRAM_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BRAM_DEPTH { PARAM_VALUE.BRAM_DEPTH } {
	# Procedure called to validate BRAM_DEPTH
	return true
}

proc update_PARAM_VALUE.CHANNEL_NUMBER_BIT_WIDTH { PARAM_VALUE.CHANNEL_NUMBER_BIT_WIDTH } {
	# Procedure called to update CHANNEL_NUMBER_BIT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CHANNEL_NUMBER_BIT_WIDTH { PARAM_VALUE.CHANNEL_NUMBER_BIT_WIDTH } {
	# Procedure called to validate CHANNEL_NUMBER_BIT_WIDTH
	return true
}

proc update_PARAM_VALUE.CLK_FREQUENCE { PARAM_VALUE.CLK_FREQUENCE } {
	# Procedure called to update CLK_FREQUENCE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CLK_FREQUENCE { PARAM_VALUE.CLK_FREQUENCE } {
	# Procedure called to validate CLK_FREQUENCE
	return true
}

proc update_PARAM_VALUE.CRC_STATE_BIT_WIDTH { PARAM_VALUE.CRC_STATE_BIT_WIDTH } {
	# Procedure called to update CRC_STATE_BIT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CRC_STATE_BIT_WIDTH { PARAM_VALUE.CRC_STATE_BIT_WIDTH } {
	# Procedure called to validate CRC_STATE_BIT_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S00_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S00_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to update C_S00_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S00_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.FRAME_WD { PARAM_VALUE.FRAME_WD } {
	# Procedure called to update FRAME_WD when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FRAME_WD { PARAM_VALUE.FRAME_WD } {
	# Procedure called to validate FRAME_WD
	return true
}

proc update_PARAM_VALUE.GAUSS_FILTER_BIT_WIDTH { PARAM_VALUE.GAUSS_FILTER_BIT_WIDTH } {
	# Procedure called to update GAUSS_FILTER_BIT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.GAUSS_FILTER_BIT_WIDTH { PARAM_VALUE.GAUSS_FILTER_BIT_WIDTH } {
	# Procedure called to validate GAUSS_FILTER_BIT_WIDTH
	return true
}

proc update_PARAM_VALUE.GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT { PARAM_VALUE.GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT } {
	# Procedure called to update GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT { PARAM_VALUE.GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT } {
	# Procedure called to validate GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT
	return true
}

proc update_PARAM_VALUE.GFSK_DEMODULATION_BIT_WIDTH { PARAM_VALUE.GFSK_DEMODULATION_BIT_WIDTH } {
	# Procedure called to update GFSK_DEMODULATION_BIT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.GFSK_DEMODULATION_BIT_WIDTH { PARAM_VALUE.GFSK_DEMODULATION_BIT_WIDTH } {
	# Procedure called to validate GFSK_DEMODULATION_BIT_WIDTH
	return true
}

proc update_PARAM_VALUE.IQ_BIT_WIDTH { PARAM_VALUE.IQ_BIT_WIDTH } {
	# Procedure called to update IQ_BIT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IQ_BIT_WIDTH { PARAM_VALUE.IQ_BIT_WIDTH } {
	# Procedure called to validate IQ_BIT_WIDTH
	return true
}

proc update_PARAM_VALUE.LEN_UNIQUE_BIT_SEQUENCE { PARAM_VALUE.LEN_UNIQUE_BIT_SEQUENCE } {
	# Procedure called to update LEN_UNIQUE_BIT_SEQUENCE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.LEN_UNIQUE_BIT_SEQUENCE { PARAM_VALUE.LEN_UNIQUE_BIT_SEQUENCE } {
	# Procedure called to validate LEN_UNIQUE_BIT_SEQUENCE
	return true
}

proc update_PARAM_VALUE.NUM_BIT_PAYLOAD_LENGTH { PARAM_VALUE.NUM_BIT_PAYLOAD_LENGTH } {
	# Procedure called to update NUM_BIT_PAYLOAD_LENGTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NUM_BIT_PAYLOAD_LENGTH { PARAM_VALUE.NUM_BIT_PAYLOAD_LENGTH } {
	# Procedure called to validate NUM_BIT_PAYLOAD_LENGTH
	return true
}

proc update_PARAM_VALUE.NUM_TAP_GAUSS_FILTER { PARAM_VALUE.NUM_TAP_GAUSS_FILTER } {
	# Procedure called to update NUM_TAP_GAUSS_FILTER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NUM_TAP_GAUSS_FILTER { PARAM_VALUE.NUM_TAP_GAUSS_FILTER } {
	# Procedure called to validate NUM_TAP_GAUSS_FILTER
	return true
}

proc update_PARAM_VALUE.PARITY { PARAM_VALUE.PARITY } {
	# Procedure called to update PARITY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PARITY { PARAM_VALUE.PARITY } {
	# Procedure called to validate PARITY
	return true
}

proc update_PARAM_VALUE.RF_IQ_BIT_WIDTH { PARAM_VALUE.RF_IQ_BIT_WIDTH } {
	# Procedure called to update RF_IQ_BIT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RF_IQ_BIT_WIDTH { PARAM_VALUE.RF_IQ_BIT_WIDTH } {
	# Procedure called to validate RF_IQ_BIT_WIDTH
	return true
}

proc update_PARAM_VALUE.RF_I_OR_Q_BIT_WIDTH { PARAM_VALUE.RF_I_OR_Q_BIT_WIDTH } {
	# Procedure called to update RF_I_OR_Q_BIT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RF_I_OR_Q_BIT_WIDTH { PARAM_VALUE.RF_I_OR_Q_BIT_WIDTH } {
	# Procedure called to validate RF_I_OR_Q_BIT_WIDTH
	return true
}

proc update_PARAM_VALUE.SAMPLE_PER_SYMBOL { PARAM_VALUE.SAMPLE_PER_SYMBOL } {
	# Procedure called to update SAMPLE_PER_SYMBOL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SAMPLE_PER_SYMBOL { PARAM_VALUE.SAMPLE_PER_SYMBOL } {
	# Procedure called to validate SAMPLE_PER_SYMBOL
	return true
}

proc update_PARAM_VALUE.SIN_COS_ADDR_BIT_WIDTH { PARAM_VALUE.SIN_COS_ADDR_BIT_WIDTH } {
	# Procedure called to update SIN_COS_ADDR_BIT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SIN_COS_ADDR_BIT_WIDTH { PARAM_VALUE.SIN_COS_ADDR_BIT_WIDTH } {
	# Procedure called to validate SIN_COS_ADDR_BIT_WIDTH
	return true
}

proc update_PARAM_VALUE.VCO_BIT_WIDTH { PARAM_VALUE.VCO_BIT_WIDTH } {
	# Procedure called to update VCO_BIT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.VCO_BIT_WIDTH { PARAM_VALUE.VCO_BIT_WIDTH } {
	# Procedure called to validate VCO_BIT_WIDTH
	return true
}


proc update_MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.CLK_FREQUENCE { MODELPARAM_VALUE.CLK_FREQUENCE PARAM_VALUE.CLK_FREQUENCE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CLK_FREQUENCE}] ${MODELPARAM_VALUE.CLK_FREQUENCE}
}

proc update_MODELPARAM_VALUE.BAUD_RATE { MODELPARAM_VALUE.BAUD_RATE PARAM_VALUE.BAUD_RATE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BAUD_RATE}] ${MODELPARAM_VALUE.BAUD_RATE}
}

proc update_MODELPARAM_VALUE.PARITY { MODELPARAM_VALUE.PARITY PARAM_VALUE.PARITY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PARITY}] ${MODELPARAM_VALUE.PARITY}
}

proc update_MODELPARAM_VALUE.FRAME_WD { MODELPARAM_VALUE.FRAME_WD PARAM_VALUE.FRAME_WD } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FRAME_WD}] ${MODELPARAM_VALUE.FRAME_WD}
}

proc update_MODELPARAM_VALUE.RF_IQ_BIT_WIDTH { MODELPARAM_VALUE.RF_IQ_BIT_WIDTH PARAM_VALUE.RF_IQ_BIT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RF_IQ_BIT_WIDTH}] ${MODELPARAM_VALUE.RF_IQ_BIT_WIDTH}
}

proc update_MODELPARAM_VALUE.RF_I_OR_Q_BIT_WIDTH { MODELPARAM_VALUE.RF_I_OR_Q_BIT_WIDTH PARAM_VALUE.RF_I_OR_Q_BIT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RF_I_OR_Q_BIT_WIDTH}] ${MODELPARAM_VALUE.RF_I_OR_Q_BIT_WIDTH}
}

proc update_MODELPARAM_VALUE.CRC_STATE_BIT_WIDTH { MODELPARAM_VALUE.CRC_STATE_BIT_WIDTH PARAM_VALUE.CRC_STATE_BIT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CRC_STATE_BIT_WIDTH}] ${MODELPARAM_VALUE.CRC_STATE_BIT_WIDTH}
}

proc update_MODELPARAM_VALUE.CHANNEL_NUMBER_BIT_WIDTH { MODELPARAM_VALUE.CHANNEL_NUMBER_BIT_WIDTH PARAM_VALUE.CHANNEL_NUMBER_BIT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CHANNEL_NUMBER_BIT_WIDTH}] ${MODELPARAM_VALUE.CHANNEL_NUMBER_BIT_WIDTH}
}

proc update_MODELPARAM_VALUE.SAMPLE_PER_SYMBOL { MODELPARAM_VALUE.SAMPLE_PER_SYMBOL PARAM_VALUE.SAMPLE_PER_SYMBOL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SAMPLE_PER_SYMBOL}] ${MODELPARAM_VALUE.SAMPLE_PER_SYMBOL}
}

proc update_MODELPARAM_VALUE.GAUSS_FILTER_BIT_WIDTH { MODELPARAM_VALUE.GAUSS_FILTER_BIT_WIDTH PARAM_VALUE.GAUSS_FILTER_BIT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.GAUSS_FILTER_BIT_WIDTH}] ${MODELPARAM_VALUE.GAUSS_FILTER_BIT_WIDTH}
}

proc update_MODELPARAM_VALUE.NUM_TAP_GAUSS_FILTER { MODELPARAM_VALUE.NUM_TAP_GAUSS_FILTER PARAM_VALUE.NUM_TAP_GAUSS_FILTER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NUM_TAP_GAUSS_FILTER}] ${MODELPARAM_VALUE.NUM_TAP_GAUSS_FILTER}
}

proc update_MODELPARAM_VALUE.VCO_BIT_WIDTH { MODELPARAM_VALUE.VCO_BIT_WIDTH PARAM_VALUE.VCO_BIT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.VCO_BIT_WIDTH}] ${MODELPARAM_VALUE.VCO_BIT_WIDTH}
}

proc update_MODELPARAM_VALUE.SIN_COS_ADDR_BIT_WIDTH { MODELPARAM_VALUE.SIN_COS_ADDR_BIT_WIDTH PARAM_VALUE.SIN_COS_ADDR_BIT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SIN_COS_ADDR_BIT_WIDTH}] ${MODELPARAM_VALUE.SIN_COS_ADDR_BIT_WIDTH}
}

proc update_MODELPARAM_VALUE.IQ_BIT_WIDTH { MODELPARAM_VALUE.IQ_BIT_WIDTH PARAM_VALUE.IQ_BIT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IQ_BIT_WIDTH}] ${MODELPARAM_VALUE.IQ_BIT_WIDTH}
}

proc update_MODELPARAM_VALUE.GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT { MODELPARAM_VALUE.GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT PARAM_VALUE.GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT}] ${MODELPARAM_VALUE.GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT}
}

proc update_MODELPARAM_VALUE.GFSK_DEMODULATION_BIT_WIDTH { MODELPARAM_VALUE.GFSK_DEMODULATION_BIT_WIDTH PARAM_VALUE.GFSK_DEMODULATION_BIT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.GFSK_DEMODULATION_BIT_WIDTH}] ${MODELPARAM_VALUE.GFSK_DEMODULATION_BIT_WIDTH}
}

proc update_MODELPARAM_VALUE.LEN_UNIQUE_BIT_SEQUENCE { MODELPARAM_VALUE.LEN_UNIQUE_BIT_SEQUENCE PARAM_VALUE.LEN_UNIQUE_BIT_SEQUENCE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.LEN_UNIQUE_BIT_SEQUENCE}] ${MODELPARAM_VALUE.LEN_UNIQUE_BIT_SEQUENCE}
}

proc update_MODELPARAM_VALUE.NUM_BIT_PAYLOAD_LENGTH { MODELPARAM_VALUE.NUM_BIT_PAYLOAD_LENGTH PARAM_VALUE.NUM_BIT_PAYLOAD_LENGTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NUM_BIT_PAYLOAD_LENGTH}] ${MODELPARAM_VALUE.NUM_BIT_PAYLOAD_LENGTH}
}

proc update_MODELPARAM_VALUE.BRAM_DEPTH { MODELPARAM_VALUE.BRAM_DEPTH PARAM_VALUE.BRAM_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BRAM_DEPTH}] ${MODELPARAM_VALUE.BRAM_DEPTH}
}

proc update_MODELPARAM_VALUE.BRAM_ADDR_WIDTH { MODELPARAM_VALUE.BRAM_ADDR_WIDTH PARAM_VALUE.BRAM_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BRAM_ADDR_WIDTH}] ${MODELPARAM_VALUE.BRAM_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.BRAM_DATA_WIDTH { MODELPARAM_VALUE.BRAM_DATA_WIDTH PARAM_VALUE.BRAM_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BRAM_DATA_WIDTH}] ${MODELPARAM_VALUE.BRAM_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.BRAM_ADDR_WIDTH_IN_BYTE { MODELPARAM_VALUE.BRAM_ADDR_WIDTH_IN_BYTE PARAM_VALUE.BRAM_ADDR_WIDTH_IN_BYTE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BRAM_ADDR_WIDTH_IN_BYTE}] ${MODELPARAM_VALUE.BRAM_ADDR_WIDTH_IN_BYTE}
}

