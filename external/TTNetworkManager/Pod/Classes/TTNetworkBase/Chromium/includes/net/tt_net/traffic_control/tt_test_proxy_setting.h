//
//  Created by gaohaidong on 12/7/18.
//  Copyright © 2018 ttnet. All rights reserved.
//

#ifndef NET_TTNET_TRAFFIC_CONTROL_TEST_PROXY_SETTING_H_
#define NET_TTNET_TRAFFIC_CONTROL_TEST_PROXY_SETTING_H_

#include <regex>
#include <vector>

#include "base/memory/singleton.h"
#include "net/net_buildflags.h"

class GURL;
namespace net {
class URLRequest;

class TTProxySetting final {
 public:
  static TTProxySetting* GetInstance();
  ~TTProxySetting();

  void SetProxy(const std::string& config);
  void SetProxyOnIOThread(const std::string& config);
  void SetBoeProxyEnabled(bool enabled, const std::string& json);
  bool BoeProxyEnabled() { return boe_enabled_; }
  void SetBoeProxyEnabledOnIOThread(bool enabled, const std::string& json);
  void ReplaceHostWithBoeDomainSuffix(URLRequest* request, GURL* new_url) const;
  void ReplaceURLWithBoeDomainSuffix(GURL& url) const;
  void ReplaceHostWithoutBoeHttpSuffix(GURL& url) const;
  bool ReplaceUrlWithoutBoeHttpSuffix(const GURL& url,
                                      std::string& final_url) const;
  bool IsBoeHttpsEnabled() const;

 private:
  friend struct base::DefaultSingletonTraits<TTProxySetting>;

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class TTProxySettingTest;
  FRIEND_TEST_ALL_PREFIXES(TTProxySettingTest, SetBoeProxyEnabled);
#endif

  TTProxySetting();
  void ParseBypassBOEJSON(const std::string& json);
  bool InBypassBoeList(const std::string& host, const std::string& path) const;
  void DowngradeToHttpScheme(const GURL& current_url, GURL* new_url) const;
  void ReplaceBoeHttpSuffix(const GURL& current_url, GURL* new_url) const;
  void ReplaceBoeHttpsSuffix(const GURL& current_url, GURL* new_url) const;

  bool boe_enabled_{false};
  bool downgrade_to_http_{false};
  std::string boe_http_suffix_;
  std::string boe_https_suffix_;
  std::vector<std::string> bypass_boe_path_list_;
  std::vector<std::string> bypass_boe_host_list_;
  std::vector<std::regex> bypass_boe_regex_lists_;

  DISALLOW_COPY_AND_ASSIGN(TTProxySetting);
};

}  // namespace net

#endif  // NET_TTNET_TRAFFIC_CONTROL_TEST_PROXY_SETTING_H_
