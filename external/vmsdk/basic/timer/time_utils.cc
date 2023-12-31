// Copyright 2017 The Vmsdk Authors. All rights reserved.

#include "basic/timer/time_utils.h"

#include <sys/time.h>
#include <time.h>

#include <chrono>
#include <cstdint>

namespace vmsdk {
namespace general {

uint64_t CurrentTimeMilliseconds() {
  // Use steady clock to guarantee the clock is monotonic.
  const auto time = std::chrono::steady_clock::now().time_since_epoch();
  return std::chrono::duration_cast<std::chrono::milliseconds>(time).count();
}

uint64_t CurrentTimeMicroseconds() {
  // Use steady clock to guarantee the clock is monotonic.
  const auto time = std::chrono::steady_clock::now().time_since_epoch();
  return std::chrono::duration_cast<std::chrono::microseconds>(time).count();
}

uint64_t CurrentThreadCPUTimeMicroseconds() {
  struct timespec ts;
#if OS_IOS
  if (__builtin_available(iOS 10.0, *)) {
    clock_gettime(CLOCK_THREAD_CPUTIME_ID, &ts);
  } else {
    // TODO(liushouqun):solved this on ios
    return -1;
  }
#elif OS_ANDROID
  clock_gettime(CLOCK_THREAD_CPUTIME_ID, &ts);
#endif
  uint64_t cpu_thread_time = ts.tv_sec;
  cpu_thread_time *= 1000ll * 1000ll;
  cpu_thread_time += ts.tv_nsec / 1000ll;
  return cpu_thread_time;
}

timespec ToTimeSpecFromNow(uint64_t interval_time) {
  // FIXME: Currently `ToTimeSpecFromNow` is only used by the Condition class,
  // which provides abstime for `pthread_cond_timedwait`, however this is buggy
  // because the time is not monotonic.
  // Consider using monotonic time in Condition class by the following setting:
  //  ```
  //    pthread_condattr_setclock(&attrs, CLOCK_MONOTONIC);
  //  ```
  timespec out_time;
  struct timeval now;
  uint64_t absmsec;
  gettimeofday(&now, nullptr);
  absmsec = now.tv_sec * 1000ll + now.tv_usec / 1000ll;
  absmsec += interval_time;

  out_time.tv_sec = static_cast<time_t>(absmsec / 1000ll);
  out_time.tv_nsec = static_cast<long>(absmsec % 1000ll * 1000000ll);
  return out_time;
}
}  // namespace general
}  // namespace vmsdk
