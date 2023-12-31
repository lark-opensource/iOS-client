// Copyright (c) 2020 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_STORE_IDC_MANAGER_H
#define NET_TTNET_STORE_IDC_MANAGER_H

#include <map>

#include "base/memory/singleton.h"
#include "base/ttnet_implement_buildflags.h"
#if defined(OS_WIN) || defined(OS_MAC) || BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
#include "net/http/http_response_headers.h"
#endif
#include "url/gurl.h"

namespace base {
class Value;
}

namespace net {

class URLRequest;

class TTNET_IMPLEMENT_EXPORT StoreIdcManager {
 public:
  ~StoreIdcManager();
  static StoreIdcManager* GetInstance();

  enum ReportState {
    COOKIE_UPDATE = 1,
    TNC_ACCEPT = 2,
  };

  void AddStoreIdcHeader(URLRequest* request, GURL* url) const;
  void UpdateStoreRegionFromServer(const std::string& path,
                                   const std::string& store_region,
                                   const std::string& store_src,
                                   const std::string& tnc_attr,
                                   const std::string& tnc_etag,
                                   const std::string& tnc_config,
                                   const std::string& tnc_data,
                                   const std::string& base_log,
                                   const std::string& sec_uid,
                                   const std::string& logid);
  void SetStoreIdcRuleJSON(const std::string& json);
  void SetStoreIdcHeaderForGetDomain(
      std::map<std::string, std::string>& headers) const;
  std::unique_ptr<base::Value> GetStoreIdcInfo() const;
  void SendStoreIdcLog(const std::string& base_log,
                       const std::string& logid,
                       ReportState state,
                       bool request_tnc) const;

  bool IsStoreRegionEnabled() const { return store_idc_rule_enabled_; }
  int64_t GetCurrentEpoch() const { return current_epoch_; }
  bool IsStoreRegionEmpty() const { return store_region_.empty(); }

#if defined(OS_IOS)
  const std::vector<std::string>& GetStoreIdcPathList() const {
    return update_store_idc_path_list_;
  }
#endif

#if defined(OS_WIN) || defined(OS_MAC) || BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  // 1. Called by application, pass reponse headers and body of passport;
  // 2. Called by URLRequestHttpJob::SaveCookiesAndNotifyHeadersComplete,
  //    body will be "", and will send new tnc request.
  // Work in network thread.
  void UpdateStoreRegionFromBiz(scoped_refptr<HttpResponseHeaders> headers,
                                const std::string& data);
  // Work in network thread.
  bool ShouldCheckRegion(const GURL& url) const;

  // Work in network thread.
  std::pair<std::string, std::string> ExtractStoreRegionFromCookieHeaders(
      scoped_refptr<HttpResponseHeaders> headers);
#endif

 private:
  friend struct base::DefaultSingletonTraits<StoreIdcManager>;
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  FRIEND_TEST_ALL_PREFIXES(StoreIdcManagerTest, UpdateAndAddStoreRegionTest);
  FRIEND_TEST_ALL_PREFIXES(StoreIdcManagerTest, UpdateTncConfigTest);
  FRIEND_TEST_ALL_PREFIXES(StoreIdcManagerTest, UpdateStoreRegionFromTNCTest);
  FRIEND_TEST_ALL_PREFIXES(StoreIdcManagerTest, UpdateStoreRegionFromBizTest);
  FRIEND_TEST_ALL_PREFIXES(StoreIdcManagerTest,
                           ExtractStoreRegionFromCookieHeadersTest);
  FRIEND_TEST_ALL_PREFIXES(StoreIdcManagerTest, ShouldCheckRegionTest);
  FRIEND_TEST_ALL_PREFIXES(TTServerConfigTest, TryAcceptTncConfigByAttr);
  void SetCurrentEpochForTesting(int64_t epoch) { current_epoch_ = epoch; }
  void SetStoreIdcRuleEnabled(bool enable) { store_idc_rule_enabled_ = enable; }
#endif
  StoreIdcManager();
  bool AddExtraParamsForDidAndUidPath(URLRequest* request, GURL* url) const;

  // Update store-idc info from response which path is matched
  // in |update_store_idc_path_list_|.
  std::vector<std::string> update_store_idc_path_list_;

  // Add store-idc header into request which host is matched in
  // |add_store_idc_host_list_|.
  std::vector<std::string> add_store_idc_host_list_;

  enum StoreRegionInit {
    NOT_INIT = 0,
    CONFIG_EMPTY,
    CONFIG_ERROR,
    INIT_SUCCESS,
  };

  int64_t current_epoch_{0};
  StoreRegionInit region_init_{NOT_INIT};
  // request: path + logid + region + source.
  std::string update_region_info_;
  std::string store_region_;
  std::string store_sec_uid_;
  std::string store_region_local_;
  std::string store_region_src_;
  bool store_idc_rule_enabled_{false};
  DISALLOW_COPY_AND_ASSIGN(StoreIdcManager);
};

}  // namespace net
#endif  // NET_TTNET_STORE_IDC_MANAGER_H
