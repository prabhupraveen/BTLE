import numpy as np
import os
import btlelib as bl
import random
import shutil

# --- Configuration ---
BASE_SAVE_DIR = '../verilog/test_vectors_batch'
SNR_DEFAULT = 25      # High SNR for clean reference
PPM_DEFAULT = 5.0     # Small frequency offset for realistic testing

def clear_and_prepare_dir(directory):
    """Creates a clean directory for the test vectors."""
    if os.path.exists(directory):
        shutil.rmtree(directory)
    os.makedirs(directory, exist_ok=True)

def generate_packet_files(case_name, channel, access_addr, crc_init_hex, pdu_hex, phy_mode='1M', is_random=False):
    """
    Generates a full suite of TX and RX files for a specific packet configuration.
    """
    # Set PHY mode
    bl.set_phy_mode(phy_mode)
    
    case_dir = os.path.join(BASE_SAVE_DIR, f'{case_name}_{phy_mode}')
    os.makedirs(case_dir, exist_ok=True)
    
    # Configure btlelib for this specific run
    bl.SAVE_FOR_VERILOG = 1
    bl.SAVE_DIR = case_dir
    
    crc_init_bit = bl.hex_string_to_bit(crc_init_hex)
    pdu_bit = bl.hex_string_to_bit(pdu_hex)
    
    print(f"Generating Case: {case_name} ({phy_mode}) | Chan: {channel} | AA: {access_addr} | CRCInit: {crc_init_hex}")

    # 1. Save Meta Config
    with open(os.path.join(case_dir, 'btle_config.txt'), 'w') as f:
        f.write(f"{len(pdu_bit):x}\n")
        f.write(f"{channel:x}\n")
        f.write(f"{crc_init_hex}\n")
        f.write(f"{access_addr}\n")
        f.write(f"{phy_mode}\n")

    # 2. Save raw input PDU bits
    bl.bit_to_txt_octet_per_line(pdu_bit, os.path.join(case_dir, 'btle_tx_test_input.txt'))

    # 3. Generate TX Samples (Golden Reference)
    tx_i, tx_q, phy_bit, _ = bl.btle_tx(pdu_bit, channel, crc_init_bit, access_addr)
    np.savetxt(os.path.join(case_dir, 'btle_tx_test_output_i_ref.txt'), tx_i, fmt='%d')
    np.savetxt(os.path.join(case_dir, 'btle_tx_test_output_q_ref.txt'), tx_q, fmt='%d')

    # 4. Simulate Channel & Generate RX Input
    # Add small delay, freq offset and noise
    tx_i_err, tx_q_err, _, _ = bl.add_freq_sampling_error(tx_i, tx_q, PPM_DEFAULT)
    rx_i, rx_q = bl.add_noise(tx_i_err, tx_q_err, SNR_DEFAULT)
    
    np.savetxt(os.path.join(case_dir, 'btle_rx_test_input_i.txt'), np.int16(rx_i), fmt='%d')
    np.savetxt(os.path.join(case_dir, 'btle_rx_test_input_q.txt'), np.int16(rx_q), fmt='%d')

    # 5. "Solve" the decoding path to provide Golden RX results
    rx_pdu_bit, crc_ok, _, _, _, _, _ = bl.btle_rx(rx_i, rx_q, channel, crc_init_bit, access_addr)
    
    # Save results
    np.savetxt(os.path.join(case_dir, 'btle_rx_test_output_crc_ok_ref.txt'), [int(crc_ok)], fmt='%d')
    bl.bit_to_txt_octet_per_line(rx_pdu_bit, os.path.join(case_dir, 'btle_rx_test_output_ref.txt'))
    
    if not crc_ok and not is_random:
        print(f"  [!] Warning: CRC failed for golden case {case_name} ({phy_mode})")
    else:
        print(f"  [✓] OK: CRC passed for {case_name} ({phy_mode})")

def get_random_hex(length):
    return ''.join(random.choice('0123456789ABCDEF') for _ in range(length))

if __name__ == "__main__":
    clear_and_prepare_dir(BASE_SAVE_DIR)
    
    # --- Part 1: Specific Golden Tests (both 1M and 2M) ---
    golden_cases = [
        {
            "name": "case0_adv_ch37",
            "chan": 37,
            "aa": "D6BE898E",
            "crc": "555555",
            "pdu": "422006050403020119095344522f426c7565746f6f74682f4c6f772f456e65726779"
        },
        {
            "name": "case1_conn_update_ch9",
            "chan": 9,
            "aa": "1B0A8560",
            "crc": "A77B22",
            "pdu": "030c00020f0e50040706d007ffee"
        },
        {
            "name": "case2_data_ch10",
            "chan": 10,
            "aa": "1B0A8511",
            "crc": "123456",
            "pdu": "0100"
        }
    ]

    print("=" * 60)
    print("Generating 1M mode test vectors...")
    print("=" * 60)
    for case in golden_cases:
        generate_packet_files(case["name"], case["chan"], case["aa"], case["crc"], case["pdu"], phy_mode='1M')

    print("\n" + "=" * 60)
    print("Generating 2M mode test vectors...")
    print("=" * 60)
    for case in golden_cases:
        generate_packet_files(case["name"], case["chan"], case["aa"], case["crc"], case["pdu"], phy_mode='2M')

    print(f"\nDone. All test vectors are in: {os.path.abspath(BASE_SAVE_DIR)}")
    print("\nDirectory structure:")
    for mode in ['1M', '2M']:
        for case in golden_cases:
            print(f"  {case['name']}_{mode}/")
