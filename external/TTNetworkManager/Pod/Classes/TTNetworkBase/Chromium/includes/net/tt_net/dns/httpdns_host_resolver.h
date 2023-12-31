//
//  Created by gaohaidong on 3/7/17.
//  Copyright © 2017 ttnet. All rights reserved.
//

#ifndef NET_DNS_HTTPDNS_HOST_RESOLVER_H_
#define NET_DNS_HTTPDNS_HOST_RESOLVER_H_

#include <memory>
#include <string>
#include <vector>

#include "base/callback.h"
#include "base/single_thread_task_runner.h"
#include "base/timer/timer.h"
#include "net/base/address_family.h"
#include "net/base/ip_address.h"
#include "net/base/net_export.h"
#include "net/base/network_isolation_key.h"
// #include "net/dns/host_resolver_manager.h"
#include "net/net_buildflags.h"
#include "net/tt_net/dns/tt_dns_cross_sp_manager.h"
#include "net/url_request/url_fetcher_delegate.h"

namespace net {

class URLRequestContext;
class URLRequestContextGetter;

class HttpDnsTransaction;
class TTWaitBatchHttpdnsTransaction;

enum ParsingError {
  ParsingErrorOK = 0,
  ParsingErrorNoContent = 1000,
  ParsingErrorDecyptedFailed,
  ParsingErrorNoIP,
  ParsingErrorNoTTL,
  ParsingErrorBadJson,
  ParsingErrorTimeout,
  ParsingErrorNoDnsContent,
  ParsingErrorWaitBatchTimeout
};

enum HttpDnsSource {
  Unknown = -1,
  TT = 0,
  Google,
  TTBatch,
  TTWaitBatch,
  TTBiz
};

class HttpDnsContext {
 public:
  HttpDnsContext();
  ~HttpDnsContext();

  void insert_bypass_httpdns_list(const std::string& host) {
    bypass_httpdns_list_.insert(host);
  }

  void erase_bypass_httpdns_list(const std::string& host) {
    bypass_httpdns_list_.erase(host);
  }

  const std::set<std::string>& bypass_httpdns_list() const {
    return bypass_httpdns_list_;
  }

  TTDnsCrossSpManager* dns_cross_sp_manager() const {
    return dns_cross_sp_manager_.get();
  }

 private:
  std::set<std::string> bypass_httpdns_list_;
  std::unique_ptr<TTDnsCrossSpManager> dns_cross_sp_manager_ =
      std::make_unique<TTDnsCrossSpManager>();

  DISALLOW_COPY_AND_ASSIGN(HttpDnsContext);
};

class NET_EXPORT HttpDnsHostResolver {
 public:
  struct HttpDnsParsedItem {
    std::string host;
    std::vector<std::string> ips;
    base::TimeDelta ttl;

    HttpDnsParsedItem();
    HttpDnsParsedItem(const HttpDnsParsedItem& other);
    ~HttpDnsParsedItem();
  };

  struct HttpDnsResponse {
    std::vector<HttpDnsParsedItem> parsed_list;
    int error_no{ParsingError::ParsingErrorOK};
    IPAddress cip;
    int dns_type{0};
    HostResolverFlags resolver_flag{0};
    bool batched{false};
    bool preload{false};
    bool is_auth{false};
    /**
     * action within the response of httpdns query.
     * action: 0 or others, ignore the value.
     * action: 1, perform the cross sp strategy.
     */
    int action{-1};

    HttpDnsResponse();
    HttpDnsResponse(const HttpDnsResponse& other);
    ~HttpDnsResponse();
  };
  typedef base::OnceCallback<void(int net_error,
                                  const HttpDnsResponse& response)>
      CallbackType;

  class Handle {
   public:
    explicit Handle(HttpDnsTransaction* transaction);
    ~Handle();

   private:
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
    friend class TestHttpDnsResolverHelper;
#endif
    scoped_refptr<HttpDnsTransaction> transaction_;
  };

  explicit HttpDnsHostResolver(URLRequestContextGetter* context_getter);
  ~HttpDnsHostResolver();

  std::unique_ptr<Handle> StartHttpDnsTransaction(const std::string& hostname,
                                                  int sdk_id,
                                                  int cache_stale_reason,
                                                  int cache_expire_time_delta,
                                                  int timeout_seconds,
                                                  const NetworkIsolationKey& network_isolation_key,
                                                  bool is_internal_retry_req,
                                                  CallbackType callback);

  std::unique_ptr<Handle> StartBatchHttpDnsTransaction(
      const std::vector<std::string>& host_list,
      int cache_stale_reason,
      int cache_expire_time_delta,
      bool preload,
      CallbackType callback);
  bool MatchBatchedHttpdnsHosts(const std::string& hostname) const;

  void OnNetworkChanged() { ++network_changes_; }

  void SendFeedbackLog(const std::string& url,
                       int status_code,
                       int error,
                       HttpDnsSource source) const;

  bool IsHttpDnsBypassed(const std::string& host) const;
  bool ValidateHttpDnsHostWhiteList(const std::string& hostname) const;
  bool MatchHttpDnsHostForbiddenList(const std::string& hostname) const;
  bool CheckUseGoogleDns(const std::string& host) const;
  bool CheckPreloadBatchHttpDnsPerforming() const {
    return preload_batch_httpdns_performing_;
  }

  void RegisterWaitBatchHttpdnsCallback(
      const std::string& task_id,
      TTWaitBatchHttpdnsTransaction* callback) {
    wait_batch_map_[task_id] = callback;
  }

  void RemoveWaitBatchHttpdnsCallback(const std::string& task_id) {
    if (wait_batch_map_.count(task_id) > 0) {
      wait_batch_map_[task_id] = nullptr;
    }
  }

  URLRequestContextGetter* url_request_context_getter() {
    return url_request_context_getter_.get();
  }

  static bool ShouldSkipDnsDispatchQueue(HttpDnsHostResolver* client,
                                         const std::string& host);

  // For metrics
  int google_request_total_{0};
  int google_request_success_{0};

  int tthttpdns_request_total_{0};
  int tthttpdns_request_success_{0};

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  int* fetch_complete_runtimes_for_testing_{nullptr};
  void SetFetchCompleteRunTimesForTesting(int* count_ref) {
    fetch_complete_runtimes_for_testing_ = count_ref;
  }
#endif

 private:
  scoped_refptr<net::URLRequestContextGetter> url_request_context_getter_;

  bool batch_httpdns_performing_{false};
  bool preload_batch_httpdns_performing_{false};
  CallbackType batch_httpdns_callback_;
  std::vector<std::string> batch_httpdns_hosts_;
  std::map<std::string, TTWaitBatchHttpdnsTransaction*> wait_batch_map_;
  int network_changes_{0};

  bool CheckHostMatchedGoogleDns(const std::string& host) const;
  bool CheckHostMatchedTTHttpDns(const std::string& host) const;
  std::string GetTTHttpDnsDomain() const;
  std::string GetTTHttpDnsDomainForHost(const std::string& host) const;

  void OnBatchHttpdnsComplete(
      int network_changes,
      int net_error,
      const HttpDnsHostResolver::HttpDnsResponse& response);
};

class HttpDnsTransaction
    : public net::URLFetcherDelegate,
      public base::RefCountedThreadSafe<HttpDnsTransaction> {
 public:
  HttpDnsTransaction(HttpDnsHostResolver* host,
                     HttpDnsSource source,
                     HttpDnsHostResolver::CallbackType callback);

  // net::URLFetcherDelegate implementation.
  void OnURLFetchComplete(const net::URLFetcher* source) override;

  void OnURLFetchDownloadProgress(const net::URLFetcher* source,
                                  int64_t current,
                                  int64_t total,
                                  int64_t current_network_bytes) override;

  void OnURLFetchUploadProgress(const net::URLFetcher* source,
                                int64_t current,
                                int64_t total) override;
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  URLFetcher* GetUrlFetcherForTesting() const { return fetcher_.get(); }
  int* fetch_complete_runtimes_for_testing_{nullptr};
  void SetFetchCompleteRunTimesForTesting(int* count_ref) {
    fetch_complete_runtimes_for_testing_ = count_ref;
  }
#endif
  void SetSdkId(int sdk_id) { sdk_id_ = sdk_id; }

  void set_network_isolation_key(
      const NetworkIsolationKey& network_isolation_key) {
    network_isolation_key_ = network_isolation_key;
  }

  void set_is_internal_retry_req(bool val) { is_internal_retry_req_ = val; }

  void SetTimeoutSeconds(int seconds) { timeout_seconds_ = seconds; }

  HttpDnsSource GetHttpDnsSource() const { return http_dns_source_; }

 public:
  virtual void StartHttpDnsTransaction(const std::string& hostname);

  virtual bool ParseResult(const std::string& content,
                           HttpDnsHostResolver::HttpDnsResponse& dnsResponse);

  virtual void Cancel();

 protected:
  void StartFetchDnsOnIOThread(const std::string& native_url);

  void OnTimeout(net::URLFetcher* fetcher);

  // Used to directly skip the transaction when start http dns transaction,
  // and it will post task in order to avoid callback destory itself to make a
  // coredump. Do not use it to fail or cancel a transaction, call Cancel()
  // directly.
  void SkipTransactionWithError(int error);

  void SetExtraHeaders(const std::vector<std::string>& headers) {
    extra_headers_ = headers;
  }

 protected:
  friend class base::RefCountedThreadSafe<HttpDnsTransaction>;
  DISALLOW_COPY_AND_ASSIGN(HttpDnsTransaction);

  ~HttpDnsTransaction() override;

  void MonitorApiResult(bool succ);

  HttpDnsHostResolver* host_resolver_{nullptr};
  std::unique_ptr<net::URLFetcher> fetcher_;

  HttpDnsSource http_dns_source_{HttpDnsSource::Unknown};

  HttpDnsHostResolver::CallbackType callback_;

  base::OneShotTimer timeout_timer_;

  std::string request_host_;

  // stat params
  std::string uuid_;
  std::string origin_url_;
  std::string trace_code_;
  int64_t app_start_{0};
  int64_t request_start_{0};
  int64_t response_back_{0};
  int64_t response_complete_{0};
  int64_t request_end_{0};
  int dns_type_{0};
  int sdk_id_{0};
  NetworkIsolationKey network_isolation_key_;
  bool is_internal_retry_req_{false};
  HostResolverFlags resolver_flag_{0};
  int timeout_seconds_{0};

  bool is_auth_{false};

  std::vector<std::string> extra_headers_;
};
}  // namespace net

#endif  // NET_DNS_HTTPDNS_HOST_RESOLVER_H_
