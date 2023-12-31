//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_RENDERKIT_PLATFORM_VALUE_RENDERKIT_H_
#define LYNX_JSBRIDGE_RENDERKIT_PLATFORM_VALUE_RENDERKIT_H_

#include <utility>

#include "jsbridge/platform_value.h"
#include "third_party/renderkit/include/rk_modules.h"

namespace lynx {
namespace piper {

class PlatformValueRenderkit : public PlatformValue {
 public:
  explicit PlatformValueRenderkit(RKLynxModuleArgsRef value) : value_(value) {}
  ~PlatformValueRenderkit() override;

  RKLynxModuleArgsRef Get() const { return value_; }

 private:
  RKLynxModuleArgsRef value_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RENDERKIT_PLATFORM_VALUE_RENDERKIT_H_
