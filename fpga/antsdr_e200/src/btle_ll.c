// Author: Reconstructed Zynq Bridge
// Target: Zynq AntSDR E200
// Features: Bidirectional (Host Command -> FPGA) && (FPGA IRQ -> Host Data)

#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sched.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <netinet/ether.h>
#include <arpa/inet.h>
#include <linux/if_packet.h>
#include <poll.h>
#include <time.h>

// Configuration
#define UIO_DEV "/dev/uio0"
#define ETH_P_CUSTOM 0x88B5
#define ISOLATED_CPU 1

// Magic Headers (Must match Host Code)
#define MAGIC_CMD_RX     0x64838364 // Host -> Zynq
#define MAGIC_DATA_TX    0x05628562 // Zynq -> Host (Sniffed Data)
#define MAGIC_ACK_TX     0x19293811 // Zynq -> Host (ACK)

// Global pointers
volatile uint32_t *fpga_regs;
int uio_fd;
int sock_fd;
size_t map_size_global = 0x1000;

// Ethernet Buffer
uint8_t tx_buffer[2048];
struct sockaddr_ll dest_addr;

// ---------------------------------------------------------------------------
// Helper: Get Monotonic Time (us)
// ---------------------------------------------------------------------------
static inline uint64_t get_time_us() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000000ULL + ts.tv_nsec / 1000;
}

// ---------------------------------------------------------------------------
// Helper: Setup Destination Address (Broadcast or specific)
// ---------------------------------------------------------------------------
void setup_dest_addr(int ifindex) {
    memset(&dest_addr, 0, sizeof(dest_addr));
    dest_addr.sll_family = AF_PACKET;
    dest_addr.sll_ifindex = ifindex;
    dest_addr.sll_halen = ETH_ALEN;
    // Default to Broadcast FF:FF:FF:FF:FF:FF
    memset(dest_addr.sll_addr, 0xFF, 6); 
    dest_addr.sll_protocol = htons(ETH_P_CUSTOM);
}

// ---------------------------------------------------------------------------
// Helper: Pin CPU
// ---------------------------------------------------------------------------
void pin_to_cpu(int cpu_id) {
    cpu_set_t mask;
    CPU_ZERO(&mask);
    CPU_SET(cpu_id, &mask);
    sched_setaffinity(0, sizeof(mask), &mask);
}

// ---------------------------------------------------------------------------
// Helper: Configure IRQ Affinity
// ---------------------------------------------------------------------------
int configure_irq_affinity(int cpu_id) {
    int irq = -1;
    char path[256];
    
    // Quick scan for IRQ
    FILE *fp = fopen("/proc/interrupts", "r");
    if (fp) {
        char line[512];
        while (fgets(line, sizeof(line), fp)) {
            if (strstr(line, "btle_controller")) {
                char *p = line;
                while (*p == ' ') p++;
                irq = atoi(p);
                break;
            }
        }
        fclose(fp);
    }

    if (irq > 0) {
        sprintf(path, "/proc/irq/%d/smp_affinity", irq);
        int afd = open(path, O_WRONLY);
        if (afd >= 0) {
            uint32_t mask = (1 << cpu_id);
            dprintf(afd, "%x", mask);
            close(afd);
            printf("IRQ %d pinned to CPU %d\n", irq, cpu_id);
        }
    }
    return 0;
}

// ---------------------------------------------------------------------------
// Helper: Init UIO with Auto-Size
// ---------------------------------------------------------------------------
int uio_init() {
    char size_path[64];
    char size_buf[32];
    
    snprintf(size_path, sizeof(size_path), "/sys/class/uio/uio0/maps/map0/size");
    FILE *f = fopen(size_path, "r");
    if (f) {
        if (fgets(size_buf, sizeof(size_buf), f)) map_size_global = strtoul(size_buf, NULL, 0);
        fclose(f);
    }

    uio_fd = open(UIO_DEV, O_RDWR | O_SYNC);
    if (uio_fd < 0) { perror("UIO open failed"); return -1; }

    void *map = mmap(NULL, map_size_global, PROT_READ | PROT_WRITE, MAP_SHARED, uio_fd, 0);
    if (map == MAP_FAILED) { perror("mmap failed"); return -1; }

    fpga_regs = (volatile uint32_t *)map;
    printf("FPGA mapped (Size: 0x%zx)\n", map_size_global);
    return 0;
}

// ---------------------------------------------------------------------------
// Helper: Init Network
// ---------------------------------------------------------------------------
int net_init(const char *ifname) {
    struct ifreq if_idx;
    sock_fd = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_CUSTOM));
    if (sock_fd < 0) return -1;

    memset(&if_idx, 0, sizeof(struct ifreq));
    strncpy(if_idx.ifr_name, ifname, IFNAMSIZ - 1);
    if (ioctl(sock_fd, SIOCGIFINDEX, &if_idx) < 0) return -1;

    struct sockaddr_ll sll;
    memset(&sll, 0, sizeof(sll));
    sll.sll_family = AF_PACKET;
    sll.sll_ifindex = if_idx.ifr_ifindex;
    sll.sll_protocol = htons(ETH_P_CUSTOM);

    if (bind(sock_fd, (struct sockaddr *)&sll, sizeof(sll)) < 0) return -1;
    
    setup_dest_addr(if_idx.ifr_ifindex);
    return 0;
}

// ---------------------------------------------------------------------------
// CRITICAL: Handle FPGA Interrupt (Send Data to Host)
// ---------------------------------------------------------------------------
void handle_fpga_irq() {
    uint32_t irq_count;
    // 1. Acknowledge IRQ in UIO driver (Blocking read unblocks now)
    read(uio_fd, &irq_count, 4);

    // 2. READ DATA FROM FPGA
    // IMPORTANT: Since we don't have the exact register map, we infer from
    // standard design. Usually, there's a Status Reg, Length Reg, and Data FIFO.
    // 
    // Hypothesized Layout based on host code expectation:
    // Reg[0]: Status / IRQ Clear
    // Reg[1]: Header/CRC Length
    // Reg[2]: Access Address
    // Reg[3+]: Payload Data (or a single FIFO register read repeatedly)
    
    // NOTE: This part might need adjustment if the packet comes out garbled.
    // We will construct the packet format the Host expects:
    // [EtherHeader] [Magic: 0x05628562] [Timestamp: 8B] [AccAddr: 4B] [Len: 4B] [Payload...]
    
    uint32_t pkt_len = 0;
    
    // Prepare Ethernet Header
    struct ether_header *eh = (struct ether_header *)tx_buffer;
    // Note: We leave dest/src MAC as set in setup, just ensure type
    eh->ether_type = htons(ETH_P_CUSTOM);
    
    uint32_t offset = sizeof(struct ether_header);
    
    // Write Magic
    *((uint32_t *)(tx_buffer + offset)) = MAGIC_DATA_TX;
    offset += 4;
    
    // Write Timestamp
    *((uint64_t *)(tx_buffer + offset)) = get_time_us();
    offset += 8;
    
    // Read Access Address from FPGA (Assuming Reg 2, or cached)
    // For now, let's read Reg 10 (Unique Seq) as the user sets it there?
    // Or Reg 2 if it's capture. Let's assume Reg 2 contains captured AA.
    uint32_t access_addr = fpga_regs[2]; 
    *((uint32_t *)(tx_buffer + offset)) = access_addr;
    offset += 4;
    
    // Read Length from FPGA (Assuming Reg 1)
    uint32_t payload_crc_len = fpga_regs[1]; 
    // Sanity check length (e.g., max 255 bytes)
    if (payload_crc_len > 255) payload_crc_len = 0; 
    
    *((uint32_t *)(tx_buffer + offset)) = payload_crc_len;
    offset += 4;
    
    // Read Payload
    // If FPGA has a FIFO at Reg 3:
    uint32_t *payload_ptr = (uint32_t *)(tx_buffer + offset);
    
    // Copy loop (Reading word by word from FPGA FIFO or RAM)
    // Assuming data is available in a memory window starting at Reg 4 (offset 0x10)
    for (int i = 0; i < (payload_crc_len + 3) / 4; i++) {
        payload_ptr[i] = fpga_regs[4 + i]; 
    }
    
    offset += payload_crc_len;
    
    // 3. Send to Host
    sendto(sock_fd, tx_buffer, offset, 0, (struct sockaddr*)&dest_addr, sizeof(dest_addr));
    
    // 4. Re-enable UIO Interrupt
    uint32_t enable = 1;
    write(uio_fd, &enable, 4);
    
    // 5. Clear FPGA IP Interrupt (If required by hardware, e.g., write 1 to Reg 0)
    fpga_regs[0] = 1; 
}

// ---------------------------------------------------------------------------
// Handle Network Packet (Host Command)
// ---------------------------------------------------------------------------
void handle_network_packet(uint8_t *buf, ssize_t len) {
    if (len < (sizeof(struct ether_header) + 4)) return;
    
    struct ether_header *eh = (struct ether_header *)buf;
    if (eh->ether_type != htons(ETH_P_CUSTOM)) return;
    
    uint8_t *payload = buf + sizeof(struct ether_header);
    uint32_t magic = *((uint32_t *)payload);
    
    if (magic == MAGIC_CMD_RX) {
        // [Magic] [Timestamp] [Control] [RegIndex] [RegValue]
        // Offset: 0       4          12        16         20
        
        if (len >= (sizeof(struct ether_header) + 24)) {
            uint32_t idx = *((uint32_t *)(payload + 16));
            uint32_t val = *((uint32_t *)(payload + 20));
            
            // Bounds check
            if (idx < (map_size_global/4)) {
                fpga_regs[idx] = val; // Write to FPGA
                
                // Send ACK back to host
                // Reuse TX buffer
                struct ether_header *tx_eh = (struct ether_header *)tx_buffer;
                tx_eh->ether_type = htons(ETH_P_CUSTOM);
                *((uint32_t *)(tx_buffer + sizeof(struct ether_header))) = MAGIC_ACK_TX;
                sendto(sock_fd, tx_buffer, sizeof(struct ether_header) + 4, 0, 
                       (struct sockaddr*)&dest_addr, sizeof(dest_addr));
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
int main(int argc, char *argv[]) {
    struct pollfd fds[2];
    uint8_t rx_buffer[2048];
    char ifname[32] = "eth0";

    int opt;
    while ((opt = getopt(argc, argv, "i:")) != -1) {
        if (opt == 'i') strncpy(ifname, optarg, 31);
    }

    printf("Starting Bidirectional Bridge on %s...\n", ifname);

    pin_to_cpu(ISOLATED_CPU);
    
    if (uio_init() < 0) return 1;
    configure_irq_affinity(ISOLATED_CPU);
    if (net_init(ifname) < 0) return 1;

    // Enable UIO IRQ initially
    uint32_t enable = 1;
    write(uio_fd, &enable, 4);

    // Setup Poll
    // fds[0] = Network Socket
    fds[0].fd = sock_fd;
    fds[0].events = POLLIN;
    
    // fds[1] = UIO (Hardware Interrupt)
    fds[1].fd = uio_fd;
    fds[1].events = POLLIN;

    while (1) {
        int ret = poll(fds, 2, -1); // Infinite timeout
        if (ret > 0) {
            
            // Check Network (Host sent a command)
            if (fds[0].revents & POLLIN) {
                ssize_t n = recvfrom(sock_fd, rx_buffer, sizeof(rx_buffer), 0, NULL, NULL);
                if (n > 0) handle_network_packet(rx_buffer, n);
            }
            
            // Check FPGA (Hardware Interrupt)
            if (fds[1].revents & POLLIN) {
                handle_fpga_irq();
            }
        }
    }

    close(sock_fd);
    close(uio_fd);
    return 0;
}