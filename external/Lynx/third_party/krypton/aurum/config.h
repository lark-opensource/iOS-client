// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_CONFIG_H_
#define LYNX_KRYPTON_AURUM_CONFIG_H_

#define AU_SAMPLE_RATE 44100
#define AU_PLAYBACK_BUF_LEN 480
#define AU_STREAM_BUF_LEN 4096
#define AU_CAPTURE_BUF_LEN 1024

#define AU_MIN(x, y) x ^ ((x ^ y) & -(x > y))
#define AU_MAX(x, y) y ^ ((x ^ y) & -(x > y))
#define AU_MIN_MAX(x, min, max) (x < min) ? min : (x > max) ? max : x

#define AU_LOCK(lock)                          \
  while (__sync_lock_test_and_set(&lock, 1)) { \
    ;                                          \
  }
#define AU_UNLOCK(lock) __sync_lock_release(&lock)

namespace lynx {
namespace canvas {
namespace au {

using SampleFormat = short;
struct Status {
  int code, line;
};

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#define AU_OK \
  Status { 0, 0 }
#define AU_ERROR(code) \
  Status { int(code), __LINE__ }

#endif  // LYNX_KRYPTON_AURUM_CONFIG_H_
