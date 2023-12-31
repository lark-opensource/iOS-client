// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_TIME_H_
#define LYNX_KRYPTON_AURUM_TIME_H_

namespace lynx {
namespace canvas {
namespace au {

inline uint64_t CurrentTimeUs() {
  struct timespec time;
  if (__builtin_available(iOS 10.0, *)) {
    clock_gettime(CLOCK_MONOTONIC, &time);
  }
  return uint64_t(time.tv_sec) * 1000000LLU + time.tv_nsec / 1000;
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_TIME_H_
