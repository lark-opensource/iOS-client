// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_URL_LOADER_H_
#define LYNX_KRYPTON_AURUM_URL_LOADER_H_

#include <stdint.h>

namespace lynx {
namespace canvas {

namespace au {
class PlatformLoaderDelegate {
 public:
  virtual void OnStart(int64_t content_length = -1) = 0;  // optional
  virtual void OnData(const void* data, uint64_t len) = 0;
  virtual void OnEnd(bool success = true,
                     const char* err_msg = 0) = 0;  // final call
};
}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_URL_LOADER_H_
