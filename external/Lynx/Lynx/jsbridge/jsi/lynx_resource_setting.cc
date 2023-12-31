// Copyright 2019 The Lynx Authors. All rights reserved.

#include "jsbridge/jsi/lynx_resource_setting.h"

namespace lynx {
namespace piper {

std::shared_ptr<LynxResourceSetting> LynxResourceSetting::getInstance() {
  static std::shared_ptr<LynxResourceSetting> instance =
      std::make_shared<LynxResourceSetting>();
  return instance;
}

}  // namespace piper
}  // namespace lynx
