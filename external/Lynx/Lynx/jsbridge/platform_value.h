//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_PLATFORM_VALUE_H_
#define LYNX_JSBRIDGE_PLATFORM_VALUE_H_

#include <memory>

#include "jsbridge/jsi/jsi.h"

namespace lynx {
namespace piper {

// PlatformValue is used to hold platform(android/ios/renderkit) values in
// native code. It is usually converted from a piper value, and will be sent to
// platform code to perform a UI operation.
//
// It is forbidden to copy a PlatformValue.
//
// Construction:
// - use FromPiperJsObject() to construct from a js object `{...}`.
//
class PlatformValue {
 public:
  virtual ~PlatformValue() = default;

  PlatformValue(const PlatformValue &) = delete;
  PlatformValue &operator=(const PlatformValue &) = delete;

  PlatformValue(PlatformValue &&) = default;
  PlatformValue &operator=(PlatformValue &&) = default;

  // only for js object '{...}'.
  static std::unique_ptr<PlatformValue> FromPiperJsObject(
      const Object *piper_object, std::weak_ptr<Runtime> rt);

 protected:
  PlatformValue() = default;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_PLATFORM_VALUE_H_
