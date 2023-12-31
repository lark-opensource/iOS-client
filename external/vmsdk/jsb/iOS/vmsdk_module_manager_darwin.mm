// Copyright 2019 The Vmsdk Authors. All rights reserved.

#include "vmsdk_module_manager_darwin.h"
#import <Foundation/Foundation.h>
#import "basic/log/iOS/VLog.h"

@interface VmsdkModuleWrapper : NSObject

@property(nonatomic, readwrite, strong) Class<JSModule> moduleClass;

@property(nonatomic, readwrite, strong) id param;
@end

@implementation VmsdkModuleWrapper
- (void)dealloc {
  _param = nil;
  NSLog(@"deleting VmsdkModuleWrapper ------");
}
@end

namespace vmsdk {
namespace piper {
ModuleManagerDarwin::ModuleManagerDarwin() : parent(nullptr) {
  modulesClasses_ = [[NSMutableDictionary alloc] init];
}

void ModuleManagerDarwin::initBindingPtr(std::weak_ptr<ModuleManagerDarwin> weak_manager,
                                         const std::shared_ptr<ModuleDelegate> &delegate) {
  bindingPtr = std::make_shared<vmsdk::piper::VmsdkModuleBinding>(
      [weak_manager, delegate](const std::string &name) {
        auto manager = weak_manager.lock();
        if (manager) {
          auto ptr = manager->getModule(name, delegate);
          if (ptr.get() != nullptr) {
            return ptr;
          }
        }
        // ptr == nullptr
        // issue: #1510
        if (!VmsdkModuleUtils::VmsdkModuleManagerAllowList::get().count(name)) {
          LOGW("VmsdkModule, try to find module: " << name << " failed. manager: " << std::hex
                                                   << manager << std::dec);
        } else {
          LOGV("VmsdkModule, module: " << name << " is not found but it is in the allow list");
        }
        return VmsdkModuleDarwinPtr(nullptr);
      });
}

VmsdkModuleDarwinPtr ModuleManagerDarwin::getModule(
    const std::string &name, const std::shared_ptr<ModuleDelegate> &delegate) {
  auto moduleLookup = modules_.find(name);
  if (moduleLookup != modules_.end()) {
    VmsdkModuleDarwinPtr ptr = moduleLookup->second;
    return ptr;
  }
  NSString *str = [NSString stringWithCString:name.c_str()
                                     encoding:[NSString defaultCStringEncoding]];
  VmsdkModuleWrapper *wrapper = modulesClasses_[str];
  if (wrapper == nil && parent) {
    wrapper = parent->moduleWrappers()[str];
  }
  Class<JSModule> aClass = wrapper.moduleClass;
  id param = wrapper.param;
  if (aClass != nil) {
    id<JSModule> instance = [(Class)aClass alloc];
    //    if ([instance conformsToProtocol:@protocol(VmsdkContextModule)]) {
    //      if (param != nil && [instance
    //      respondsToSelector:@selector(initWithVmsdkContext:WithParam:)]) {
    //        instance = [(id<VmsdkContextModule>)instance
    //        initWithVmsdkContext:context WithParam:param];
    //      } else {
    //        instance = [(id<VmsdkContextModule>)instance
    //        initWithVmsdkContext:context];
    //      }
    //    } else
    if (param != nil && [instance respondsToSelector:@selector(initWithParam:)]) {
      instance = [instance initWithParam:param];
    } else {
      instance = [instance init];
    }

    std::shared_ptr<vmsdk::piper::VmsdkModuleDarwin> moduleDarwin =
        std::make_shared<vmsdk::piper::VmsdkModuleDarwin>(instance, delegate);

    modules_[name] = moduleDarwin;
    {
      //      auto conformsToVmsdkContextModule = [instance
      //      conformsToProtocol:@protocol(VmsdkContextModule)];
      auto conformsToVmsdkModule = [instance conformsToProtocol:@protocol(JSModule)];
      LOGV(
          "VmsdkModule, module: "
          << name << "(conforming to VmsdkModule?: " << std::boolalpha
          << conformsToVmsdkModule
          //           												<<
          //           ", conforming to VmsdkContextModule?: "
          //                                  << conformsToVmsdkContextModule
          << ", with param(address): " << std::hex << reinterpret_cast<std::uintptr_t>(param)
          << std::dec << ")"
          << ", is created in getModule()");
    }
    return moduleDarwin;
  }
  return VmsdkModuleDarwinPtr(nullptr);
}

void ModuleManagerDarwin::registerModule(Class<JSModule> cls) { registerModule(cls, nil); }

void ModuleManagerDarwin::registerModule(Class<JSModule> cls, id param) {
  VmsdkModuleWrapper *wrapper = [[VmsdkModuleWrapper alloc] init];
  wrapper.moduleClass = cls;
  wrapper.param = param;
  modulesClasses_[[cls name]] = wrapper;
  VLogInfo(@"VmsdkModule, module: %@ registered with param (address): %p", cls, param);
}

#if ENABLE_ARK_RECORDER
void ModuleManagerDarwin::Record(int64_t vmsdk_view_id) {
  [modulesClasses_
      enumerateKeysAndObjectsUsingBlock:^(NSString *key, VmsdkModuleWrapper *value, BOOL *stop) {
        NSDictionary *methodLookup = [value.moduleClass methodLookup];
        [methodLookup enumerateKeysAndObjectsUsingBlock:^(NSString *k, NSString *v, BOOL *stop) {
          vmsdk::tasm::recorder::VmsdkViewInitRecorder::GetInstance().RecordMethodLookup(
              [k UTF8String], [v UTF8String]);
        }];
        NSString *param_value;
        id param = value.param;
        if ([param isKindOfClass:[NSString class]]) {
          param_value = (NSString *)param;
        } else if ([param isKindOfClass:[NSDictionary class]]) {
          NSError *err;
          NSData *json_data = [NSJSONSerialization dataWithJSONObject:param options:0 error:&err];
          if (!err) {
            param_value = [[NSString alloc] initWithData:json_data encoding:NSUTF8StringEncoding];
          }
        }
        vmsdk::tasm::recorder::VmsdkViewInitRecorder::GetInstance().RecordRegisteredModule(
            [key UTF8String], vmsdk_view_id, [param_value UTF8String]);
      }];
}
#endif

NSMutableDictionary<NSString *, id> *ModuleManagerDarwin::moduleWrappers() {
  return modulesClasses_;
}

void ModuleManagerDarwin::addWrappers(NSMutableDictionary<NSString *, id> *wrappers) {
  [modulesClasses_ addEntriesFromDictionary:wrappers];
}

void ModuleManagerDarwin::Destroy() {}

}
}
