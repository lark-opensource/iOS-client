// Copyright (c) 2020 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_CLIENT_KEY_MANAGER_H
#define NET_TTNET_CLIENT_KEY_MANAGER_H

#include "base/memory/singleton.h"
#include "base/ttnet_implement_buildflags.h"
#include "base/values.h"
#include "net/cookies/canonical_cookie.h"
#include "net/cookies/cookie_options.h"

namespace net {

class URLRequest;
class URLRequestContext;

class ClientKeyManager {
 public:
  struct ClientKeyConfig {
    ClientKeyConfig();
    ClientKeyConfig(const ClientKeyConfig&);
    ~ClientKeyConfig();

    bool client_key_sign_enabled{false};
    std::vector<std::string> update_host_list;
    std::vector<std::string> update_path_list;
  };

  ~ClientKeyManager();
  static ClientKeyManager* GetInstance();

  void AddClientKeyHeader(URLRequest* request) const;
  void InitClientKeyAndSessionInfo(const URLRequestContext* context);
  void ParseClientKeyConfig(const base::DictionaryValue* data);
  void UpdateClientKeyAndSessionInfo(const URLRequest* request);

 private:
  friend struct base::DefaultSingletonTraits<ClientKeyManager>;
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  FRIEND_TEST_ALL_PREFIXES(ClientKeyManagerTest, UpdateAndSetClientKeyTest);
  FRIEND_TEST_ALL_PREFIXES(ClientKeyManagerTest, ClientKeySignUnabled);
#endif
  ClientKeyManager();

  void ClearClientKeyAndSessionInfo();
  void GetCookieListCompleted(
      const CookieOptions& options,
      const URLRequestContext* context,
      const CookieAccessResultList& cookies_with_access_result_list,
      const CookieAccessResultList& excluded_list);
  void RefreshAndSendCookieMismatchLog(const std::string& cookie_line,
                                       const CookieOptions& options,
                                       const URLRequestContext* context);

  ClientKeyConfig config_;
  std::string client_key_;
  std::string kms_version_;
  std::string session_id_;
  std::string session_url_;
  std::string session_cookie_;
  DISALLOW_COPY_AND_ASSIGN(ClientKeyManager);
};

}  // namespace net

#endif  // NET_TTNET_CLIENT_KEY_MANAGER_H
