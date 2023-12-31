// Copyright 2019 The Lynx Authors. All rights reserved.

#include "lynx_module_manager_darwin.h"
#import "LynxLog.h"

#include <string>
#include <unordered_map>

#include "base/string/string_utils.h"
#include "config/config.h"
#if __ENABLE_LYNX_NET__
#include "jsbridge/network/request_interceptor_darwin.h"
#endif

@implementation LynxModuleWrapper

@end

namespace lynx {
namespace piper {
ModuleManagerDarwin::ModuleManagerDarwin() : parent(nullptr), context(nil) {
  modulesClasses_ = [[LynxThreadSafeDictionary alloc] init];
  extra_ = [NSMutableDictionary dictionary];
  methodAuthBlocks_ = [[NSMutableArray alloc] init];
  methodSessionBlocks_ = [[NSMutableArray alloc] init];
}

void ModuleManagerDarwin::initBindingPtr(std::weak_ptr<ModuleManagerDarwin> weak_manager,
                                         const std::shared_ptr<ModuleDelegate> &delegate) {
  bindingPtr =
      std::make_shared<lynx::piper::LynxModuleBinding>(BindingFunc(weak_manager, delegate));
#if ENABLE_ARK_REPLAY
  this->delegate = delegate;
#endif
}

LynxModuleProviderFunction ModuleManagerDarwin::BindingFunc(
    std::weak_ptr<ModuleManagerDarwin> weak_manager,
    const std::shared_ptr<ModuleDelegate> &delegate) {
  return [weak_manager, delegate](const std::string &name) {
    auto manager = weak_manager.lock();
    if (manager) {
      auto ptr = manager->getModule(name, delegate);
      if (ptr.get() != nullptr) {
        return ptr;
      }
    }
    // ptr == nullptr
    // issue: #1510
    if (!LynxModuleUtils::LynxModuleManagerAllowList::get().count(name)) {
      LOGW("LynxModule, try to find module: " << name << "failed. manager: " << std::hex << manager
                                              << std::dec);
    } else {
      LOGV("LynxModule, module: " << name << " is not found but it is in the allow list");
    }
    return LynxModuleDarwinPtr(nullptr);
  };
}

LynxModuleDarwinPtr ModuleManagerDarwin::getModule(
    const std::string &name, const std::shared_ptr<ModuleDelegate> &delegate) {
  auto moduleLookup = modules_.find(name);
  if (moduleLookup != modules_.end()) {
    LynxModuleDarwinPtr ptr = moduleLookup->second;
    return ptr;
  }
  NSString *str = [NSString stringWithCString:name.c_str()
                                     encoding:[NSString defaultCStringEncoding]];
  LynxModuleWrapper *wrapper = modulesClasses_[str];
  if (wrapper == nil && parent) {
    wrapper = parent->moduleWrappers()[str];
  }
  Class<LynxModule> aClass = wrapper.moduleClass;
  id param = wrapper.param;
  if (aClass != nil) {
    id<LynxModule> instance = [(Class)aClass alloc];
    if ([instance conformsToProtocol:@protocol(LynxContextModule)]) {
      if (param != nil && [instance respondsToSelector:@selector(initWithLynxContext:WithParam:)]) {
        instance = [(id<LynxContextModule>)instance initWithLynxContext:context WithParam:param];
      } else {
        instance = [(id<LynxContextModule>)instance initWithLynxContext:context];
      }
    } else if (param != nil && [instance respondsToSelector:@selector(initWithParam:)]) {
      instance = [instance initWithParam:param];
    } else {
      instance = [instance init];
    }
    std::shared_ptr<lynx::piper::LynxModuleDarwin> moduleDarwin =
        std::make_shared<lynx::piper::LynxModuleDarwin>(instance, delegate);
#if ENABLE_ARK_RECORDER
    moduleDarwin->SetRecordID(record_id_);
#endif
    modules_[name] = moduleDarwin;
    moduleDarwin->SetMethodAuth(methodAuthBlocks_);
    moduleDarwin->SetMethodSession(methodSessionBlocks_);
    NSString *url = [context getLynxView].url;
    if (context && url) {
      moduleDarwin->SetSchema(base::SafeStringConvert([url UTF8String]));
    }
    if (wrapper.namescope) {
      moduleDarwin->SetMethodScope(wrapper.namescope);
    }
    {
      auto conformsToLynxContextModule = [instance conformsToProtocol:@protocol(LynxContextModule)];
      auto conformsToLynxModule = [instance conformsToProtocol:@protocol(LynxModule)];
      LOGV("LynxModule, module: " << name << "(conforming to LynxModule?: " << std::boolalpha
                                  << conformsToLynxModule << ", conforming to LynxContextModule?: "
                                  << conformsToLynxContextModule
                                  << ", with param(address): " << std::hex
                                  << reinterpret_cast<std::uintptr_t>(param) << std::dec << ")"
                                  << ", is created in getModule()");
    }
    return moduleDarwin;
  }
  return LynxModuleDarwinPtr(nullptr);
}

void ModuleManagerDarwin::registerModule(Class<LynxModule> cls) { registerModule(cls, nil); }

void ModuleManagerDarwin::registerModule(Class<LynxModule> cls, id param) {
  LynxModuleWrapper *wrapper = [[LynxModuleWrapper alloc] init];
  wrapper.moduleClass = cls;
  wrapper.param = param;
  if (param && [param isKindOfClass:[NSDictionary class]] &&
      [((NSDictionary *)param) objectForKey:@"namescope"]) {
    wrapper.namescope = [((NSDictionary *)param) objectForKey:@"namescope"];
  }
  modulesClasses_[[cls name]] = wrapper;
  LLogInfo(@"LynxModule, module: %@ registered with param (address): %p", cls, param);
}

void ModuleManagerDarwin::registerMethodAuth(LynxMethodBlock block) {
  [methodAuthBlocks_ addObject:block];
}

void ModuleManagerDarwin::registerMethodSession(LynxMethodSessionBlock block) {
  [methodSessionBlocks_ addObject:block];
}

void ModuleManagerDarwin::registerExtraInfo(NSDictionary *extra) {
  [extra_ addEntriesFromDictionary:extra];
}

NSMutableDictionary<NSString *, id> *ModuleManagerDarwin::moduleWrappers() {
  return modulesClasses_;
}

NSMutableArray<LynxMethodBlock> *ModuleManagerDarwin::methodAuthWrappers() {
  return methodAuthBlocks_;
}

NSMutableArray<LynxMethodSessionBlock> *ModuleManagerDarwin::methodSessionWrappers() {
  return methodSessionBlocks_;
}

NSMutableDictionary<NSString *, id> *ModuleManagerDarwin::extraWrappers() { return extra_; }

void ModuleManagerDarwin::addWrappers(NSMutableDictionary<NSString *, id> *wrappers) {
  [modulesClasses_ addEntriesFromDictionary:wrappers];
}

void ModuleManagerDarwin::Destroy() {
#if !defined(OS_OSX)
  LOGI("lynx module_manager_darwin destroy: " << reinterpret_cast<std::uintptr_t>(this));
  for (const auto &module : modules_) {
    module.second->Destroy();
  }
#endif  // !defined(OS_OSX)
}

void ModuleManagerDarwin::InitModuleInterceptor() {
#if __ENABLE_LYNX_NET__
  auto network_module = network::CreateNetworkModule(bindingPtr.get());
  if (network_module == nullptr) {
    LOGE("Cannot create NetworkModule, So we don't add request_interceptor.");
    return;
  }
  LOGI("Start Add RequestInterceptor");
  auto interceptors = std::make_shared<GroupInterceptor>();
  auto request_interceptor = std::make_shared<network::RequestInterceptorDarwin>();
  request_interceptor->network_module_ = network_module;
  interceptors->AddInterceptor(request_interceptor);
  bindingPtr->interceptor_ = interceptors;
#endif
}

}  // namespace piper
}  // namespace lynx
