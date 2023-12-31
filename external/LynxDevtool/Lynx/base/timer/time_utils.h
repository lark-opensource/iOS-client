// Copyright 2017 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_TIMER_TIME_UTILS_H_
#define LYNX_BASE_TIMER_TIME_UTILS_H_

#include <time.h>

#include <cstdint>

#include "base/base_export.h"

namespace lynx {
namespace base {
// This method should not be used except in unsatisfied scenarios.
uint64_t CurrentSystemTimeMilliseconds();
uint64_t CurrentTimeMicroseconds();
BASE_EXPORT_FOR_DEVTOOL uint64_t CurrentTimeMilliseconds();
uint64_t CurrentThreadCPUTimeMicroseconds();
#if !defined(OS_WIN)
timespec ToTimeSpecFromNow(uint64_t interval_time);
#endif
}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_TIMER_TIME_UTILS_H_
