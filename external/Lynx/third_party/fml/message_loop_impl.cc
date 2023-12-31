// Copyright 2013 The Flutter Authors. All rights reserved.
// Copyright 2022 The Lynx Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "third_party/fml/message_loop_impl.h"

#include <algorithm>
#include <vector>

#include "base/trace_event/trace_event.h"
#include "third_party/fml/build_config.h"

#if FML_OS_MACOSX
#include "third_party/fml/platform/darwin/message_loop_darwin.h"
#elif FML_OS_ANDROID
#include "third_party/fml/platform/android/message_loop_android.h"
#elif OS_FUCHSIA
#include "third_party/fml/platform/fuchsia/message_loop_fuchsia.h"
#elif FML_OS_LINUX
#include "third_party/fml/platform/linux/message_loop_linux.h"
#elif FML_OS_WIN
#include "third_party/fml/platform/win/message_loop_win.h"
#endif

namespace lynx {
namespace fml {

fml::RefPtr<MessageLoopImpl> MessageLoopImpl::Create() {
#if FML_OS_MACOSX
  return fml::MakeRefCounted<MessageLoopDarwin>();
#elif FML_OS_ANDROID
  return fml::MakeRefCounted<MessageLoopAndroid>();
#elif OS_FUCHSIA
  return fml::MakeRefCounted<MessageLoopFuchsia>();
#elif FML_OS_LINUX
  return fml::MakeRefCounted<MessageLoopLinux>();
#elif FML_OS_WIN
  return fml::MakeRefCounted<MessageLoopWin>();
#else
  return nullptr;
#endif
}

MessageLoopImpl::MessageLoopImpl()
    : task_queue_(MessageLoopTaskQueues::GetInstance()),
      queue_id_(task_queue_->CreateTaskQueue()),
      terminated_(false) {
  task_queue_->SetWakeable(queue_id_, this);
}

MessageLoopImpl::~MessageLoopImpl() { task_queue_->Dispose(queue_id_); }

void MessageLoopImpl::PostTask(base::closure task, fml::TimePoint target_time,
                               fml::TaskSourceGrade task_source_grade) {
  DCHECK(task != nullptr);
  DCHECK(task != nullptr);
  if (terminated_) {
    // If the message loop has already been terminated, PostTask should destruct
    // |task| synchronously within this function.
    return;
  }
  task_queue_->RegisterTask(queue_id_, std::move(task), target_time,
                            task_source_grade);
}

void MessageLoopImpl::DoRun() {
  if (terminated_) {
    // Message loops may be run only once.
    return;
  }

  // Allow the implementation to do its thing.
  Run();

  // The loop may have been implicitly terminated. This can happen if the
  // implementation supports termination via platform specific APIs or just
  // error conditions. Set the terminated flag manually.
  terminated_ = true;

  // The message loop is shutting down. Check if there are expired tasks. This
  // is the last chance for expired tasks to be serviced. Make sure the
  // terminated flag is already set so we don't accrue additional tasks now.
  RunExpiredTasksNow();

  // When the message loop is in the process of shutting down, pending tasks
  // should be destructed on the message loop's thread. We have just returned
  // from the implementations |Run| method which we know is on the correct
  // thread. Drop all pending tasks on the floor.
  task_queue_->DisposeTasks(queue_id_);
}

void MessageLoopImpl::DoTerminate() {
  terminated_ = true;
  Terminate();
}

void MessageLoopImpl::FlushTasks(FlushType type) {
  TRACE_EVENT("lynx", "MessageLoop::FlushTasks");

  const auto now = fml::TimePoint::Now();
  base::closure invocation;
  do {
    invocation = task_queue_->GetNextTaskToRun(queue_id_, now);
    if (!invocation) {
      break;
    }
    invocation();
    if (type == FlushType::kSingle) {
      break;
    }
  } while (invocation);
}

void MessageLoopImpl::RunExpiredTasksNow() { FlushTasks(FlushType::kAll); }

void MessageLoopImpl::RunSingleExpiredTaskNow() {
  FlushTasks(FlushType::kSingle);
}

TaskQueueId MessageLoopImpl::GetTaskQueueId() const { return queue_id_; }

}  // namespace fml
}  // namespace lynx
