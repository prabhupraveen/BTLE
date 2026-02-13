// Save this as debug_ctl.c and compile: gcc debug_ctl.c -o debug_ctl
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>

struct __attribute__((__packed__)) pcap_hdr {
    uint32_t magic_number; uint16_t v_maj; uint16_t v_min;
    int32_t zone; uint32_t sig; uint32_t snap; uint32_t network;
};

struct __attribute__((__packed__)) pcaprec_hdr {
    uint32_t ts_sec; uint32_t ts_usec; uint32_t incl_len; uint32_t orig_len;
};

int main(int argc, char *argv[]) {
    int sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    struct sockaddr_in saddr = {.sin_family = AF_INET, .sin_port = htons(50001), .sin_addr.s_addr = INADDR_ANY};
    bind(sockfd, (struct sockaddr*)&saddr, sizeof(saddr));

    struct pcap_hdr gh = {0xa1b2c3d4, 2, 4, 0, 0, 65535, 251};
    write(1, &gh, sizeof(gh));

    uint8_t buf[2048];
    while (1) {
        ssize_t n = recvfrom(sockfd, buf, sizeof(buf), 0, NULL, NULL);
        if (n <= 20) continue; // Skip header-only packets

        // Bypass all checks! 
        // We assume: [4b Magic][8b TS][4b AA][4b Len][Payload...]
        uint32_t aa = *(uint32_t*)(buf + 12);
        uint32_t payload_len = *(uint32_t*)(buf + 16);
        uint8_t *payload = buf + 20;

        struct pcaprec_hdr ph = {(uint32_t)time(NULL), 0, payload_len + 4, payload_len + 4};
        write(1, &ph, sizeof(ph));
        write(1, &aa, 4);
        write(1, payload, payload_len);
    }
    return 0;
}