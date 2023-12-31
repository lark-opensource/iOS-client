// Copyright 2013 The Flutter Authors. All rights reserved.
// Copyright 2022 The Lynx Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "third_party/fml/message_loop.h"

#include <utility>

#include "base/no_destructor.h"
#include "third_party/fml/memory/ref_counted.h"
#include "third_party/fml/memory/ref_ptr.h"
#include "third_party/fml/message_loop_impl.h"
#include "third_party/fml/task_runner.h"
#include "third_party/fml/thread_local.h"

namespace lynx {
namespace fml {

namespace {
ThreadLocalUniquePtr<MessageLoop>& GetThreadLocalLooper() {
  FML_THREAD_LOCAL base::NoDestructor<ThreadLocalUniquePtr<MessageLoop>>
      tls_message_loop_instance;
  return *tls_message_loop_instance;
}
}  // namespace

MessageLoop& MessageLoop::GetCurrent() {
  auto* loop = GetThreadLocalLooper().get();
  CHECK(loop != nullptr)
      << "MessageLoop::EnsureInitializedForCurrentThread was not called on "
         "this thread prior to message loop use.";
  return *loop;
}

void MessageLoop::EnsureInitializedForCurrentThread() {
  if (GetThreadLocalLooper().get() != nullptr) {
    // Already initialized.
    return;
  }
  GetThreadLocalLooper().reset(new MessageLoop());
}

bool MessageLoop::IsInitializedForCurrentThread() {
  return GetThreadLocalLooper().get() != nullptr;
}

MessageLoop::MessageLoop()
    : loop_(MessageLoopImpl::Create()),
      task_runner_(fml::MakeRefCounted<fml::TaskRunner>(loop_)) {
  CHECK(loop_);
  CHECK(task_runner_);
}

MessageLoop::~MessageLoop() = default;

void MessageLoop::Run() { loop_->DoRun(); }

void MessageLoop::Terminate() { loop_->DoTerminate(); }

fml::RefPtr<fml::TaskRunner> MessageLoop::GetTaskRunner() const {
  return task_runner_;
}

fml::RefPtr<MessageLoopImpl> MessageLoop::GetLoopImpl() const { return loop_; }

void MessageLoop::RunExpiredTasksNow() { loop_->RunExpiredTasksNow(); }

TaskQueueId MessageLoop::GetCurrentTaskQueueId() {
  auto* loop = GetThreadLocalLooper().get();
  CHECK(loop != nullptr)
      << "MessageLoop::EnsureInitializedForCurrentThread was not called on "
         "this thread prior to message loop use.";
  return loop->GetLoopImpl()->GetTaskQueueId();
}

}  // namespace fml
}  // namespace lynx
