# crc24

## Description
This is the top-level controller(of CRC24) and state machine. It manages the timing and flow of data into and out of the core.
- **Preamble Skipping**: It tracks the number of incoming bits and ignores the first 40 bits (the Bluetooth Preamble and Access Address), as these are not included in the CRC calculation.  
- **Data Passthrough**: During the "Input" phase, it passes the original data bits directly to the output while simultaneously feeding them into the crc24_core for calculation.  
- **Checksum Appending**: Once the last bit of payload data is processed, the module switches to a CRC_BIT_OUTPUT state. It then shifts out the final 24-bit calculated CRC from the LFSR, effectively appending the checksum to the end of the data stream.  
- **Timing Management**: It includes a clock counter to handle internal timing, ensuring bits are output at the correct intervals relative to the system clock.  

## Inputs
- clk
- rst
- crc_state_init_bit
- crc_state_init_bit_load
- info_bit
- info_bit_valid
- info_bit_valid_last

## Outputs
- info_bit_after_crc24
- info_bit_after_crc24_valid
- info_bit_after_crc24_valid_last

## Calls
- [crc24_core](crc24_core.md)

## Called By
- [btle_tx](btle_tx.md)

## State Machine
- **IDLE**: Wait for data.
- **SKIP**: Count 40 bits of header/preamble without triggering the CRC core.  
- **WORK_ON_INPUT**: Pass data bits to the output and the CRC core.  
- **CRC_BIT_OUTPUT**: Stop taking input and output the 24 bits stored in the LFSR.