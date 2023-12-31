// Copyright (c) 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_ROUTE_SELECTION_SEQUENTIAL_SELECTION_GROUP_IMPL_H_
#define NET_TTNET_URL_DISPATCHER_ROUTE_SELECTION_SEQUENTIAL_SELECTION_GROUP_IMPL_H_

#include <memory>
#include <set>

#include "base/time/time.h"
#include "base/timer/timer.h"
#include "net/tt_net/url_dispatcher/route_selection/route_selection_group.h"

namespace net {

class SequentialSelectionGroupImpl : public RouteSelectionGroup {
 public:
  SequentialSelectionGroupImpl(
      const std::vector<RouteCandidate>& candidates_info,
      int scheme_option,
      const std::string& sign,
      const int64_t epoch,
      unsigned int priority,
      bool dsa_edge_route);
  ~SequentialSelectionGroupImpl() override;

  void StartRouteTest() override;

  void OnOneRouteTestCompleted(const RouteCandidate& route_info,
                               int duration,
                               int rv,
                               bool from_cache) override;

 private:
  const RouteCandidate& GetRouteCandidateRef(const RouteCandidate& route_info);
  base::OneShotTimer accelerate_next_candidate_timer_;

  DISALLOW_COPY_AND_ASSIGN(SequentialSelectionGroupImpl);
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_ROUTE_SELECTION_SEQUENTIAL_SELECTION_GROUP_IMPL_H_
