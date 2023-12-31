// Copyright 2017 The Vmsdk Authors. All rights reserved.

#ifndef VMSDK_BASE_THREADING_CONDITION_H_
#define VMSDK_BASE_THREADING_CONDITION_H_

#include "basic/threading/lock.h"
#include "basic/timer/time_utils.h"

namespace vmsdk {
namespace general {
class Condition {
 public:
  Condition(Lock &lock) : lock_(lock) { pthread_cond_init(&condition_, NULL); }

  ~Condition() { pthread_cond_destroy(&condition_); }

  void Wait() { pthread_cond_wait(&condition_, &lock_.mutex_); }

  void Wait(uint64_t time) {
    timespec next_time = ToTimeSpecFromNow(time);
    pthread_cond_timedwait(&condition_, &lock_.mutex_, &next_time);
  }

  void Signal() { pthread_cond_signal(&condition_); }

  void Broadcast() { pthread_cond_broadcast(&condition_); }

 private:
  Lock &lock_;
  pthread_cond_t condition_;
};
}  // namespace general
}  // namespace vmsdk

#endif  // VMSDK_BASE_THREADING_CONDITION_H_
