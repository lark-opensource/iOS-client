// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_ROUTE_SELECTION_FUSION_BASED_SELECTION_GROUP_IMPL_H_
#define NET_TTNET_URL_DISPATCHER_ROUTE_SELECTION_FUSION_BASED_SELECTION_GROUP_IMPL_H_

#include <math.h>
#include <memory>

#include "base/timer/timer.h"
#include "net/tt_net/url_dispatcher/route_selection/route_selection_group.h"

namespace net {

class FusionBasedSelectionGroupImpl : public RouteSelectionGroup {
 public:
  FusionBasedSelectionGroupImpl(
      const std::vector<RouteCandidate>& candidates_info,
      int scheme_option,
      const std::string& sign,
      const int64_t epoch,
      unsigned int priority,
      double fusion_lambda,
      bool dsa_edge_route);
  ~FusionBasedSelectionGroupImpl() override;

  void StartRouteTest() override;

  void OnOneRouteTestCompleted(const RouteCandidate& route_info,
                               int duration,
                               int rv,
                               bool from_cache) override;

 private:
  struct ScoreInfo {
    bool has_client_score{false};
    double client_score{std::numeric_limits<double>::epsilon()};
    double server_score{std::numeric_limits<double>::epsilon()};
    double fusion_score{std::numeric_limits<double>::epsilon()};

    ScoreInfo() = default;
    ~ScoreInfo() = default;
    ScoreInfo(const ScoreInfo& other) = default;
    ScoreInfo(ScoreInfo&& other) = default;

    ScoreInfo(bool has_client_score,
              double client_score,
              double server_score,
              double fusion_score)
        : has_client_score(has_client_score),
          client_score(client_score),
          server_score(server_score),
          fusion_score(fusion_score) {}
  };

  std::string FindBestHost() const;

  bool HasUnfinishedTest() const;
  void ScheduleNextTimeout();
  void OnTimeout();

  double ComputeClientScore(int rtt, int bias, int threshold) const {
    if (threshold == 0 || rtt + bias >= threshold)
      return std::numeric_limits<double>::epsilon();
    double client_score = 1 - static_cast<double>(rtt + bias) / threshold;
    // when route test request timeout, client score will be set epslion,
    // so the minimum value of client score is epslion.
    if (client_score < std::numeric_limits<double>::epsilon()) {
      client_score = std::numeric_limits<double>::epsilon();
    }
    return client_score;
  }

  double ComputeFusionScore(double client_score, double server_score) const {
    return (1 - fusion_lambda_) * log(client_score) +
           fusion_lambda_ * log(server_score);
  }

  double fusion_lambda_;

  std::map<RouteCandidate, ScoreInfo> hosts_scores_;

  base::OneShotTimer timeout_decision_timer_;
  int current_timeout_duration_;

  DISALLOW_COPY_AND_ASSIGN(FusionBasedSelectionGroupImpl);
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_ROUTE_SELECTION_FUSION_BASED_SELECTION_GROUP_IMPL_H_
