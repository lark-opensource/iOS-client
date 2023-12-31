// Copyright 2017 The Vmsdk Authors. All rights reserved.

#ifndef VMSDK_BASE_THREADING_THREAD_IMPL_POSIX_H
#define VMSDK_BASE_THREADING_THREAD_IMPL_POSIX_H

#include <pthread.h>

#include <string>

#include "basic/threading/thread_impl.h"

namespace vmsdk {
namespace general {

class ThreadImplPosix : public ThreadImpl {
 public:
  explicit ThreadImplPosix(MessageLoop::MESSAGE_LOOP_TYPE type,
                           const ThreadInfo &name);

  virtual ~ThreadImplPosix();

  void Start() override;

  void Join() override;
};

}  // namespace general
}  // namespace vmsdk

#endif  // VMSDK_BASE_THREADING_THREAD_IMPL_POSIX_H
