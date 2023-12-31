// Copyright 2019 The Vmsdk Authors. All rights reserved.

#ifndef JSBRIDGE_MODULE_VMSDK_MODULE_MANAGER_H
#define JSBRIDGE_MODULE_VMSDK_MODULE_MANAGER_H

#include <utility>

#include "basic/no_destructor.h"
#include "jsb/module/vmsdk_module_binding.h"

namespace vmsdk {
namespace piper {
// issue: #1510
// VmsdkModuleUtils::VmsdkModuleManagerAllowList
// inline static alternative
namespace VmsdkModuleUtils {
struct VmsdkModuleManagerAllowList {
  static const std::unordered_set<std::string> &get() {
    static basic::NoDestructor<std::unordered_set<std::string>> storage_{
        {"BDVmsdkModule", "VmsdkTestModule", "NetworkingModule",
         "NavigationModule"}};
    return *storage_.get();
  }
};
}  // namespace VmsdkModuleUtils

using VmsdkModuleBindingPtr = std::shared_ptr<vmsdk::piper::VmsdkModuleBinding>;

class VmsdkModuleManager {
 public:
  VmsdkModuleBindingPtr bindingPtr;

  VmsdkModuleManager() = default;
  virtual ~VmsdkModuleManager() = default;

  virtual void Destroy() = 0;
};

}  // namespace piper
}  // namespace vmsdk

#endif  // JSBRIDGE_MODULE_VMSDK_MODULE_MANAGER_H
