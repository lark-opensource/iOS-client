// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_MODULE_LYNX_MODULE_MANAGER_H_
#define LYNX_JSBRIDGE_MODULE_LYNX_MODULE_MANAGER_H_

#include <memory>
#include <string>
#include <unordered_set>
#include <utility>

#include "base/no_destructor.h"
#include "config/config.h"
#include "jsbridge/module/lynx_module_binding.h"
#include "jsbridge/module/module_delegate.h"

namespace lynx {
namespace piper {
// issue: #1510
// LynxModuleUtils::LynxModuleManagerAllowList
// inline static alternative
namespace LynxModuleUtils {
struct LynxModuleManagerAllowList {
  static const std::unordered_set<std::string>& get() {
    static base::NoDestructor<std::unordered_set<std::string>> storage_{
        {"BDLynxModule", "LynxTestModule", "NetworkingModule",
         "NavigationModule"}};
    return *storage_.get();
  }
};
}  // namespace LynxModuleUtils

using LynxModuleBindingPtr = std::shared_ptr<lynx::piper::LynxModuleBinding>;

class LynxModuleManager {
 public:
  LynxModuleBindingPtr bindingPtr;

  LynxModuleManager() = default;
  virtual ~LynxModuleManager() = default;
  void SetRecordID(int64_t record_id) { record_id_ = record_id; };
  int64_t record_id_ = 0;
  std::shared_ptr<ModuleDelegate> delegate;
  virtual void Destroy() = 0;
  virtual void InitModuleInterceptor(){};
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_MODULE_LYNX_MODULE_MANAGER_H_
