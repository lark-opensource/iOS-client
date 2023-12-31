// Copyright 2013 The Flutter Authors. All rights reserved.
// Copyright 2022 The Lynx Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef THIRD_PARTY_FLUTTER_FML_MESSAGE_LOOP_IMPL_H_
#define THIRD_PARTY_FLUTTER_FML_MESSAGE_LOOP_IMPL_H_

#include <atomic>
#include <deque>
#include <map>
#include <mutex>
#include <queue>
#include <utility>

#include "base/closure.h"
#include "third_party/fml/delayed_task.h"
#include "third_party/fml/macros.h"
#include "third_party/fml/memory/ref_counted.h"
#include "third_party/fml/message_loop.h"
#include "third_party/fml/message_loop_task_queues.h"
#include "third_party/fml/time/time_point.h"
#include "third_party/fml/wakeable.h"

namespace lynx {
namespace fml {

/// An abstract class that represents the differences in implementation of a \p
/// fml::MessageLoop depending on the platform.
/// \see fml::MessageLoop
/// \see fml::MessageLoopAndroid
/// \see fml::MessageLoopDarwin
class MessageLoopImpl : public Wakeable,
                        public fml::RefCountedThreadSafe<MessageLoopImpl> {
 public:
  static fml::RefPtr<MessageLoopImpl> Create();

  virtual ~MessageLoopImpl();

  virtual void Run() = 0;

  virtual void Terminate() = 0;

  void PostTask(base::closure task, fml::TimePoint target_time,
                fml::TaskSourceGrade task_source_grade =
                    fml::TaskSourceGrade::kUnspecified);

  void DoRun();

  void DoTerminate();

  virtual TaskQueueId GetTaskQueueId() const;

 protected:
  // Exposed for the embedder shell which allows clients to poll for events
  // instead of dedicating a thread to the message loop.
  friend class MessageLoop;

  void RunExpiredTasksNow();

  void RunSingleExpiredTaskNow();

 protected:
  MessageLoopImpl();

 private:
  MessageLoopTaskQueues* task_queue_;
  TaskQueueId queue_id_;

  std::atomic_bool terminated_;

  void FlushTasks(FlushType type);

  FML_DISALLOW_COPY_AND_ASSIGN(MessageLoopImpl);
};

}  // namespace fml
}  // namespace lynx

#endif  // THIRD_PARTY_FLUTTER_FML_MESSAGE_LOOP_IMPL_H_
