// Copyright 2013 The Flutter Authors. All rights reserved.
// Copyright 2022 The Lynx Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "third_party/fml/task_runner.h"

#include <utility>

#include "third_party/fml/memory/task_runner_checker.h"
#include "third_party/fml/message_loop.h"
#include "third_party/fml/message_loop_impl.h"
#include "third_party/fml/message_loop_task_queues.h"
#include "third_party/fml/synchronization/waitable_event.h"

namespace lynx {
namespace fml {

TaskRunner::TaskRunner(fml::RefPtr<MessageLoopImpl> loop)
    : loop_(std::move(loop)) {}

TaskRunner::~TaskRunner() = default;

void TaskRunner::PostTask(base::closure task) {
  loop_->PostTask(std::move(task), fml::TimePoint::Now());
}

void TaskRunner::PostEmergencyTask(base::closure task) {
  loop_->PostTask(std::move(task), fml::TimePoint::Now(),
                  fml::TaskSourceGrade::kEmergency);
}

void TaskRunner::PostIdleTask(base::closure task) {
  loop_->PostTask(std::move(task), fml::TimePoint::Now(),
                  fml::TaskSourceGrade::kIdle);
}

void TaskRunner::PostSyncTask(base::closure task) {
  if (RunsTasksOnCurrentThread()) {
    task();
  } else {
    fml::AutoResetWaitableEvent arwe;
    PostTask([task = std::move(task), &arwe]() {
      task();
      arwe.Signal();
    });
    arwe.Wait();
  }
}

void TaskRunner::PostTaskForTime(base::closure task,
                                 fml::TimePoint target_time) {
  loop_->PostTask(std::move(task), target_time);
}

void TaskRunner::PostDelayedTask(base::closure task, fml::TimeDelta delay) {
  loop_->PostTask(std::move(task), fml::TimePoint::Now() + delay);
}

TaskQueueId TaskRunner::GetTaskQueueId() {
  DCHECK(loop_);
  return loop_->GetTaskQueueId();
}

// TODO(heshan):this method acquires the lock of MessageLoopTaskQueues
// three times, needs to be optimized.
bool TaskRunner::RunsTasksOnCurrentThread() {
  if (!fml::MessageLoop::IsInitializedForCurrentThread()) {
    return false;
  }

  const auto current_queue_id = MessageLoop::GetCurrentTaskQueueId();

  // if current queue is subsumed, means current loop is suspended.
  if (MessageLoopTaskQueues::GetInstance()->IsSubsumed(current_queue_id)) {
    return false;
  }

  const auto loop_queue_id = loop_->GetTaskQueueId();

  return TaskRunnerChecker::RunsOnTheSameThread(current_queue_id,
                                                loop_queue_id);
}

void TaskRunner::RunNowOrPostTask(fml::RefPtr<fml::TaskRunner> runner,
                                  base::closure task) {
  DCHECK(runner);
  if (runner->RunsTasksOnCurrentThread()) {
    task();
  } else {
    runner->PostTask(std::move(task));
  }
}

void TaskRunner::RunNowOrPostTask(std::shared_ptr<fml::TaskRunner> runner,
                                  base::closure task) {
  DCHECK(runner);
  if (runner->RunsTasksOnCurrentThread()) {
    task();
  } else {
    runner->PostTask(std::move(task));
  }
}

}  // namespace fml
}  // namespace lynx
