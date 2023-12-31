#ifndef NET_TTNET_PROXY_TT_PROXY_HELPER_H_
#define NET_TTNET_PROXY_TT_PROXY_HELPER_H_

#include "base/timer/timer.h"
#include "net/http/http_request_headers.h"
#include "net/http/http_response_info.h"
#include "net/http/http_stream_request.h"
#include "net/proxy_resolution/proxy_info.h"
#include "net/tt_net/proxy/tt_proxy_info.h"

namespace net {

class TTNetProxyHelper {
 public:
  TTNetProxyHelper();
  ~TTNetProxyHelper();

  // TTNet proxy enabled.
  static bool IsProxyEnabled();

  // See HttpStreamFactoryImpl, Identify proxy requests.
  static void BeforeDoResolveProxy(HttpStreamRequest::Delegate* delegate,
                                   const HttpRequestInfo request_info,
                                   ProxyInfo* proxy_info);

  // See HttpStreamFactoryImpl, Set proxy info config and authentication
  // information.
  static void AfterDoResolveProxy(HttpStreamRequest::Delegate* delegate,
                                  const HttpRequestInfo request_info,
                                  ProxyInfo* proxy_info);

  // See ProxyService, set ttnet proxy configuration effective.
  static void ApplyTTNetProxy(const GURL& url, ProxyInfo* result);

  // In HttpProxyClientSocket, set sign for http connect signature.
  static void DoHttpsSign(bool is_ttnet_tunnel,
                          std::map<std::string, std::string> ttnet_proxy_auth,
                          HttpRequestHeaders* request_headers);

  // In HttpProxyClientSocket, callback for http connect info.
  static void DoResolveHttpsProxy(
      bool is_ttnet_tunnel,
      HttpResponseInfo response,
      base::TimeTicks http_connect_start_time,
      OnTTNetProxyInfoCallback ttnet_proxy_info_callback);

  // In HttpNetworkTransaction, resolve http proxy info, return need fallback.
  static bool DoResolveHttpProxy(bool allow_ttnet_proxy_fallback,
                                 HttpResponseInfo response,
                                 TTNetProxyInfo* ttnet_proxy_info);

  // In HttpNetworkTransaction, remove ttnet proxy extra header.
  static void RemoveProxyExtraHeader(bool is_ttnet_proxy_request,
                                     bool allow_ttnet_proxy_fallback,
                                     const HttpRequestInfo* request,
                                     HttpRequestHeaders* request_headers);

  // In HttpNetworkTransaction, fill proxy statistics.
  static void TryFillProxyLoadTimingInfo(GURL url,
                                         bool is_ttnet_proxy_enabled,
                                         bool allow_ttnet_proxy_fallback,
                                         TTNetProxyInfo ttnet_proxy_info,
                                         LoadTimingInfo* load_timing_info);
};
}  // namespace net
#endif
