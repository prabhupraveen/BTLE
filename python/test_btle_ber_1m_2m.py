# Author: Xianjun Jiao + 2M mode
# SPDX-FileCopyrightText: 2024 Xianjun Jiao
# SPDX-License-Identifier: Apache-2.0 license

import numpy as np
import matplotlib.pyplot as plt
import btlelib as bl
import sys

if __name__ == "__main__":
  ppm_value = 0
  phy_mode = '1M'  # Default to 1M

  print('arguments: ppm_value phy_mode(1M|2M)')
  
  if len(sys.argv) == 2:
    ppm_value = float(sys.argv[1])
    if ppm_value > 50.0:
      print('ppm_value input should be within -50 ~ 50!')
      exit()
  elif len(sys.argv) == 3:
    ppm_value = float(sys.argv[1])
    phy_mode = sys.argv[2]
    if ppm_value > 50.0:
      print('ppm_value input should be within -50 ~ 50!')
      exit()
  
  print([ppm_value, phy_mode])

  # Set PHY mode
  bl.set_phy_mode(phy_mode)

  channel_number = 37
  pdu_bit_in_hex = '422506050403020119095344522f426c7565746f6f74682f4c6f772f456e657267791234567890' # ADV payload length 37

  ppm_abs = np.array([0,  10, 20, 25, 30, 35, 40, 45, 50])
  max_snr = np.array([11, 12, 13, 14, 15, 17, 19, 21, 26])
  snr = np.interp(np.abs(ppm_value), ppm_abs, max_snr)

  snr_set = [snr-4, snr-2.5, snr-1, snr]
  ber_set = [-1, -1, -1, -1]
  pkt_count_set = [100, 200, 300, 300]
  print('snr_set ', snr_set)
  print('pkt_count_set ', pkt_count_set)

  snr_idx = 0
  for snr in snr_set:
    num_bit_total = 0
    num_bit_err = 0

    for idx in range(pkt_count_set[snr_idx]):
      pdu_bit = bl.hex_string_to_bit(pdu_bit_in_hex)
      pdu_bit[16:] = np.int8(np.random.randint(2, size=len(pdu_bit)-16)) # generate random payload

      # generate tx packet iq sample
      tx_i, tx_q, _, _ = bl.btle_tx(pdu_bit, channel_number)

      # add sampling frequency offset, carrier frequency offset
      tx_i_error, tx_q_error, _, fo = bl.add_freq_sampling_error(tx_i, tx_q, ppm_value)

      # add AWGN noise
      rx_i, rx_q = bl.add_noise(tx_i_error, tx_q_error, snr)

      # receiver decodes signal from channel
      rx_pdu_bit, crc_ok, _, _, _, _, _ = bl.btle_rx(rx_i, rx_q, channel_number)

      num_bit_total = num_bit_total + len(pdu_bit)

      if not crc_ok:
        if len(rx_pdu_bit) == 0:
          num_bit_err = num_bit_err + len(pdu_bit)
        else:
          min_len = min(len(pdu_bit), len(rx_pdu_bit))
          num_bit_err = num_bit_err + np.sum(pdu_bit[0:min_len] != rx_pdu_bit[0:min_len])

    ber = num_bit_err/num_bit_total
    print(f'ppm {ppm_value} freq offset {fo} Hz snr {snr} dB ber {ber} num_bit_total {num_bit_total} num_bit_err {num_bit_err} ({phy_mode})')

    ber_set[snr_idx] = ber
    snr_idx = snr_idx + 1

  plt.figure(0)
  plt.semilogy(snr_set, ber_set, 'b+-')
  plt.title(f'BER (Bit Error Rate) with ppm {ppm_value} ({phy_mode})')
  plt.xlabel('SNR(dB)')
  plt.ylabel('BER')
  plt.grid()
  plt.show()

  np.savetxt(f'snr_set_{phy_mode}.txt', snr_set, fmt='%f')
  np.savetxt(f'ber_set_{phy_mode}.txt', ber_set, fmt='%f')
