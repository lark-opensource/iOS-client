// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_LOAD_MONITOR_TT_LOAD_MONITOR_MANAGER_H
#define NET_TT_NET_LOAD_MONITOR_TT_LOAD_MONITOR_MANAGER_H

#include "base/macros.h"
#include "base/memory/singleton.h"
#include "base/power_monitor/power_observer.h"
#include "base/task/task_observer.h"
#include "base/time/time.h"
#include "net/net_buildflags.h"
#include "net/tt_net/route_selection/tt_server_config.h"

namespace base {
struct PendingTask;
}  // namespace base

namespace net {

class TTLoadMonitorManager : base::TaskObserver,
                             base::PowerObserver,
                             public TTServerConfigObserver {
 public:
  static TTLoadMonitorManager* GetInstance();

  void OnServerConfigChanged(
      UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;

 private:
  friend struct base::DefaultSingletonTraits<TTLoadMonitorManager>;
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  FRIEND_TEST_ALL_PREFIXES(TTLoadMonitorManagerTest, ParseServerConfig);
  FRIEND_TEST_ALL_PREFIXES(TTLoadMonitorManagerTest, SetUpTearDown);
  FRIEND_TEST_ALL_PREFIXES(TTLoadMonitorManagerTest, StartStop);
  FRIEND_TEST_ALL_PREFIXES(TTLoadMonitorManagerTest, RunTasks);
  FRIEND_TEST_ALL_PREFIXES(TTLoadMonitorManagerTest, SendMonitor);
  FRIEND_TEST_ALL_PREFIXES(TTLoadMonitorManagerTest, IgnoreTask);
  FRIEND_TEST_ALL_PREFIXES(TTLoadMonitorManagerTest, LoadInfo);
  FRIEND_TEST_ALL_PREFIXES(TTLoadMonitorManagerTest, ProcessSuspend);
  FRIEND_TEST_ALL_PREFIXES(TTLoadMonitorManagerTest, ProcessObserver);
#endif

  TTLoadMonitorManager();

  ~TTLoadMonitorManager() override;

  struct TNCConfig {
    bool load_collect_enable;
    bool load_detail_collect_enable;
    int measure_interval_s;
    int suspend_threshold_s;
    int rank1_threshold_ms;
    int rank2_threshold_ms;
    int rank3_threshold_ms;

    TNCConfig();

    TNCConfig(const TNCConfig& other);

    ~TNCConfig();
  };

  TNCConfig tnc_config_;

  struct MQLoadInfo {
    enum State {
      QUEUE_MAX_IS_BLOCK_OR_LOW_PRIORITY = 1 << 0,
      EXEC_MAX_IS_BLOCK_OR_LOW_PRIORITY = 1 << 1,
      WAS_PROCESS_SUSPEND = 1 << 2,
    };

    uint32_t handled_tasks{0};
    uint32_t queue_avg_us{0};
    uint32_t queue_max_us{0};
    uint32_t queue_max_delay_ms{0};
    base::Location queue_max_location;

    uint32_t exec_avg_us{0};
    uint32_t exec_max_us{0};
    uint32_t exec_max_delay_ms{0};
    base::Location exec_max_location;

    uint32_t qps{0};
    uint8_t queue_of_all{0};
    uint8_t info_state{0};

    uint32_t rank1{0};
    uint32_t rank2{0};
    uint32_t rank3{0};

    // An opaque identifier for the task
    const void* current_identifier{nullptr};
    // Whether the task was at some point in a queue that was blocked or low
    // priority.
    bool current_was_blocked_or_low_priority{false};
    // The time at which the task or event started running.
    base::TimeTicks current_execution_start_time;

    MQLoadInfo();

    MQLoadInfo(const MQLoadInfo& other);

    ~MQLoadInfo();
  };

  MQLoadInfo mq_load_info_;

  bool is_main_process_{false};

  bool load_collect_started_{false};

  // Whether or not the process is suspended (Power management).
  bool is_process_suspended_{false};
  // Stores whether to process was suspended since last metric computation.
  bool was_process_suspended_{false};

  base::TimeTicks last_calculation_time_;

  base::TimeTicks most_recent_activity_time_;

  void SetProcessSuspended(bool suspended);

  // base::PowerObserver interface implementation
  void OnSuspend() override;

  void OnResume() override;

  void PostLoadCollectChange(bool enable);

  void StartLoadCollectOnIOThread();

  void StopLoadCollectOnIOThread();

  // These methods are called by IO thread to collect metadata about the tasks
  // being run.
  void WillProcessTask(const base::PendingTask& pending_task,
                       bool was_blocked_or_low_priority) override;

  void DidProcessTask(const base::PendingTask& pending_task) override;

  void TaskFinishedOnIOThread(const base::PendingTask& pending_task,
                              const base::TimeTicks& execution_finish_time);

  void SendMetricIfNecessary(const base::TimeTicks& current_time);

  void SendMonitor(const MQLoadInfo& loadInfo) const;

  bool ParseJsonResult(const base::Optional<base::Value>& tnc_config_value);

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
 public:
  void SetMainProcessForTesting(bool isMainProcess);
  void DeinitForTesting();
#endif
  DISALLOW_COPY_AND_ASSIGN(TTLoadMonitorManager);
};

}  // namespace net

#endif  // NET_TT_NET_LOAD_MONITOR_TT_LOAD_MONITOR_MANAGER_H
