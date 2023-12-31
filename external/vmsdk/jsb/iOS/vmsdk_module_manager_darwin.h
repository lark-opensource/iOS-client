// Copyright 2019 The Vmsdk Authors. All rights reserved.

#pragma once

#import <Foundation/Foundation.h>
#import "jsb/iOS/framework/JSModule.h"

#include "jsb/iOS/vmsdk_module_darwin.h"
#include "jsb/module/vmsdk_module_manager.h"

using VmsdkModuleDarwinPtr = std::shared_ptr<vmsdk::piper::VmsdkModuleDarwin>;

namespace vmsdk {
namespace runtime {
class VmsdkRuntime;
}  // namespace runtime

namespace piper {
class ModuleManagerDarwin : public VmsdkModuleManager {
 public:
  ModuleManagerDarwin();
  virtual ~ModuleManagerDarwin() = default;
  void registerModule(Class<JSModule> cls);
  void registerModule(Class<JSModule> cls, id param);
  NSMutableDictionary<NSString *, id> *moduleWrappers();
  void addWrappers(NSMutableDictionary<NSString *, id> *wrappers);
  std::shared_ptr<ModuleManagerDarwin> parent;
  //  __weak VmsdkContext *context;
  virtual void Destroy() override;
  void initBindingPtr(std::weak_ptr<ModuleManagerDarwin> weak_manager,
                      const std::shared_ptr<ModuleDelegate> &delegate);
#if ENABLE_ARK_RECORDER
  void SetVmsdkViewID(int64_t vmsdk_view_id) { vmsdk_view_id_ = vmsdk_view_id; }
  void Record(int64_t vmsdk_view_id);
#endif

 private:
  VmsdkModuleDarwinPtr getModule(const std::string &name,
                                 const std::shared_ptr<ModuleDelegate> &delegate);
  std::unordered_map<std::string, VmsdkModuleDarwinPtr> modules_;
  NSMutableDictionary<NSString *, id> *modulesClasses_;
#if ENABLE_ARK_RECORDER
  int64_t vmsdk_view_id_;
#endif
};
}
}
