// Copyright (c) 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_DISPATCH_ACTION_INFO_H_
#define NET_TTNET_URL_DISPATCHER_DISPATCH_ACTION_INFO_H_

#include <stdint.h>

#include "base/time/time.h"
#include "url/gurl.h"

namespace net {

struct DispatchActionInfo {
  DispatchActionInfo();
  DispatchActionInfo(const DispatchActionInfo& other);
  ~DispatchActionInfo();

  unsigned int priority;

  // Unique identification for the action.
  std::string sign;

  bool action_hit;

  bool need_feedback;

  int rule_id;

  int strategy_type;

  std::string service_name;

  GURL replace_url;

  base::TimeTicks action_start;
  base::TimeTicks action_end;
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_DISPATCH_ACTION_INFO_H_
