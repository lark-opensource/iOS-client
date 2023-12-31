#ifndef NET_DNS_TT_DNS_CROSS_SP_MANAGER_H_
#define NET_DNS_TT_DNS_CROSS_SP_MANAGER_H_

#include <map>
#include <set>
#include <string>
#include <vector>

#include "base/memory/ref_counted.h"
#include "base/memory/singleton.h"
#include "net/base/address_list.h"
#include "net/base/network_change_notifier.h"
#include "net/dns/host_resolver.h"
#include "net/log/net_log_with_source.h"
#include "net/tt_net/route_selection/tt_server_config.h"

namespace net {

class URLRequest;

class TTDnsCrossSpManager
    : public NetworkChangeNotifier::ConnectionTypeObserver {
 public:
  TTDnsCrossSpManager();
  ~TTDnsCrossSpManager() override;

  void ParseTncConfig(const base::DictionaryValue* data);

  void OnConnectionTypeChanged(
      NetworkChangeNotifier::ConnectionType type) override;

  bool HandleRequestResult(net::URLRequest* url_request, int net_error);

  void OnCrossSpJobFinished(const std::string& host,
                            const AddressList& addr_list);

  bool GetCrossSpInfo(const std::string& host,
                      std::string& tcip,
                      std::string& dcip,
                      int64_t& ttfb) const;

  void NotifyCrossSpJobResult(const std::string& host,
                              int64_t finish_time,
                              bool perform_cross_sp,
                              const std::string& remote_ip);

  bool MatchCrossSpWaitPerform(const std::string& host,
                               const std::string& remote_ip);

  void SetActionPerformRecord(const std::string& host);
  bool IsActionHit(const std::string& host) const;

 private:
  class CrossSpJob : public base::RefCountedThreadSafe<CrossSpJob> {
   public:
    CrossSpJob(const std::string& host,
               const std::string& tcip,
               const std::string& dcip,
               const std::string& remote_ip,
               int64_t ttfb,
               TTDnsCrossSpManager* cross_sp_manager);

    bool Start();

    void OnHostResolveComplete(int result);
    std::string GetTcip() const { return tcip_; }
    std::string GetDcip() const { return dcip_; }
    int64_t GetTtfb() const { return ttfb_; }

   private:
    friend class base::RefCountedThreadSafe<CrossSpJob>;
    ~CrossSpJob();

    std::string host_;
    std::string tcip_;
    std::string dcip_;
    std::string remote_ip_;
    int64_t ttfb_{0};

    std::unique_ptr<HostResolver::ResolveHostRequest> host_resolve_request_;
    NetLogWithSource netlog_source_;
    TTDnsCrossSpManager* cross_sp_manager_{nullptr};

    base::WeakPtrFactory<CrossSpJob> weak_ptr_factory_{this};
    DISALLOW_COPY_AND_ASSIGN(CrossSpJob);
  };

  bool MatchHostPattern(const std::string& host) const;

  std::map<std::string, scoped_refptr<CrossSpJob>> cross_sp_jobs_;
  std::map<std::string, int64_t> resolve_history_records_;
  std::map<std::string, std::string> wait_perform_records_;
  std::map<std::string, int64_t> action_history_records_;

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class TTDNSCrossSpTest;
  friend class URLRequestJSONLogVisitorTest;
  friend class HttpDnsHostResolverTest;
  FRIEND_TEST_ALL_PREFIXES(HttpDnsHostResolverTest, TTHttpDNSResolve);
  FRIEND_TEST_ALL_PREFIXES(URLRequestJSONLogVisitorTest, VisitForHttp);
  FRIEND_TEST_ALL_PREFIXES(TTDNSCrossSpTest, TNCConfig);
  FRIEND_TEST_ALL_PREFIXES(TTDNSCrossSpTest, TNCConfigEmpty);
  FRIEND_TEST_ALL_PREFIXES(TTDNSCrossSpTest, OnConnectionTypeChanged);
  FRIEND_TEST_ALL_PREFIXES(TTDNSCrossSpTest, GetCrossSpInfo);
  FRIEND_TEST_ALL_PREFIXES(TTDNSCrossSpTest, PerformAction);
  FRIEND_TEST_ALL_PREFIXES(TTDNSCrossSpTest, CrossJobResolve);
  FRIEND_TEST_ALL_PREFIXES(TTDNSCrossSpTest, HandleRequestResult);
#endif
};
}  // namespace net

#endif  // NET_DNS_TT_DNS_CROSS_SP_MANAGER_H_