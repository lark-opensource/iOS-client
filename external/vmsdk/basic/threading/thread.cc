// Copyright 2017 The Vmsdk Authors. All rights reserved.

#include "basic/threading/thread.h"

#include <string.h>

#include <iostream>

#include "basic/log/logging.h"
#include "basic/threading/thread_impl_posix.h"
#if OS_ANDROID
#include "basic/threading/thread_impl_android.h"
#endif
#ifdef OS_IOS
#include "basic/threading/thread_impl_ios.h"
#endif

namespace vmsdk {
namespace general {

static std::unique_ptr<ThreadImpl> CreateThreadImpl(
    MessageLoop::MESSAGE_LOOP_TYPE type, const ThreadInfo &info) {
#if OS_ANDROID
  if (type == MessageLoop::MESSAGE_LOOP_TYPE::MESSAGE_LOOP_PLATFORM ||
      type == MessageLoop::MESSAGE_LOOP_TYPE::MESSAGE_LOOP_UI) {
    return std::make_unique<ThreadImplAndroid>(type, info);
  }
#endif
#if OS_IOS
  if (type == MessageLoop::MESSAGE_LOOP_TYPE::MESSAGE_LOOP_PLATFORM ||
      type == MessageLoop::MESSAGE_LOOP_TYPE::MESSAGE_LOOP_UI) {
    return std::make_unique<ThreadImplIOS>(type, info);
  }

  if (type == MessageLoop::MESSAGE_LOOP_TYPE::MESSAGE_LOOP_JS) {
    return std::make_unique<ThreadImplIOS>(type, info);
  }
#endif
  return std::make_unique<ThreadImplPosix>(type, info);
}

Thread::Thread(MessageLoop::MESSAGE_LOOP_TYPE type, const std::string &name)
    : impl_(CreateThreadImpl(type, ThreadInfo(name))) {}

Thread::Thread(MessageLoop::MESSAGE_LOOP_TYPE type) : Thread(type, "") {}

Thread::Thread(MessageLoop::MESSAGE_LOOP_TYPE type, const ThreadInfo &info)
    : impl_(CreateThreadImpl(type, info)) {}

Thread::~Thread() { Stop(); }

void Thread::Start() {
  {
    std::lock_guard<std::mutex> lock(GetGlobalStateLock());
    GetRunningThreads().push_back(this);
  }
  impl_->Start();
}

void Thread::Stop() {
  {
    std::lock_guard<std::mutex> lock(GetGlobalStateLock());
    GetRunningThreads().remove(this);
  }
  impl_->Stop();
}

void Thread::ForEachRunningThread(std::function<void(Thread *)> callback) {
  std::lock_guard<std::mutex> lock(GetGlobalStateLock());
  for (const auto &thread : GetRunningThreads()) {
    callback(thread);
  }
}

std::mutex &Thread::GetGlobalStateLock() {
  static basic::NoDestructor<std::mutex> global_state_lock;
  return *global_state_lock;
}

std::list<Thread *> &Thread::GetRunningThreads() {
  static basic::NoDestructor<std::list<Thread *>> running_threads;
  return *running_threads;
}

}  // namespace general
}  // namespace vmsdk
