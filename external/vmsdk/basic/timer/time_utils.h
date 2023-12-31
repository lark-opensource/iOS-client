// Copyright 2017 The Vmsdk Authors. All rights reserved.

#ifndef VMSDK_BASE_TIMER_TIME_UTILS_H_
#define VMSDK_BASE_TIMER_TIME_UTILS_H_

#include <time.h>

#include <cstdint>

namespace vmsdk {
namespace general {
uint64_t CurrentTimeMicroseconds();
uint64_t CurrentTimeMilliseconds();
uint64_t CurrentThreadCPUTimeMicroseconds();
timespec ToTimeSpecFromNow(uint64_t interval_time);
}  // namespace general
}  // namespace vmsdk

#endif  // VMSDK_BASE_TIMER_TIME_UTILS_H_
