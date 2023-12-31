#ifndef NET_TT_NET_UTIL_TT_HTTP_UTILS_
#define NET_TT_NET_UTIL_TT_HTTP_UTILS_

#include <string>

#include "net/base/net_export.h"
#include "net/http/http_request_headers.h"
#include "url/gurl.h"

namespace net {

namespace ttutils {

TTNET_IMPLEMENT_EXPORT bool MatchHpackOptimization(const GURL& gurl,
                            std::string* common_params,
                            std::string* variable_params,
                            bool force_match);

TTNET_IMPLEMENT_EXPORT void HandleHpackOptimization(
    const GURL& origin_url,
    net::HttpRequestHeaders* origin_headers,
    std::string& url_string,
    std::vector<std::string>& new_headers);

}  // namespace ttutils

}  // namespace net

#endif  // NET_TT_NET_UTIL_TT_HTTP_UTILS_
