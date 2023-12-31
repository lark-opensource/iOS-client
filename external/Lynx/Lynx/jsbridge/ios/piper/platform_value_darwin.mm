//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "jsbridge/ios/piper/platform_value_darwin.h"

#import <Foundation/Foundation.h>

#include <vector>

#include "jsbridge/ios/piper/lynx_module_darwin.h"
#include "jsbridge/utils/utils.h"

namespace lynx {
namespace piper {
std::unique_ptr<PlatformValue> PlatformValue::FromPiperJsObject(const Object *piper_object,
                                                                std::weak_ptr<Runtime> rt) {
  return PlatformValueDarwin::FromPiperJsObject(piper_object, rt);
}

std::unique_ptr<PlatformValueDarwin> PlatformValueDarwin::FromPiperJsObject(
    const Object *piper_object, std::weak_ptr<Runtime> rt) {
  auto srt = rt.lock();
  if (!srt) {
    return nullptr;
  }

  std::unique_ptr<std::vector<piper::Object>> pre_object_vector =
      std::make_unique<std::vector<piper::Object>>();

  id value = convertJSIObjectToNSDictionary(*srt, *piper_object, *pre_object_vector);
  if (value == nil) {
    LOGE("[FromPiperJsObject] There is an error happened in convertJSIObjectToNSDictionary.");
  }
  return std::make_unique<PlatformValueDarwin>(std::move(value));
}
}  // namespace piper
}  // namespace lynx
