// Copyright (c) 2018 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_URL_REQUEST_URL_REQUEST_JSON_LOG_VISITOR_H_
#define NET_URL_REQUEST_URL_REQUEST_JSON_LOG_VISITOR_H_

#include <string>

#include "base/macros.h"
#include "base/time/time.h"
#include "base/values.h"
#include "net/net_buildflags.h"
#include "net/tt_net/base/ttnet_basic_request_info.h"

namespace net {

struct RedirectInfo;
class URLRequest;

// Helper class to format url request log in JSON. The request log content
// contain key informations about the request process, and it will further be
// uploaded for analysis and monitor.
class URLRequestJSONLogVisitor {
 public:
  URLRequestJSONLogVisitor();
  ~URLRequestJSONLogVisitor();

  // Visitor pattern. To collect the information from |url_request| and output
  // the well-formatted log string.
  const std::string& Visit(URLRequest* url_request);
  TTNetBasicRequestInfo GetTTNetBasicRequestInfo() const {
    return ttnet_basic_request_info_;
  }

 private:
  bool ValidateAndSetTimingValue(base::DictionaryValue* dict,
                                 const std::string& field_name,
                                 base::TimeTicks start_time,
                                 base::TimeTicks end_time,
                                 bool previous_step_success,
                                 int64_t& value) const;
  std::unique_ptr<base::Value> GetTimingInfo(URLRequest* url_request) const;
  std::unique_ptr<base::Value> GetResponseInfo(URLRequest* url_request) const;
  std::unique_ptr<base::Value> GetDNSInfo(URLRequest* url_request) const;
  std::unique_ptr<base::Value> GetSocketInfo(URLRequest* url_request) const;
  std::unique_ptr<base::Value> GetSocketTimeoutParam(
      const URLRequest* url_request) const;
  std::unique_ptr<base::Value> GetSSLInfo(URLRequest* url_request) const;
  std::unique_ptr<base::Value> GetSocketPoolInfo(URLRequest* url_request) const;
  std::unique_ptr<base::Value> GetURLDispatchInfo(
      URLRequest* url_request) const;
  std::unique_ptr<base::Value> GetNQEInfo(URLRequest* url_request) const;
  std::unique_ptr<base::Value> GetEventInfo(URLRequest* url_request) const;
  std::unique_ptr<base::Value> GetOtherInfo(URLRequest* url_request) const;
  std::unique_ptr<base::Value> GetHeaderInfo(URLRequest* url_request) const;
  std::unique_ptr<base::Value> GetHttp2Info(URLRequest* url_request) const;
  std::unique_ptr<base::Value> GetCompressInfo(URLRequest* url_request) const;
  std::unique_ptr<base::Value> GetQuicInfo(URLRequest* url_request) const;
  std::unique_ptr<base::Value> GetABTestInfo() const;
  std::unique_ptr<base::Value> GetRedirectInfo(
      const std::vector<RedirectInfo>& redirect_chain) const;
  std::unique_ptr<base::Value> GetTNCInfo() const;
  std::unique_ptr<base::Value> GetSessionInfo(URLRequest* url_request) const;
  std::unique_ptr<base::Value> GetControlHeaders(const URLRequest* url_request) const;
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_PROXY_SUPPORT)
  std::unique_ptr<base::Value> GetProxyInfo(URLRequest* url_request) const;
#endif
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_STREAM_ZSTD)
  std::unique_ptr<base::Value> GetSourceStreamInfo(
      URLRequest* url_request) const;
#endif
  std::string log_content_;
  mutable TTNetBasicRequestInfo ttnet_basic_request_info_;
  std::string final_host_;

  DISALLOW_COPY_AND_ASSIGN(URLRequestJSONLogVisitor);
};

}  // namespace net

#endif  // NET_URL_REQUEST_URL_REQUEST_JSON_LOG_VISITOR_H_
