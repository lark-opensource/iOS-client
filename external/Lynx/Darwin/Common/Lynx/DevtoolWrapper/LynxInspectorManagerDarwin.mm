// Copyright 2019 The Lynx Authors. All rights reserved.
#import "LynxInspectorManagerDarwin.h"
#if INSPECTOR_TEST
#import "LynxEnv.h"
#import "LynxTemplateRender+Internal.h"
#import "LynxTouchEvent.h"
#import "LynxView+Internal.h"

#import <objc/runtime.h>
#include <memory>
#include <string>
#include "base/closure.h"
#include "inspector/inspector_manager.h"
#include "jsbridge/bindings/console_message_postman.h"

#pragma mark - InspectorManagerImpl
namespace lynx {
namespace devtool {
class InspectorManagerImpl : public InspectorManager {
 public:
  InspectorManagerImpl(LynxInspectorManagerDarwin* darwin) { _darwin = darwin; }
  ~InspectorManagerImpl() override = default;
  virtual void Call(const std::string& function, const std::string& params) override {
    __strong typeof(_darwin) darwin = _darwin;
    [darwin call:[NSString stringWithUTF8String:function.c_str()]
        withParam:[NSString stringWithUTF8String:params.c_str()]];
  }
  virtual void SendConsoleMessage(const piper::ConsoleMessage& message) override {
    __strong typeof(_darwin) darwin = _darwin;
    NSString* text = [NSString stringWithUTF8String:message.text_.c_str()];
    if (text == nil) {
      text = @"Console message has invalid characters, please check!";
      LOGE("devtool post console message error: " << message.text_);
    }
    [darwin SendConsoleMessage:text withLevel:message.level_ withTimStamp:message.timestamp_];
  }
  virtual intptr_t getJavascriptDebugger() override {
    __strong typeof(_darwin) darwin = _darwin;
    return [darwin getJavascriptDebugger];
  }

  virtual intptr_t getLepusDebugger(const std::string& url) override {
    __strong typeof(_darwin) darwin = _darwin;
    NSString* str = [NSString stringWithCString:url.c_str()
                                       encoding:[NSString defaultCStringEncoding]];
    return [darwin getLepusDebugger:str];
  }

  virtual intptr_t createInspectorRuntimeManager() override {
    __strong typeof(_darwin) darwin = _darwin;
    return [darwin createInspectorRuntimeManager];
  }

  virtual intptr_t GetLynxDevtoolFunction() override {
    __strong typeof(_darwin) darwin = _darwin;
    return [darwin GetLynxDevtoolFunction];
  }

 private:
  inline bool ManagerDarwinIsNull() { return _darwin == nil; }
  __weak LynxInspectorManagerDarwin* _darwin;
};
}  // namespace devtool
}  // namespace lynx

#pragma mark - LynxInspectorManagerDarwin
@implementation LynxInspectorManagerDarwin {
  int connection_id_;
  __weak id<LynxBaseInspectorOwner> _owner;
  std::shared_ptr<lynx::devtool::InspectorManager> inspector_manager_;
}

- (nonnull instancetype)initWithOwner:(id<LynxBaseInspectorOwner>)owner {
  self = [super init];
  if (self) {
    _owner = owner;
    inspector_manager_ = std::make_shared<lynx::devtool::InspectorManagerImpl>(self);
  }
  return self;
}

- (void)onTemplateAssemblerCreated:(intptr_t)ptr {
  if (inspector_manager_) {
    inspector_manager_->OnTasmCreated(ptr);
  }
}

- (void)call:(NSString*)function withParam:(NSString*)params {
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    [owner call:function withParam:params];
  }
}

- (intptr_t)GetLynxDevtoolFunction {
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    return [owner GetLynxDevtoolFunction];
  }
  return 0;
}

- (intptr_t)GetFirstPerfContainer {
  if (inspector_manager_) {
    return inspector_manager_->GetFirstPerfContainer();
  }
  return 0;
}

- (void)setLynxEnvKey:(NSString*)key withValue:(bool)value {
  if (inspector_manager_) {
    inspector_manager_->SetLynxEnv([key UTF8String], value);
  }
}

- (void)SendConsoleMessage:(NSString*)message
                 withLevel:(int32_t)level
              withTimStamp:(int64_t)timeStamp {
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    [owner dispatchConsoleMessage:message withLevel:level withTimStamp:timeStamp];
  }
}

- (const std::shared_ptr<lynx::devtool::InspectorManager>&)getNativePtr {
  return inspector_manager_;
}

- (intptr_t)getJavascriptDebugger {
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    return [owner getJavascriptDebugger];
  } else {
    return 0;
  }
}

- (intptr_t)getLepusDebugger:(NSString*)url {
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    return [owner getLepusDebugger:url];
  } else {
    return 0;
  }
}

- (intptr_t)createInspectorRuntimeManager {
  if (!LynxEnv.sharedInstance.lynxDebugEnabled || !LynxEnv.sharedInstance.devtoolEnabled ||
      [LynxEnv.sharedInstance getDevtoolEnv:@"disableInspectorV8Runtime" withDefaultValue:NO]) {
    return 0;
  }
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    return [owner createInspectorRuntimeManager];
  } else {
    return 0;
  }
}

- (void)HotModuleReplaceWithHmrData:(const std::vector<HmrData>&)component_datas
                            message:(const std::string&)message {
  if (inspector_manager_ != nil) {
    inspector_manager_->HotModuleReplaceWithHmrData(component_datas, message);
  }
}

- (void)RunOnJSThread:(intptr_t)closure {
#if OS_IOS
  if (inspector_manager_) {
    inspector_manager_->RunOnJSThread(std::move(*reinterpret_cast<lynx::base::closure*>(closure)));
  }
#endif
}

- (intptr_t)getTemplateApiDefaultProcessor {
#if OS_IOS
  if (inspector_manager_) {
    return inspector_manager_->GetDefaultProcessor();
  }
#endif
  return 0;
}

- (intptr_t)getTemplateApiProcessorMap {
#if OS_IOS
  if (inspector_manager_) {
    return inspector_manager_->GetProcessorMap();
  }
#endif
  return 0;
}

- (void)sendTouchEvent:(nonnull NSString*)type
                  sign:(int)sign
                     x:(int)x
                     y:(int)y
            onLynxView:(LynxView*)lynxview {
#if OS_IOS
  CGPoint clientPoint = CGPointMake(x, y);
  LynxTouchEvent* event = [[LynxTouchEvent alloc] initWithName:type
                                                     targetTag:sign
                                                   clientPoint:clientPoint
                                                     pagePoint:clientPoint
                                                     viewPoint:clientPoint];
  [lynxview.templateRender sendSyncTouchEvent:event];
#endif
}

@end
#endif
