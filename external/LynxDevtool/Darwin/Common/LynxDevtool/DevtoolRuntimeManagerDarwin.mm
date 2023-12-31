// Copyright 2020 The Lynx Authors. All rights reserved.
#import "DevtoolRuntimeManagerDarwin.h"
#import "LynxDevtoolEnv.h"

#if TARGET_OS_IOS
#if __has_include(<Lynx/LynxEnvKey.h>)
#import <Lynx/LynxEnvKey.h>
#endif
#else
#if __has_include(<LynxMacOS/LynxEnvKey.h>)
#import <LynxMacOS/LynxEnvKey.h>
#endif
#endif

#include "jsbridge/js_debug/inspector_java_script_debugger.h"
#include "jsbridge/js_debug/inspector_runtime_manager.h"

namespace lynx {
namespace devtool {
class InspectorJavaScriptDebuggerImpl : public lynx::devtool::InspectorJavaScriptDebugger {
 public:
  InspectorJavaScriptDebuggerImpl(DevtoolRuntimeManagerDarwin* runtime)
      : InspectorJavaScriptDebugger([[LynxDevtoolEnv sharedInstance] v8Enabled] ? v8_debug
                                                                                : quickjs_debug) {
    _runtime = runtime;
  }
  virtual bool ResponseFromJSEngine(const std::string& message) override {
    __strong typeof(_runtime) runtime = _runtime;
    if (runtime) {
      return [runtime ResponseFromJSEngine:message];
    }
    return false;
  }

 private:
  __weak DevtoolRuntimeManagerDarwin* _runtime;
};
}  // namespace devtool
}  // namespace lynx

#pragma mark - DevtoolRuntimeManagerDarwin
@implementation DevtoolRuntimeManagerDarwin {
  __weak LynxInspectorOwner* _owner;
  std::shared_ptr<lynx::devtool::InspectorJavaScriptDebuggerImpl> debugger_;
  NSString* _groupName;
}
static bool _debug_active = true;

- (instancetype)initWithInspectorOwner:(LynxInspectorOwner*)owner {
  self = [super init];
  if (self) {
    _owner = owner;
#if !(defined(OS_IOS) && (defined(__i386__) || defined(__arm__)))
    debugger_ = std::make_shared<lynx::devtool::InspectorJavaScriptDebuggerImpl>(self);
#endif
  }
  return self;
}

- (intptr_t)getJavascriptDebugger {
  if (debugger_ != nullptr) {
    auto sp = std::dynamic_pointer_cast<lynx::piper::JavaScriptDebugger>(debugger_);
    return reinterpret_cast<intptr_t>(new lynx::piper::JavaScriptDebuggerWrapper(sp));
  } else {
    return 0;
  }
}

- (intptr_t)createInspectorRuntimeManager {
#if !(defined(OS_IOS) && (defined(__i386__) || defined(__arm__)))
  lynx::runtime::InspectorRuntimeManager* manager = new lynx::runtime::InspectorRuntimeManager();
  return reinterpret_cast<intptr_t>(manager);
#else
  return 0;
#endif
}

- (bool)ResponseFromJSEngine:(std::string)response {
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    [owner sendResponse:response];
    return true;
  } else {
    return false;
  }
}

- (void)DispatchMessageToJSEngine:(std::string)message {
  if (debugger_) {
    debugger_->DispatchMessageToJSEngine(message);
  }
}

- (void)StopDebug {
  if (debugger_) {
    debugger_->StopDebug();
  }
}

- (void)DestroyDebug {
  if (debugger_) {
    debugger_->StopDebug();
    debugger_->OnDestroy();
  }
}

- (void)DispatchDebuggerDisableMessage {
  if (debugger_) {
    debugger_->DispatchDebuggerDisableMessage();
  }
}

- (void)setSharedVM:(LynxGroup*)group {
  if (debugger_) {
    _groupName = group ? [group groupName] : [LynxGroup singleGroupTag];
    debugger_->SetSharedVM([_groupName UTF8String]);
  }
}

- (NSString*)groupName {
  return _groupName ? _groupName : [LynxGroup singleGroupTag];
}

- (void)setInspectorManager:(const std::shared_ptr<lynx::devtool::InspectorManager>&)manager {
  if (debugger_ && manager) {
    debugger_->SetInspectorManager(manager);
  }
}

- (void)setViewDestroyed:(bool)destroyed {
  if (debugger_) {
    debugger_->SetViewDestroyed(destroyed);
  }
}

- (void)setEnableNeeded:(BOOL)enable {
  if (debugger_) {
    [[LynxDevtoolEnv sharedInstance] set:enable forKey:SP_KEY_DEVTOOL_CONNECTED];
    debugger_->SetEnableNeeded(enable);
  }
}

+ (void)setDebugActive:(BOOL)active {
  _debug_active = active;
}

@end
