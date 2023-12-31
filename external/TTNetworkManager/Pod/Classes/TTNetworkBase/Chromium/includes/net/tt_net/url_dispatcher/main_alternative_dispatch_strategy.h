// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_MAIN_ALTERNATIVE_DISPATCH_STRATEGY_H_
#define NET_TTNET_URL_DISPATCHER_MAIN_ALTERNATIVE_DISPATCH_STRATEGY_H_

#include "base/memory/weak_ptr.h"
#include "base/timer/timer.h"
#include "net/tt_net/url_dispatcher/history_based_dispatch_strategy.h"
#include "net/url_request/url_fetcher_delegate.h"

namespace net {

class MainAlternativeDispatchStrategy
    : public HistoryBasedDispatchStrategy,
      public HistoryBasedDispatchStrategy::RequestResultHistoryObserver,
      public URLFetcherDelegate {
 public:
  explicit MainAlternativeDispatchStrategy(
      const base::DictionaryValue* strategy_info);
  ~MainAlternativeDispatchStrategy() override;

  // DispatchStrategy implementations:
  GURL GetTargetURL(const GURL& original_url) override;

  DispatchStrategyType GetStrategyType() const override;

 private:
  struct HostGroup {
    struct MainHostEntity;
    struct AlternativeHostEntity;
    struct HostEntity {
      enum Priority { UNSPECIFIED, MAIN, ALTERNATIVE };

      Priority priority{UNSPECIFIED};
      int64_t failed_count{0};  // Count of consecutive request failures.

      explicit HostEntity();
      virtual ~HostEntity();
      static std::unique_ptr<HostEntity> Factory(Priority priority);
      MainHostEntity* GetAsMainEntity();
      virtual void Reset();
    };
    using HostEntityMap =
        quiche::SimpleLinkedHashMap<std::string, std::unique_ptr<HostEntity>>;

    // The main host has privilege, it can compete for dispatching rights by
    // checking its connectivity.
    struct MainHostEntity : HostEntity {
      // Timer for executing the privilege to check its connectivity.
      base::OneShotTimer privilege_timer;
      // Timer for |resume_request| timeout.
      base::OneShotTimer request_timeout_timer;
      // Send a request to check connectivity.
      std::unique_ptr<URLFetcher> resume_request{nullptr};

      MainHostEntity();
      ~MainHostEntity() override;
      void Reset() override;
    };

    // The alternative host has no privilege.
    struct AlternativeHostEntity : HostEntity {
      AlternativeHostEntity();
      ~AlternativeHostEntity() override;
    };

    // When this host failures count reaches the |failure_count_threshold|, we
    // will select the next host.
    int failure_count_threshold{50};
    uint16_t privilege_delay_s{10 * 60};
    uint16_t request_timeout_s{15};
    HostEntityMap entities;

    HostGroup();
    ~HostGroup();
  };
  using HostEntity = HostGroup::HostEntity;
  using Priority = HostGroup::HostEntity::Priority;
  using HostEntityMap = HostGroup::HostEntityMap;

  // URLFetcherDelegate implementations:
  void OnURLFetchComplete(const net::URLFetcher* source) override;

  // HistoryBasedLoadBalance::RequestResultHistoryObserver implementations:
  void OnSampleAddedToHistory(const std::string& host,
                              RequestResult result) override;

  // iterate over |iterations| times at the |position| circularly.
  void IterateEntityMap(HostEntityMap::iterator* position, size_t iterations);

  void OnHostHistoryReceived(const std::string& host, RequestResult result);

  void OnHostResumeRequestStarted(const std::string& host);

  void OnHostResumeRequestTimeout(const GURL& target_url);

  HostGroup host_group_;
  // The entity iterator selected by the last request.
  HostEntityMap::iterator selected_it_;

  base::WeakPtrFactory<MainAlternativeDispatchStrategy> weak_factory_;
  DISALLOW_COPY_AND_ASSIGN(MainAlternativeDispatchStrategy);
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_MAIN_ALTERNATIVE_DISPATCH_STRATEGY_H_
