// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_COOKIES_TT_SHARE_COOKIE_MANAGER_H_
#define NET_TT_NET_COOKIES_TT_SHARE_COOKIE_MANAGER_H_

#include "net/cookies/canonical_cookie.h"
#include "net/tt_net/route_selection/tt_server_config.h"

namespace net {

class TTShareCookieManager : public TTServerConfigObserver {
 public:
  TTShareCookieManager();
  ~TTShareCookieManager() override;

  bool Init(scoped_refptr<base::SingleThreadTaskRunner> task_runner);

  void Deinit();

 protected:
  // Get cookies from |cookie_source_hosts| and share them with |new_hosts|.
  virtual void ShareCookiesWithHostsInternal(
      const std::vector<std::string>& cookie_source_hosts,
      const std::vector<std::string>& new_hosts) = 0;

  bool IsHostInCookieSharedHosts(
      const std::string& host,
      const std::vector<std::string>& share_cookie_hosts) const;

  // Current cookie-shared hosts.
  std::vector<std::string> cookie_shared_hosts_;

  bool initialized_;

 private:
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class MockShareCookieManager;
#endif
  // TTServerConfigObserver implementation:
  void OnServerConfigChanged(
      const UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;

  bool ParseJsonResult(const base::Optional<base::Value>& tnc_config_value);

  void TryShareCookiesFromOldHosts(
      const std::vector<std::string>& cookie_shared_hosts_old);

  void ReadTNCConfigFromCache();

  DISALLOW_COPY_AND_ASSIGN(TTShareCookieManager);
};

}  // namespace net

#endif