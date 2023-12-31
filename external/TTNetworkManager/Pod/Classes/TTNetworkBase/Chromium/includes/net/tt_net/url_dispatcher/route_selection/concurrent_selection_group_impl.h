// Copyright (c) 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_ROUTE_SELECTION_CONCURRENT_SELECTION_GROUP_IMPL_H_
#define NET_TTNET_URL_DISPATCHER_ROUTE_SELECTION_CONCURRENT_SELECTION_GROUP_IMPL_H_

#include <memory>
#include <set>

#include "base/timer/timer.h"
#include "net/tt_net/url_dispatcher/route_selection/route_selection_group.h"

namespace net {

class ConcurrentSelectionGroupImpl : public RouteSelectionGroup {
 public:
  ConcurrentSelectionGroupImpl(
      const std::vector<RouteCandidate>& candidates_info,
      int scheme_option,
      const std::string& sign,
      const int64_t epoch,
      unsigned int priority,
      bool dsa_edge_route);
  ~ConcurrentSelectionGroupImpl() override;

  void StartRouteTest() override;

  void OnOneRouteTestCompleted(const RouteCandidate& route_info,
                               int duration,
                               int rv,
                               bool from_cache) override;

 private:
  void OnCanDecideWinner();

  void MaybeUpdateBestHost(const RouteCandidate& route_info, int duration);

  void RescheduleWinnerDecideTimer(int duration);

  bool has_decide_best_target_;

  base::OneShotTimer winner_decide_timer_;
  RouteCandidate winner_decide_timer_watching_candidate_;

  RouteCandidate best_host_;
  int best_host_test_duration_;

  std::set<RouteCandidate> unfinished_best_host_competitors_;

  DISALLOW_COPY_AND_ASSIGN(ConcurrentSelectionGroupImpl);
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_ROUTE_SELECTION_CONCURRENT_SELECTION_GROUP_IMPL_H_
