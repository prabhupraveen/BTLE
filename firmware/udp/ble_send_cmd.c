// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2025 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <stdint.h>
#include <poll.h>

#include <sched.h>
#include <pthread.h>
#include <ctype.h>
#include <errno.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <sys/resource.h>

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

// #define DEBUG_PRINT(...) printf(__VA_ARGS__)
#define DEBUG_PRINT(...)

// Maximum message length that fits in a BLE ADV_NONCONN_IND Complete Local Name AD.
// BLE PDU payload max = 37 bytes. Layout: 6-byte AdvA + 3-byte Flags AD + 2-byte AD header for name
//   => 37 - 6 - 3 - 2 = 26 bytes of usable name.
#define BLE_MAX_ADV_NAME_LEN 26

int sockfd = -1;
struct sockaddr_in dest_addr;

volatile sig_atomic_t signal_stop = 0;

static inline void pin_to_cpu(int cpu_id) {
  cpu_set_t mask;
  CPU_ZERO(&mask);
  CPU_SET(cpu_id, &mask);
  if (sched_setaffinity(0, sizeof(mask), &mask) != 0) {
    perror("sched_setaffinity");
    exit(1);
  }
}

static inline void set_realtime_priority(void) {
  struct sched_param param;
  param.sched_priority = 99;
  if (sched_setscheduler(0, SCHED_FIFO, &param) != 0) {
    perror("sched_setscheduler");
    exit(1);
  }
}

static inline void handle_sigint(int sig) {
  signal_stop = 1;
  printf("Quitting...\n");
}

static inline uint64_t get_time_us() {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (uint64_t)ts.tv_sec * 1000000ULL + ts.tv_nsec / 1000;
}

static inline int udp_socket_init(const char *dest_ip, uint16_t dest_port) {
  int enable = 1;

  sockfd = socket(AF_INET, SOCK_DGRAM, 0);
  if (sockfd < 0) { perror("socket"); return -1; }

  if (setsockopt(sockfd, SOL_SOCKET, SO_BROADCAST, &enable, sizeof(enable)) != 0) {
    perror("setsockopt SO_BROADCAST");
    close(sockfd);
    return -1;
  }

  memset(&dest_addr, 0, sizeof(dest_addr));
  dest_addr.sin_family = AF_INET;
  dest_addr.sin_port = htons(dest_port);
  if (inet_pton(AF_INET, dest_ip, &dest_addr.sin_addr) != 1) {
    fprintf(stderr, "Invalid destination IP: %s\n", dest_ip);
    close(sockfd);
    return -1;
  }

  return 0;
}

static inline int udp_socket_send(uint32_t num_byte, uint8_t *packet_byte) {
  int send_result = sendto(sockfd, packet_byte, num_byte, 0,
                           (struct sockaddr*)&dest_addr, sizeof(dest_addr));
  if (send_result < 0)
    perror("sendto");
  return send_result;
}

static inline void print_usage() {
  printf("Usage: ble_send_cmd [options]\n");
  printf("\nRegister write options (control=0):\n");
  printf("  -n <channel>   Channel number (e.g. 37, 38, 39) -> register 11\n");
  printf("  -c <crc_init>  CRC init value (e.g. 0x555555)   -> register 12\n");
  printf("  -a <aa>        Access address (e.g. 0x8E89BED6) -> register 10\n");
  printf("\nTransmit options (control=1):\n");
  printf("  -m <message>   Transmit message as BLE ADV_NONCONN_IND advertisement\n");
  printf("                 Max %d characters. The AntSDR FPGA will broadcast it\n", BLE_MAX_ADV_NAME_LEN);
  printf("                 as a 'Complete Local Name' AD record, visible in Wireshark.\n");
  printf("\nNetwork options:\n");
  printf("  -t <ip>        Destination IPv4 address (default: 255.255.255.255)\n");
  printf("  -p <port>      Destination UDP port (default: 50000)\n");
}

// ---------------------------------------------------------------------------
// Build a BLE ADV_NONCONN_IND PDU into `pdu_out` and return its byte length.
//
// Wire format (all handled by FPGA PHY: preamble, AA, whitening, CRC):
//   [PDU hdr byte 0] [PDU hdr byte 1 = Length] [AdvA 6B] [AdvData ...]
//
// AdvData layout:
//   AD #1 – Flags:               02 01 06
//   AD #2 – Complete Local Name: (name_len+1) 09 <name bytes>
// ---------------------------------------------------------------------------
static inline uint32_t build_adv_pdu(const char *name, uint8_t *pdu_out) {
  uint8_t adv_addr[6] = {0x11, 0x22, 0x33, 0x44, 0x55, 0x66}; // static random address
  uint32_t name_len = strlen(name);
  if (name_len > BLE_MAX_ADV_NAME_LEN) {
    name_len = BLE_MAX_ADV_NAME_LEN;
    fprintf(stderr, "Warning: message truncated to %d characters\n", BLE_MAX_ADV_NAME_LEN);
  }

  // AdvData: [02 01 06] [name_len+1  09  <name>]
  uint32_t adv_data_len = 3 + 2 + name_len;  // Flags AD + Name AD header + name
  uint32_t pdu_payload_len = 6 + adv_data_len; // AdvA + AdvData

  uint32_t idx = 0;
  // PDU header
  pdu_out[idx++] = 0x02;            // PDU Type: ADV_NONCONN_IND, TxAdd=0, RxAdd=0
  pdu_out[idx++] = (uint8_t)pdu_payload_len;

  // AdvA (little-endian)
  memcpy(pdu_out + idx, adv_addr, 6);
  idx += 6;

  // AD #1 – Flags
  pdu_out[idx++] = 0x02;  // length
  pdu_out[idx++] = 0x01;  // type: Flags
  pdu_out[idx++] = 0x06;  // LE General Discoverable | BR/EDR Not Supported

  // AD #2 – Complete Local Name
  pdu_out[idx++] = (uint8_t)(name_len + 1); // length (type byte + name)
  pdu_out[idx++] = 0x09;                    // type: Complete Local Name
  memcpy(pdu_out + idx, name, name_len);
  idx += name_len;

  return idx; // total PDU bytes (header + payload, no CRC – FPGA appends it)
}

int main(int argc, char *argv[])
{
  unsigned long tmp;
  int opt;

  char dest_ip[64] = "255.255.255.255";
  uint16_t dest_port = 50000;
  uint32_t channel_number = 37;
  uint32_t crc_init = 0x555555;
  uint32_t unique_bit_seq = 0x8E89BED6;

  // Control-0 fields
  int reg_idx = -1;
  uint32_t reg_val = 0;

  // Control-1 (TX) fields
  char tx_message[BLE_MAX_ADV_NAME_LEN + 1] = {0};
  int do_tx = 0;

  const uint32_t magic_header_len = 4;
  const uint32_t timestamp_len    = 8;
  const uint32_t control_len      = 4;
  const uint32_t unit_field_len   = 4;

  uint8_t packet_byte[256] = {0};
  uint32_t num_byte, runtime_len;

  while ((opt = getopt(argc, argv, "t:p:n:c:a:m:")) != -1) {
    switch (opt) {
      case 't':
        strncpy(dest_ip, optarg, sizeof(dest_ip) - 1);
        dest_ip[sizeof(dest_ip) - 1] = '\0';
        break;
      case 'p':
        errno = 0;
        tmp = strtoul(optarg, NULL, 0);
        if (errno != 0 || tmp == 0 || tmp > 65535) {
          fprintf(stderr, "Invalid UDP port: %s\n", optarg);
          return EXIT_FAILURE;
        }
        dest_port = (uint16_t)tmp;
        break;
      case 'n':
        channel_number = atoi(optarg);
        reg_idx = 11;
        reg_val = channel_number;
        break;
      case 'c':
        errno = 0;
        tmp = (uint32_t)strtoul(optarg, NULL, 0);
        if (errno != 0 || tmp > 0xFFFFFFFFUL) {
          fprintf(stderr, "Invalid uint32 hex value: %s\n", optarg);
          return EXIT_FAILURE;
        }
        crc_init = (uint32_t)tmp;
        reg_idx = 12;
        reg_val = crc_init;
        break;
      case 'a':
        errno = 0;
        tmp = (uint32_t)strtoul(optarg, NULL, 0);
        if (errno != 0 || tmp > 0xFFFFFFFFUL) {
          fprintf(stderr, "Invalid uint32 hex value: %s\n", optarg);
          return EXIT_FAILURE;
        }
        unique_bit_seq = (uint32_t)tmp;
        reg_idx = 10;
        reg_val = unique_bit_seq;
        break;
      case 'm':
        strncpy(tx_message, optarg, BLE_MAX_ADV_NAME_LEN);
        tx_message[BLE_MAX_ADV_NAME_LEN] = '\0';
        do_tx = 1;
        break;
      default:
        print_usage();
        exit(EXIT_FAILURE);
    }
  }

  printf("Destination IP:   %s\n", dest_ip);
  printf("Destination port: %u\n", dest_port);

  pin_to_cpu(1);
  set_realtime_priority();

  if (udp_socket_init(dest_ip, dest_port) != 0)
    return EXIT_FAILURE;

  signal(SIGINT,  handle_sigint);
  signal(SIGTERM, handle_sigint);
  __sync_synchronize();

  // -------------------------------------------------------------------------
  // Control = 0 : register write (unchanged behaviour)
  // -------------------------------------------------------------------------
  if (reg_idx >= 0) {
    runtime_len = 0;
    ((uint32_t*)(packet_byte + runtime_len))[0] = 0x64838364;
    runtime_len += magic_header_len;

    ((uint64_t*)(packet_byte + runtime_len))[0] = get_time_us();
    runtime_len += timestamp_len;

    ((uint32_t*)(packet_byte + runtime_len))[0] = 0; // control = 0: reg write
    runtime_len += control_len;

    ((uint32_t*)(packet_byte + runtime_len))[0] = (uint32_t)reg_idx;
    runtime_len += unit_field_len;

    ((uint32_t*)(packet_byte + runtime_len))[0] = reg_val;
    runtime_len += unit_field_len;

    num_byte = runtime_len;
    if (udp_socket_send(num_byte, packet_byte) >= 0) {
      printf("cmd sent at (us) %llu\n", (unsigned long long)get_time_us());
      printf("write 0x%08X to register %d\n", reg_val, reg_idx);
    }
  }

  // -------------------------------------------------------------------------
  // Control = 1 : transmit BLE advertisement packet
  // -------------------------------------------------------------------------
  if (do_tx) {
    // Build the BLE PDU on the PC so the link layer can inspect / log it,
    // but btle_ll.c will re-build it server-side from the raw message to keep
    // the ARM-side in control of PDU details (whitening, channel, CRC init).
    // We send: [magic][timestamp][control=1][pdu_len(4B)][pdu_bytes]

    uint8_t pdu_buf[64];
    uint32_t pdu_len = build_adv_pdu(tx_message, pdu_buf);

    runtime_len = 0;
    ((uint32_t*)(packet_byte + runtime_len))[0] = 0x64838364; // magic
    runtime_len += magic_header_len;

    ((uint64_t*)(packet_byte + runtime_len))[0] = get_time_us(); // timestamp
    runtime_len += timestamp_len;

    ((uint32_t*)(packet_byte + runtime_len))[0] = 1; // control = 1: TX
    runtime_len += control_len;

    ((uint32_t*)(packet_byte + runtime_len))[0] = pdu_len; // PDU byte count
    runtime_len += unit_field_len;

    memcpy(packet_byte + runtime_len, pdu_buf, pdu_len); // PDU bytes
    runtime_len += pdu_len;

    num_byte = runtime_len;
    if (udp_socket_send(num_byte, packet_byte) >= 0) {
      printf("TX cmd sent at (us) %llu\n", (unsigned long long)get_time_us());
      printf("BLE ADV_NONCONN_IND PDU (%u bytes):\n", pdu_len);
      for (uint32_t i = 0; i < pdu_len; i++)
        printf("  [%02u] 0x%02X  %c\n", i, pdu_buf[i], isprint(pdu_buf[i]) ? pdu_buf[i] : '.');
      printf("Message: \"%s\"\n", tx_message);
    }
  }

  if (reg_idx < 0 && !do_tx) {
    printf("No command to send. Use -n/-c/-a for register writes or -m for TX.\n");
    print_usage();
  }

  close(sockfd);
  return EXIT_SUCCESS;
}