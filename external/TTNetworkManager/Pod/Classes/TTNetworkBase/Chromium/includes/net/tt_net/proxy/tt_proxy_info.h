#ifndef NET_TTNET_PROXY_TT_PROXY_INFO_H_
#define NET_TTNET_PROXY_TT_PROXY_INFO_H_

#include <string>
#include "base/callback.h"

namespace net {

class TTNetProxyInfo {
 public:
  TTNetProxyInfo();
  ~TTNetProxyInfo();
  TTNetProxyInfo(const TTNetProxyInfo& ttnet_proxy_info);

  // Identify whether it is a ttnet proxy request.
  bool is_ttnet_proxy_enabled{false};

  bool is_ttnet_proxy_fallback{false};

  // For https proxy
  int ttnet_proxy_http_connect_code{-1};

  int ttnet_proxy_http_connect_time{0};

  int ttnet_proxy_authentication_time{0};

  int ttnet_proxy_dns_time{0};

  int ttnet_proxy_route_time{0};

  std::string ttnet_proxy_logid;

  std::string ttnet_proxy_msg;

  // For http proxy
  std::string ttnet_proxy_time;

  std::string ttnet_proxy_cache;

  std::string ttnet_proxy_error;
};

typedef base::Callback<void(TTNetProxyInfo ttNetProxyInfo)>
    OnTTNetProxyInfoCallback;
}  // namespace net
#endif
