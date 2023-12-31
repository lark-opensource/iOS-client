// Copyright 2017 The Vmsdk Authors. All rights reserved.

#ifndef VMSDK_BASE_THREADING_THREAD_H_
#define VMSDK_BASE_THREADING_THREAD_H_

#include <pthread.h>

#include <list>
#include <mutex>
#include <string>

#include "basic/no_destructor.h"
#include "basic/threading/message_loop.h"
#include "basic/threading/thread_impl.h"

namespace vmsdk {
namespace general {

class Thread {
 public:
  explicit Thread(MessageLoop::MESSAGE_LOOP_TYPE type);

  explicit Thread(MessageLoop::MESSAGE_LOOP_TYPE type, const std::string &name);

  explicit Thread(MessageLoop::MESSAGE_LOOP_TYPE type, const ThreadInfo &info);

  virtual ~Thread();

  void Start();
  void Stop();

  const std::string &thread_name() { return impl_->thread_name(); }

  long int thread_id() { return impl_->thread_id(); }

  MessageLoop *Looper() { return impl_->looper(); }

  static long int CurrentId() { return ThreadImpl::CurrentId(); }

  static uint32_t CurrentProcessId() { return ThreadImpl::CurrentProcessId(); }

  static void ForEachRunningThread(
      const std::function<void(Thread *)> callback);

  static std::mutex &GetGlobalStateLock();

  static std::list<Thread *> &GetRunningThreads();

 private:
  std::unique_ptr<ThreadImpl> impl_;
};

}  // namespace general
}  // namespace vmsdk
#endif  // VMSDK_BASE_THREADING_THREAD_H_
