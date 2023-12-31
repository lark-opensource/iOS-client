//
//  Created by songlu on 4/17/17.
//  Copyright © 2017 ttnet. All rights reserved.
//

#ifndef NET_TTNET_ROUTE_SELECTION_TT_NET_COMMON_TOOLS_H_
#define NET_TTNET_ROUTE_SELECTION_TT_NET_COMMON_TOOLS_H_

#include <map>
#include <vector>

#include "base/callback.h"
#include "base/memory/singleton.h"
#include "base/power_monitor/power_observer.h"
#include "base/run_loop.h"
#include "base/single_thread_task_runner.h"
#include "base/synchronization/waitable_event.h"
#include "base/timer/timer.h"
#include "net/base/net_export.h"
#include "net/tt_net/base/ttnet_basic_request_info.h"
#include "net/tt_net/route_selection/tt_default_server_config.h"
#include "net/tt_net/route_selection/tt_server_config.h"
#include "net/tt_net/url_dispatcher/dispatch_strategy.h"
#include "net/url_request/url_fetcher_delegate.h"

class GURL;

namespace base {
class DictionaryValue;
}

namespace net {
extern const char kIESSpeedTimingHeader[];
extern const char kStoreRegionEpochHeader[];
extern const char kStoreRegionEmptyHeader[];

class URLRequest;
class URLRequestContext;
class URLRequestContextGetter;
class DESEncrypted;
struct ServerTimingInfo;

class TTNetUrlRequest : public net::URLFetcherDelegate,
                        public base::RefCountedThreadSafe<TTNetUrlRequest> {
 public:
  typedef base::Callback<void(int, const std::string&, HttpResponseHeaders*)>
      CallbackType;
  typedef base::Callback<void(int, const net::URLFetcher*)>
      OnRequestCompletedCallback;

  TTNetUrlRequest();

  bool SendUrlRequestBackResponseCallback(const std::string& native_url,
                                          CallbackType callback,
                                          int timeout_sec = COMMON_TOOLS_MAX_WAIT_TIME_URLREQUEST);

  bool SendUrlRequestBackResponseCallback(
      const std::string& native_url,
      const std::map<std::string, std::string>& headers,
      CallbackType callback);

  bool SendUrlRequestBackResponseCallback(
      const std::string& native_url,
      int load_flags,
      const std::map<std::string, std::string>& headers,
      CallbackType callback);

  void SendGetRequest(const std::string& native_url,
                      const std::map<std::string, std::string>& headers,
                      OnRequestCompletedCallback callback,
                      int load_flags = 0);

  void OnURLFetchComplete(const net::URLFetcher* source) override;

  void OnURLFetchDownloadProgress(const net::URLFetcher* source,
                                  int64_t current,
                                  int64_t total,
                                  int64_t current_network_bytes) override;

  void OnURLFetchUploadProgress(const net::URLFetcher* source,
                                int64_t current,
                                int64_t total) override;

  scoped_refptr<base::SingleThreadTaskRunner> GetNetworkTaskRunner() const;

 private:
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  FRIEND_TEST_ALL_PREFIXES(TTCommonToolsTest, AddEpochHeaderForTNCTest);
  void SetStoreRegionEpochForTesting(int64_t epoch) {
    store_region_epoch_ = epoch;
  }
#endif
  scoped_refptr<base::SingleThreadTaskRunner> network_task_runner_;
  void StartFetchOnIOThread(const std::string& native_url, int timeout_sec);

  void FailRequestInternal();

  CallbackType callback_;
  void AsyncNotifyCaller(int responseCode,
                         const std::string& response,
                         HttpResponseHeaders* responseHeaders);

  OnRequestCompletedCallback onRequestCompletedCallback_;

  void AddTimingHeaderForIESSpeed(const net::URLFetcher* source) const;

  void AddEpochHeaderForTNC(const net::URLFetcher* source) const;

 protected:
  ~TTNetUrlRequest() override;

  friend class base::RefCountedThreadSafe<TTNetUrlRequest>;
  DISALLOW_COPY_AND_ASSIGN(TTNetUrlRequest);

  std::unique_ptr<net::URLFetcher> fetcher_;

  base::OneShotTimer timeout_timer_;

  void OnTimeout();

  void MonitorApiStart(const std::string& url, const std::string& method);
  void MonitorApiResult(bool succ);
  bool ShouldReport(const std::string& url) const;

  std::map<std::string, std::string> headers_;
  int load_flags_{0};

  // stat params
  int64_t store_region_epoch_{INT64_MAX};
  bool store_region_empty_{false};
  std::string uuid_;
  std::string origin_url_;
  std::string trace_code_;
  int64_t app_start_{0};
  int64_t request_start_{0};
  int64_t response_back_{0};
  int64_t response_complete_{0};
  int64_t request_end_{0};
};

class TTNET_IMPLEMENT_EXPORT URLDispatchByAppControl
    : public base::RefCountedThreadSafe<URLDispatchByAppControl> {
 public:
  typedef base::Callback<void(const std::string& final_url,
                              const std::string& etag,
                              const std::string& epoch)>
      URLDispatchResultCallback;
  URLDispatchByAppControl(const std::string& original_url,
                          URLDispatchResultCallback callback);
  void DoUrlDispatch();
  void DoUrlDispatchComplete(const std::string& final_url);

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_REQUEST_DELAY)
  typedef base::Callback<void(int delay)> URLDispatchDelayCallback;
  URLDispatchByAppControl(const std::string& original_url,
                          const std::string& request_tag,
                          URLDispatchDelayCallback callback);
  void DoUrlDelay();
  void DoUrlDelayComplete(int delay_time);
#endif

 private:
  friend class base::RefCountedThreadSafe<URLDispatchByAppControl>;
  ~URLDispatchByAppControl();

  std::string original_url_;
  std::string request_tag_;
  URLDispatchResultCallback result_callback_;
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_REQUEST_DELAY)
  URLDispatchDelayCallback delay_callback_;
#endif
  DISALLOW_COPY_AND_ASSIGN(URLDispatchByAppControl);
};

class TTCommonTools {
 public:
  TTCommonTools();
  ~TTCommonTools();

  static void SetRequestHeaders(URLRequest* request,
                                const std::string& key,
                                const std::string& value);
  // Construct request header of "tt-trace-id", refer to
  // doc/doccnP1peaNyLhxECMdI9w#
  static bool GetTraceId(std::string& trace_id);

  // Parse server-timging header, document refer to
  // doc/doccnTmrSG0h7NV95xM8qx#
  static bool GetServerTimingInfo(const URLRequest* url_request,
                                  base::DictionaryValue* dict,
                                  TTNetBasicRequestInfo* basic_info,
                                  int64_t ttfb);
  // Parse server-timging header.
  static bool ParseServerTimingInfo(
      const std::string& server_timing_string,
      ServerTimingInfo& info,
      std::map<std::string, int64_t>& unknown_kvs);

  // Request header which contains "x-tt-bp-rs: 1"
  // indicates to bypass Route-Selection module.
  static bool ShouldBypassRouteSelection(const URLRequest* url_request);

  // Define all the reasons for bypass a dispatch action.
  static bool ShouldBypassDispatchAction(const URLRequest* url_request,
                                         DispatchStrategyType type);

  // Return true if the scheme of origin_url is match with replace_scheme.
  // we support replacement between http and https, ws and wss.
  static bool CanReplaceScheme(const GURL& origin_url,
                               const std::string& replace_scheme);

  // Get final dispatched url by url dispatcher module.
  static GURL GetFinalURLByURLDispatcher(const std::string& url);

  // Return true if pattern string is valid.
  static bool IsPatternStringValid(const std::string& pattern);

  static void ParseTncTagStringToMap(
      const std::string& tnc_tag_string,
      std::unordered_map<std::string, std::set<std::string>>& tnc_tag);

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_REQUEST_DELAY)
  static int GetRequestDelayTime(const std::string& url,
                                 const std::string& tag);
#endif

 private:
  static int64_t ValidateAndGetServerTiming(const std::string& value);

  // Covert int64 value to Hex format at fixed length.
  // If hex length more then fixed length, all hex value set to "f".
  // example: input(123456789, 4) output(ffff)
  // If hex length less then fixed length, high position filled with 0.
  // example: input(123, 4) output(007b)
  static std::string Int64ToHexAtFixedLength(int64_t value, int length);
};

}  // namespace net
#endif
