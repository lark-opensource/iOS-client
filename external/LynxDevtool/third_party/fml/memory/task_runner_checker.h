// Copyright 2013 The Flutter Authors. All rights reserved.
// Copyright 2022 The Lynx Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef THIRD_PARTY_FLUTTER_FML_MEMORY_TASK_RUNNER_CHECKER_H_
#define THIRD_PARTY_FLUTTER_FML_MEMORY_TASK_RUNNER_CHECKER_H_

#include "third_party/fml/message_loop.h"
#include "third_party/fml/task_runner.h"

namespace lynx {
namespace fml {

class TaskRunnerChecker final {
 public:
  TaskRunnerChecker();

  ~TaskRunnerChecker();

  bool RunsOnCreationTaskRunner() const;

  static bool RunsOnTheSameThread(TaskQueueId queue_a, TaskQueueId queue_b);

 private:
  TaskQueueId initialized_queue_id_;
  std::set<TaskQueueId> subsumed_queue_ids_;

  TaskQueueId InitTaskQueueId();
};

#if !defined(NDEBUG)
#define FML_DECLARE_TASK_RUNNER_CHECKER(c) fml::TaskRunnerChecker c
#define FML_DCHECK_TASK_RUNNER_IS_CURRENT(c) \
  DCHECK((c).RunsOnCreationTaskRunner())
#else
#define FML_DECLARE_TASK_RUNNER_CHECKER(c)
#define FML_DCHECK_TASK_RUNNER_IS_CURRENT(c) ((void)0)
#endif

}  // namespace fml
}  // namespace lynx

#endif  // THIRD_PARTY_FLUTTER_FML_MEMORY_THREAD_CHECKER_H_
