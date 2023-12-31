#ifndef NET_TT_NET_TTNET_BASE_BASIC_REQUEST_INFO_H_
#define NET_TT_NET_TTNET_BASE_BASIC_REQUEST_INFO_H_

#include <stdint.h>
#include "net/base/net_export.h"

namespace net {

struct TTNET_IMPLEMENT_EXPORT NET_EXPORT TTNetBasicRequestInfo {
  TTNetBasicRequestInfo();
  TTNetBasicRequestInfo(const TTNetBasicRequestInfo& other);
  ~TTNetBasicRequestInfo();

  bool is_background{false};
  int16_t start_net_type{-1};
  int16_t end_net_type{-1};

  int64_t start_ts{-1};

  int16_t retry_attempts{-1};
  int64_t sent_bytes{-1};

  int32_t dns{-1};
  int32_t tcp{-1};
  int32_t ssl{-1};
  int32_t send{-1};
  int32_t proxy{-1};
  int32_t ttfb{-1};
  int32_t header_recv{-1};
  int32_t body_recv{-1};

  int32_t edge{-1};
  int32_t origin{-1};
  int32_t inner{-1};
  int32_t rtt{-1};

  int16_t code{0};
  int64_t received_bytes{-1};
  int32_t duration{-1};

  int32_t http_rtt{-1};
  int32_t tcp_rtt{-1};
  int32_t downlink_throughput{-1};

  int16_t effective_net_type{-1};
  uint64_t pending_requests{0};
  uint64_t total_requests{0};
};

}  // namespace net

#endif  // NET_TT_NET_TTNET_BASE_BASIC_REQUEST_INFO_H_
