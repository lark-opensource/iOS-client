// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_JSI_LYNX_RESOURCE_SETTING_H_
#define LYNX_JSBRIDGE_JSI_LYNX_RESOURCE_SETTING_H_

#include <memory>

namespace lynx {
namespace piper {

class LynxResourceSetting {
 public:
  static std::shared_ptr<LynxResourceSetting> getInstance();

 public:
  bool is_debug_resource_ = false;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_JSI_LYNX_RESOURCE_SETTING_H_
