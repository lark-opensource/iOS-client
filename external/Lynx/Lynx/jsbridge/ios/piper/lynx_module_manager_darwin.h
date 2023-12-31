// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_IOS_PIPER_LYNX_MODULE_MANAGER_DARWIN_H_
#define LYNX_JSBRIDGE_IOS_PIPER_LYNX_MODULE_MANAGER_DARWIN_H_

#import <Foundation/Foundation.h>
#import "LynxContext.h"
#import "LynxContextModule.h"
#import "LynxModule.h"

#include <memory>
#include <string>
#include <unordered_map>

#import "LynxThreadSafeDictionary.h"
#include "jsbridge/ios/piper/lynx_module_darwin.h"
#include "jsbridge/module/lynx_module_manager.h"

using LynxModuleDarwinPtr = std::shared_ptr<lynx::piper::LynxModuleDarwin>;

@interface LynxModuleWrapper : NSObject

@property(nonatomic, readwrite, strong) Class<LynxModule> moduleClass;
@property(nonatomic, readwrite, strong) id param;
@property(nonatomic, readwrite, weak) NSString *namescope;
@end

namespace lynx {
namespace runtime {
class LynxRuntime;
}  // namespace runtime

namespace piper {
class ModuleManagerDarwin : public LynxModuleManager {
 public:
  ModuleManagerDarwin();
  void registerModule(Class<LynxModule> cls);
  void registerModule(Class<LynxModule> cls, id param);
  void registerMethodAuth(LynxMethodBlock block);
  void registerExtraInfo(NSDictionary *extra);
  void registerMethodSession(LynxMethodSessionBlock block);
  NSMutableDictionary<NSString *, id> *moduleWrappers();
  NSMutableDictionary<NSString *, id> *extraWrappers();
  NSMutableArray<LynxMethodBlock> *methodAuthWrappers();
  NSMutableArray<LynxMethodSessionBlock> *methodSessionWrappers();
  void addWrappers(NSMutableDictionary<NSString *, id> *wrappers);
  std::shared_ptr<ModuleManagerDarwin> parent;
  LynxContext *context;
  virtual void Destroy() override;
  virtual void InitModuleInterceptor() override;

  void initBindingPtr(std::weak_ptr<ModuleManagerDarwin> weak_manager,
                      const std::shared_ptr<ModuleDelegate> &delegate);
  LynxThreadSafeDictionary<NSString *, id> *modulesClasses_;
  NSMutableDictionary<NSString *, id> *extra_;
  NSMutableArray<LynxMethodBlock> *methodAuthBlocks_;
  NSMutableArray<LynxMethodSessionBlock> *methodSessionBlocks_;

  LynxThreadSafeDictionary<NSString *, id> *getModuleClasses() { return modulesClasses_; }

 protected:
  LynxModuleProviderFunction BindingFunc(std::weak_ptr<ModuleManagerDarwin> weak_manager,
                                         const std::shared_ptr<ModuleDelegate> &delegate);

 private:
  LynxModuleDarwinPtr getModule(const std::string &name,
                                const std::shared_ptr<ModuleDelegate> &delegate);
  std::unordered_map<std::string, LynxModuleDarwinPtr> modules_;
};
}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_IOS_PIPER_LYNX_MODULE_MANAGER_DARWIN_H_
