// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NQE_TT_GROUP_RTT_MANAGER_H_
#define NET_TT_NET_NQE_TT_GROUP_RTT_MANAGER_H_

#include "base/memory/singleton.h"
#include "net/nqe/network_quality_estimator.h"
#include "net/tt_net/route_selection/tt_server_config.h"

namespace net {

class TTGroupRttManager : public TTServerConfigObserver {
 public:
  struct TNCConfig {
    bool enable;
    // first is group name, second is host regex.
    std::map<std::string, std::string> watching_groups;
    TNCConfig();
    TNCConfig(const TNCConfig& other);
    ~TNCConfig();
  };

  TTNET_IMPLEMENT_EXPORT static TTGroupRttManager* GetInstance();
  // Update TNC config.
  void OnServerConfigChanged(
      const UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;

  bool Init(NetworkQualityEstimatorParams* nqe_params,
            NetworkQualityEstimator* nqe);

  void Deinit();

  // Get current computed group rtt estimates in a list value.
  std::unique_ptr<base::ListValue> GetGroupRTTEstimateAsValue() const;

  // Get current computed group rtt estimates. Convenient to convert for Java
  // and OC, directly use three vectors to obtain current value's copy. User
  // should learn that each value with the same index respresents the value in
  // the same group.
  TTNET_IMPLEMENT_EXPORT void GetGroupRTTEstimateInVectors(
      std::vector<std::string>& watching_group_name,
      std::vector<int32_t>& transport_rtt,
      std::vector<int32_t>& http_rtt) const;

  void ComputeGroupRTTEstimate();

  void AddGroupRtt(const nqe::internal::Observation& observation,
                   const std::string& group_ref,
                   const bool add_anyway);

  void ClearGroupRtt();

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  struct TNCConfig& GetTncConfigForTesting() {
    return tnc_config_;
  }
#endif

 private:
  friend struct base::DefaultSingletonTraits<TTGroupRttManager>;
  TTGroupRttManager();
  ~TTGroupRttManager() override;

  // Support for group based observation collection.
  struct GroupIndicator {
    std::string group_name;
    std::regex host_regex;

    GroupIndicator();
    GroupIndicator(const GroupIndicator& other);
    ~GroupIndicator();
  };

  // Initialize the watching group pattern.
  void UpdateGroupRttObservations();

  bool ParseJsonResult(const base::Optional<base::Value>& tnc_config_value);

  TNCConfig tnc_config_;

  bool initialized_;

  NetworkQualityEstimatorParams* nqe_params_;  // not own
  NetworkQualityEstimator* nqe_;               // not own
  const base::TickClock* tick_clock_;

  typedef std::vector<
      std::pair<GroupIndicator, std::vector<nqe::internal::ObservationBuffer>>>
      GroupObservationBuffer;

  // Current estimate of rtt per observation group.
  std::map<std::string, std::pair<int64_t, int64_t>> group_rtt_estimate_;

  GroupObservationBuffer group_rtt_observations_;

  DISALLOW_COPY_AND_ASSIGN(TTGroupRttManager);
};

}  // namespace net

#endif