#ifndef NET_TTNET_TT_DNS_OUTER_SERVICE_H_
#define NET_TTNET_TT_DNS_OUTER_SERVICE_H_

#include <set>
#include <string>
#include <vector>

#include "base/bind.h"
#include "base/callback.h"
#include "base/containers/queue.h"
#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/memory/singleton.h"
#include "base/threading/thread.h"
#include "net/base/address_list.h"
#include "net/base/host_port_pair.h"
#include "net/base/net_errors.h"
#include "net/dns/host_resolver.h"
#include "net/log/net_log_with_source.h"

namespace net {

class TTDnsResolveListener {
 public:
  virtual void OnTTDnsResolveResult(const std::string& uuid,
                                    const std::string& host,
                                    int rv,
                                    int source,
                                    int cache_source,
                                    const std::vector<std::string>& ips,
                                    const std::string& detailed_info,
                                    bool is_native) = 0;
};

class TTDnsOuterService {
 public:
  class TTDnsQueryJob {
   public:
    typedef base::OnceCallback<void(int, const TTDnsQueryJob*)>
        DnsQueryCompletionCallback;

    TTDnsQueryJob(const std::string& host,
                  int sdk_id,
                  const std::string& uuid,
                  bool is_native);
    virtual ~TTDnsQueryJob();

    int Start(DnsQueryCompletionCallback callback);

    const net::AddressList& addresses() const { return addresses_; }
    const std::string task_info_json() const { return task_info_json_; }
    int cache_stale_reason() const { return cache_stale_reason_; }
    const std::string uuid() const { return uuid_; }
    const std::string host() const { return host_; }
    bool is_native() const { return is_native_; }

   private:
    void OnResolveComplete(int result);

    std::unique_ptr<net::HostResolver::ResolveHostRequest> request_holder_;
    net::AddressList addresses_;
    std::string task_info_json_;
    int cache_stale_reason_{-1};

    const net::NetLogWithSource net_log_;

    DnsQueryCompletionCallback callback_;

    std::string host_;
    int sdk_id_{-1};
    std::string uuid_;
    bool is_native_{false};

    DnsQueryType GetDnsQueryType(int dns_type);

    DISALLOW_COPY_AND_ASSIGN(TTDnsQueryJob);
  };

  static TTDnsOuterService* GetInstance();
  ~TTDnsOuterService();

#if DCHECK_IS_ON()
  void ControlHttpDNSConfig(bool http_dns_enable,
                            bool http_dns_prefer,
                            bool tt_http_dns_enable);
#endif

  void DnsLookup(const std::string& host,
                 int sdk_id,
                 const std::string& uuid,
                 bool is_native);
  void SetTTDnsResolveListener(TTDnsResolveListener* listener) {
    resolve_listener_ = listener;
  }

 private:
  friend struct base::DefaultSingletonTraits<TTDnsOuterService>;
  TTDnsOuterService();

  void DnsLookupOnNetworkThread(TTDnsQueryJob* dns_query);
  void OnDnsLookupComplete(int result, const TTDnsQueryJob* job);

  std::set<const TTDnsQueryJob*> dns_queries_;

  scoped_refptr<base::SingleThreadTaskRunner> net_thread_task_runner_;
  TTDnsResolveListener* resolve_listener_{nullptr};

  DISALLOW_COPY_AND_ASSIGN(TTDnsOuterService);
};

}  // namespace net

#endif  // NET_TTNET_TT_DNS_OUTER_SERVICE_H_
