#ifndef NET_TT_NET_NET_DETECT_BASE_TT_TCPIP_PROTOCOL_
#define NET_TT_NET_NET_DETECT_BASE_TT_TCPIP_PROTOCOL_

#include <string>

#if defined(OS_WIN)
#include <WS2tcpip.h>
#include <WinSock2.h>
#else
#include <arpa/inet.h>
#include <netdb.h>
#include <netinet/in.h>
#endif

#include <errno.h>
#include <fcntl.h>

namespace net {

namespace ttnet {

#define ICMP_ECHOREPLY_V4 0
#define ICMP_ECHOREPLY_V6 129
#define ICMP_ECHO_V4 8
#define ICMP_ECHO_V6 128
#define ICMP_TIMXCEED_V4 11
#define ICMP_TIMXCEED_V6 3
#define ICMP_TIMXCEED_INTRANS 0

#if defined(OS_APPLE)
#define IPV6_RECVHOPLIMIT 37
#endif

#define IPV6_HEADER_LENGTH 40

struct TTUdpSocketErrorMsg {
  TTUdpSocketErrorMsg();
  TTUdpSocketErrorMsg(const TTUdpSocketErrorMsg&);
  ~TTUdpSocketErrorMsg();

  size_t ret_hops{0};
  bool is_localhost{false};
  std::string reply_src_ip;
  int ret{-1};
  std::string ret_msg;

  std::string echo_dest_ip;
  uint16_t trace_id{0};
  uint16_t trace_seq{0};
};

struct IPv4Header {
  uint8_t versionAndHeaderLength;
  uint8_t differentiatedServices;
  uint16_t totalLength;
  uint16_t identification;
  uint16_t flagsAndFragmentOffset;
  uint8_t timeToLive;
  uint8_t protocol;
  uint16_t headerChecksum;
  struct in_addr sourceAddress;
  struct in_addr destinationAddress;
};
typedef struct IPv4Header IPv4Header;

struct IPv6Header {
  uint8_t versionAndPriority;
  uint8_t serviceType;
  uint16_t flowLabel;
  uint16_t totalLength;
  uint8_t nextHeader;
  uint8_t timeToLive;
  struct in6_addr sourceAddress;
  struct in6_addr destinationAddress;
};
typedef struct IPv6Header IPv6Header;

struct ICMPHeader {
  uint8_t type;
  uint8_t code;
  uint16_t checksum;
  uint16_t identifier;
  uint16_t sequenceNumber;
};
typedef struct ICMPHeader ICMPHeader;

struct ICMPPayload {
  uint16_t identifier;
  uint16_t sequenceNumber;
  int64_t echotime;
};
typedef struct ICMPPayload ICMPPayload;

struct UdpHeader {
  uint16_t srouce_port;
  uint16_t destination_port;
  uint16_t length;
  uint16_t checksum;
};
typedef struct UdpHeader UdpHeader;

const int ICMP_PKG_SIZE = sizeof(ICMPHeader) + sizeof(ICMPPayload);

void CreateIcmpPkg(char* icmp_pkg,
                   size_t pkg_len,
                   int64_t echo_time,
                   uint16_t ping_id,
                   uint16_t ping_seq,
                   bool icmp_v6 = false);

}  // namespace ttnet
}  // namespace net

#endif // NET_TT_NET_NET_DETECT_TT_TCPIP_PROTOCOL_
