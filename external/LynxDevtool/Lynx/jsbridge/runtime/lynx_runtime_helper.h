// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_RUNTIME_LYNX_RUNTIME_HELPER_H_
#define LYNX_JSBRIDGE_RUNTIME_LYNX_RUNTIME_HELPER_H_

#include <memory>

#include "jsbridge/jsi/jsi.h"

namespace lynx {
namespace runtime {
class LynxRuntimeHelper {
 public:
  virtual std::unique_ptr<piper::Runtime> MakeRuntime() = 0;
};
}  // namespace runtime
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RUNTIME_LYNX_RUNTIME_HELPER_H_
