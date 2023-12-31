#ifndef NET_TTNET_CDN_API_VERIFY_H_
#define NET_TTNET_CDN_API_VERIFY_H_

#include "base/memory/singleton.h"
#include "base/values.h"
#include "net/url_request/url_request.h"

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_CDN_API_VERIFICATION)

namespace net {

// This class provides support for checking whether the value of the
// x-tt-trace-id in the request and response is consistent to judge whether the
// API response is back to the source.
//
// In the case of inconsistency, the strategies include triggering the
// url_dispatcher and intercepting the response.
class CdnApiVerification {
 public:
  static CdnApiVerification* GetInstance();
  ~CdnApiVerification();

  void ParseCdnApiVerificationConfig(const base::DictionaryValue* data);

  int VerifyCdnApi(URLRequest* request,
                   const HttpResponseHeaders* original_response_headers);

  int TranslateErrorCodeForDispatcher(URLRequest* request, int net_error);

 private:
  friend struct base::DefaultSingletonTraits<CdnApiVerification>;
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class CdnApiVerificationTest;
#endif

  CdnApiVerification();
  void Verify5xxCode(URLRequest* request, HttpResponseHeaders* headers);

  void reset();

  bool ttnet_api_verify_enabled_;
  bool verify_5xx_enabled_;
  bool ttnet_api_verify_feedback_enabled_;
  std::vector<std::string> ttnet_api_verify_domain_list_;
  std::vector<std::string> ttnet_api_intercept_path_list_;
};

}  // namespace net

#endif  // TTNET_IMPLEMENT_DISABLE_CDN_API_VERIFICATION

#endif  // NET_TTNET_CDN_API_VERIFY_H_
