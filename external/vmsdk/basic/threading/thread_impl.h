// Copyright 2017 The Vmsdk Authors. All rights reserved.

#ifndef VMSDK_BASE_THREADING_THREAD_IMPL_H
#define VMSDK_BASE_THREADING_THREAD_IMPL_H

#include <pthread.h>
#include <unistd.h>

#include <string>

#include "basic/threading/message_loop.h"

namespace vmsdk {
namespace general {

struct ThreadInfo {
  std::string name;

  // The current thread’s priority, which is integer from 0 to 1, where 1 is the
  // highest priority. Default thread's priority is 5.
  //
  // TODO(yxping): Now only Android thread support priority, we should support
  // priority on iOS and pthread
  int32_t priority;

  explicit ThreadInfo(const std::string &name, int32_t priority = 5)
      : name(name), priority(priority) {}
};

class ThreadImpl {
 public:
  explicit ThreadImpl(MessageLoop::MESSAGE_LOOP_TYPE type,
                      const ThreadInfo &info)
      : message_loop_(type),
        thread_handle_(0),
        thread_name_(info.name),
        priority_(info.priority) {}

  virtual ~ThreadImpl() {}

  virtual void Start() = 0;

  virtual void Stop() {
    message_loop_.Quit(
        general::Bind([self = this]() { self->message_loop_.Stop(); }));
    Join();
  }

  virtual void Join() = 0;

  virtual void Run() {
    thread_id_ = CurrentId();
    message_loop_.BindToCurrentThread();
    message_loop_.Run();
  }

  const std::string &thread_name() { return thread_name_; }

  MessageLoop *looper() { return &message_loop_; }

  long int thread_id() { return thread_id_; }

  pthread_t thread_handle() { return thread_handle_; }

  inline int priority() { return priority_; }

  static long int CurrentId() {
#ifdef OS_IOS
    return pthread_mach_thread_np(pthread_self());
#elif OS_ANDROID
    return gettid();
#else
    return 0;
#endif
  }

  static int32_t CurrentProcessId() {
    return static_cast<int32_t>(CurrentId());
  }

 protected:
  MessageLoop message_loop_;
  pthread_t thread_handle_;

 private:
  long int thread_id_;
  std::string thread_name_;
  int priority_;
};

}  // namespace general
}  // namespace vmsdk

#endif  // VMSDK_BASE_THREADING_THREAD_IMPL_H
