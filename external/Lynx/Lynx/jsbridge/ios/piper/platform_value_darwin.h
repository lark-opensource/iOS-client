//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_IOS_PIPER_PLATFORM_VALUE_DARWIN_H_
#define LYNX_JSBRIDGE_IOS_PIPER_PLATFORM_VALUE_DARWIN_H_

#import <objc/runtime.h>

#include <memory>
#include <utility>

#import "jsbridge/platform_value.h"

namespace lynx {
namespace piper {
class PlatformValueDarwin : public PlatformValue {
 public:
  PlatformValueDarwin(id value) : value_(std::move(value)){};

  // only for js object '{...}'.
  static std::unique_ptr<PlatformValueDarwin> FromPiperJsObject(
      const Object *piper_object, std::weak_ptr<Runtime> rt);

  id Get() { return value_; }

 private:
  id value_;
};
}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_IOS_PIPER_PLATFORM_VALUE_DARWIN_H_
