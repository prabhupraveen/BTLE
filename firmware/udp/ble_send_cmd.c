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

int sockfd = -1;
struct sockaddr_in dest_addr;

volatile sig_atomic_t signal_stop = 0;  // flag set by signal handler

static inline void pin_to_cpu(int cpu_id) {
  cpu_set_t mask;
  CPU_ZERO(&mask);
  CPU_SET(cpu_id, &mask);
  if (sched_setaffinity(0, sizeof(mask), &mask) != 0) {
    perror("sched_setaffinity");
    exit(1);
  }
  DEBUG_PRINT(printf("Pinned to CPU %d\n", cpu_id);)
}

static inline void set_realtime_priority(void) {
  struct sched_param param;
  param.sched_priority = 99;  // Highest RT prio
  if (sched_setscheduler(0, SCHED_FIFO, &param) != 0) {
    perror("sched_setscheduler");
    exit(1);
  }
  DEBUG_PRINT(printf("Real-time priority set (SCHED_FIFO, prio 99)\n");)
}

static inline void handle_sigint(int sig) {
  signal_stop = 1;  // just set the flag, keep it simple & async-signal-safe

  // if (write(fd_uio0, &tmp_for_irq_re_arm, sizeof(tmp_for_irq_re_arm)) != sizeof(tmp_for_irq_re_arm)) {
  //   perror("write");
  // }

  printf("Quitting...\n");
}

static inline uint64_t get_time_us() {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts); // Monotonic: not affected by system clock changes
  return (uint64_t)ts.tv_sec * 1000000ULL + ts.tv_nsec / 1000;
}

static inline uint32_t get_time_s() {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts); // Monotonic: not affected by system clock changes
  return (uint32_t)ts.tv_sec;
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
  printf("Usage: ble_send_cmd\n");
  printf("  -t target IPv4 address : example 192.168.1.10 (default: 255.255.255.255)\n");
  printf("  -p target UDP port : example 50000 (default: 50000)\n");
  printf("  -n channel number : such as 37, 38, 39, etc.\n");
  printf("  -c CRC init value : such as 0x555555\n");
  printf("  -a access address : such as 0x8E89BED6\n");
}

int main(int argc, char *argv[])
{
  unsigned long tmp;
  int opt, reg_idx = -1;

  char dest_ip[64] = "255.255.255.255";
  uint16_t dest_port = 50000;
  uint32_t channel_number = 37; // default to channel 37
  uint32_t crc_init = 0x555555; // default to 0x555555
  uint32_t unique_bit_seq = 0x8E89BED6; // default to 0x8E89BED6
  uint32_t reg_val = 0;

  const uint32_t magic_header_len = 4;
  const uint32_t timestamp_len = 8;
  const uint32_t control_len = 4;
  const uint32_t unit_field_len = 4;

  uint8_t packet_byte[64] = {0,1,2,3,4,5,6};
  uint32_t num_byte = magic_header_len + timestamp_len + control_len + 2*unit_field_len;
  uint32_t runtime_len;

  while ((opt = getopt(argc, argv, "t:p:n:c:a:")) != -1) {
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
      default:
        print_usage();
        exit(EXIT_FAILURE);
    }
  }
  printf("Destination IP: %s\n", dest_ip);
  printf("Destination UDP port: %u\n", dest_port);
  // printf("Channel number: %u\n", channel_number);
  // printf("CRC init: 0x%06X\n", crc_init);
  // printf("Access address: 0x%08X\n", unique_bit_seq);

  pin_to_cpu(1);            // Bind to CPU1
  set_realtime_priority();  // RT scheduling
  
  if (udp_socket_init(dest_ip, dest_port) != 0) {
    return -1;
  }

  signal(SIGINT, handle_sigint);
  signal(SIGTERM, handle_sigint);

  __sync_synchronize();

  // while (!signal_stop) {

  if (reg_idx >= 0) {
    runtime_len = 0;
    // 4 bytes magic header
    ((uint32_t*)(packet_byte + runtime_len))[0] = 0x64838364;

    runtime_len = runtime_len + magic_header_len;
    // 8 bytes timestamp
    ((uint64_t*)(packet_byte + runtime_len))[0] = get_time_us();

    runtime_len = runtime_len + timestamp_len;
    // 4 bytes control
    ((uint32_t*)(packet_byte + runtime_len))[0] = 0; // 0 for register write

    runtime_len = runtime_len + control_len;
    // 4 bytes unit_field0
    ((uint32_t*)(packet_byte + runtime_len))[0] = reg_idx; // register index
    runtime_len = runtime_len + unit_field_len;
    // 4 bytes unit_field1
    ((uint32_t*)(packet_byte + runtime_len))[0] = reg_val; // register value

    num_byte = runtime_len + unit_field_len;
    if (udp_socket_send(num_byte, packet_byte) < 0) {
      // break;
    }
    printf("cmd sent at (us) %llu\n", (unsigned long long)get_time_us());
    printf("write %u (0x%08X) to register %d\n", reg_val, reg_val, reg_idx);
  } else {
    printf("No register setting to send.\n");
  }

  //   break;
  // }

  DEBUG_PRINT(printf("num_byte %d\n", num_byte);)

  close(sockfd);

  return(0);
}
