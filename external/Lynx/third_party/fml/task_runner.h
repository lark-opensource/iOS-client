// Copyright 2013 The Flutter Authors. All rights reserved.
// Copyright 2022 The Lynx Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef THIRD_PARTY_FLUTTER_FML_TASK_RUNNER_H_
#define THIRD_PARTY_FLUTTER_FML_TASK_RUNNER_H_

#include "base/base_export.h"
#include "base/closure.h"
#include "third_party/fml/macros.h"
#include "third_party/fml/memory/ref_counted.h"
#include "third_party/fml/memory/ref_ptr.h"
#include "third_party/fml/message_loop_task_queues.h"
#include "third_party/fml/time/time_point.h"
namespace lynx {
namespace fml {

class MessageLoopImpl;

/// An interface over the ability to schedule tasks on a \p TaskRunner.
class BasicTaskRunner {
 public:
  /// Schedules \p task to be executed on the TaskRunner's associated event
  /// loop.
  virtual void PostTask(base::closure task) = 0;
};

/// The object for scheduling tasks on a \p fml::MessageLoop.
///
/// Typically there is one \p TaskRunner associated with each thread.  When one
/// wants to execute an operation on that thread they post a task to the
/// TaskRunner.
///
/// \see fml::MessageLoop
class TaskRunner : public fml::RefCountedThreadSafe<TaskRunner>,
                   public BasicTaskRunner {
 public:
  virtual ~TaskRunner();

  virtual void PostTask(base::closure task) override;

  virtual void PostTaskForTime(base::closure task, fml::TimePoint target_time);

  /// Schedules a task to be run on the MessageLoop after the time \p delay has
  /// passed.
  /// \note There is latency between when the task is schedule and actually
  /// executed so that the actual execution time is: now + delay +
  /// message_loop_latency, where message_loop_latency is undefined and could be
  /// tens of milliseconds.
  virtual void PostDelayedTask(base::closure task, fml::TimeDelta delay);

  /// Returns \p true when the current executing thread's TaskRunner matches
  /// this instance.
  virtual bool RunsTasksOnCurrentThread();

  /// Returns the unique identifier associated with the TaskRunner.
  /// \see fml::MessageLoopTaskQueues
  virtual TaskQueueId GetTaskQueueId();

  void PostEmergencyTask(base::closure task);

  // Schedules a task in the idle period.
  // TODO(heshan):now this method just schedules a lowest priority task,
  // and will implement as web standard in the future.
  // https://w3c.github.io/requestidlecallback/#the-requestidlecallback-method
  void PostIdleTask(base::closure task);

  BASE_EXPORT void PostSyncTask(base::closure task);

  /// Executes the \p task directly if the TaskRunner \p runner is the
  /// TaskRunner associated with the current executing thread.
  BASE_EXPORT static void RunNowOrPostTask(fml::RefPtr<fml::TaskRunner> runner,
                                           base::closure task);
  static void RunNowOrPostTask(std::shared_ptr<fml::TaskRunner> runner,
                               base::closure task);

 protected:
  explicit TaskRunner(fml::RefPtr<MessageLoopImpl> loop);

 private:
  fml::RefPtr<MessageLoopImpl> loop_;

  FML_FRIEND_MAKE_REF_COUNTED(TaskRunner);
  FML_FRIEND_REF_COUNTED_THREAD_SAFE(TaskRunner);
  FML_DISALLOW_COPY_AND_ASSIGN(TaskRunner);
};

}  // namespace fml
}  // namespace lynx

#endif  // THIRD_PARTY_FLUTTER_FML_TASK_RUNNER_H_
