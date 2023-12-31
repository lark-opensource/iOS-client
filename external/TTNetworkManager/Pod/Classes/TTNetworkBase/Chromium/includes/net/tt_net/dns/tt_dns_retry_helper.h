#ifndef NET_TT_DNS_RETRY_HELPER_H_
#define NET_TT_DNS_RETRY_HELPER_H_

#include <set>
#include <string>

#include "base/memory/singleton.h"

namespace net {

class TTDnsRetryHelper {
 public:
  static TTDnsRetryHelper* GetInstance();
  ~TTDnsRetryHelper();

  void SetForceHttpdns(const std::string& host, bool enable);
  bool CheckForceHttpdns(const std::string& host) const;

  void SetSkipPerferIp(const std::string& host, bool enable);
  bool CheckSkipPreferIp(const std::string& host) const;

 private:
  friend struct base::DefaultSingletonTraits<TTDnsRetryHelper>;
  TTDnsRetryHelper();

  std::set<std::string> force_httpdns_retry_host_set_;
  std::set<std::string> skip_prefer_ip_retry_host_set_;

  DISALLOW_COPY_AND_ASSIGN(TTDnsRetryHelper);
};

}  // namespace net

#endif  // NET_TT_DNS_RETRY_HELPER_H_
