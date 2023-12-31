// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_BASE_EXPERIENCE_REPORTER_H_
#define NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_BASE_EXPERIENCE_REPORTER_H_

#include "net/tt_net/net_detect/gsdk/tt_net_experience_manager.h"

namespace net {
namespace tt_exp {

// The whole report of experience request.
struct BaseExperienceReport {
  // This block content is displayed even if TNC disabled.
  struct BasicNode {
    int exp_type{TTNetExperienceManager::REQ_TYPE_INVALID};
    int request_error{ND_ERR_OK};
    std::string tnc_etag;
    std::string sdk_version;  // the game or ttnet sdk version
    std::string user_extra_info;

    BasicNode();
    ~BasicNode();
    BasicNode(const BasicNode& other);
  } basic_node;

  BaseExperienceReport();
  virtual ~BaseExperienceReport();
};

class TTNetExpBaseExperienceReporter {
 public:
  TTNetExpBaseExperienceReporter();
  virtual ~TTNetExpBaseExperienceReporter();

  std::unique_ptr<base::DictionaryValue> ToJson(
      const BaseExperienceReport::BasicNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const BaseExperienceReport& root) const;
};

}  // namespace tt_exp
}  // namespace net
#endif  // NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_BASE_EXPERIENCE_REPORTER_H_
