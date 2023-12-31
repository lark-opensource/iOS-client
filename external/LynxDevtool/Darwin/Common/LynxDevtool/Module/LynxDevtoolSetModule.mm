//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "LynxDevtoolSetModule.h"
#import "LynxDevtoolEnv.h"
#if OS_IOS
#import <Lynx/LynxBaseInspectorOwner.h>
#import <Lynx/LynxBaseInspectorOwnerNG.h>
#import <Lynx/LynxContext+Internal.h>
#import <Lynx/LynxEnv.h>
#import <Lynx/LynxEnvKey.h>
#elif OS_OSX
#import <LynxMacOS/LynxBaseInspectorOwner.h>
#import <LynxMacOS/LynxBaseInspectorOwnerNG.h>
#import <LynxMacOS/LynxContext+Internal.h>
#import <LynxMacOS/LynxEnv.h>
#import <LynxMacOS/LynxEnvKey.h>
#endif

@implementation LynxDevtoolSetModule {
  __weak LynxContext *context_;
}

+ (NSString *)name {
  return @"LynxDevtoolSetModule";
}

+ (NSDictionary<NSString *, NSString *> *)methodLookup {
  return @{
    @"isDevtoolEnabled" : NSStringFromSelector(@selector(isDevtoolEnabled)),
    @"switchDevtool" : NSStringFromSelector(@selector(switchDevtool:)),
    @"isRedBoxEnabled" : NSStringFromSelector(@selector(isRedBoxEnabled)),
    @"switchRedBox" : NSStringFromSelector(@selector(switchRedBox:)),
    @"switchRedBoxNext" : NSStringFromSelector(@selector(switchRedBoxNext:)),
    @"isRedBoxNextEnabled" : NSStringFromSelector(@selector(isRedBoxNextEnabled)),
    @"invokeCdp" : NSStringFromSelector(@selector(invokeCdp:message:callback:)),
    @"isV8Enabled" : NSStringFromSelector(@selector(isV8Enabled)),
    @"switchV8" : NSStringFromSelector(@selector(switchV8:)),
    @"enableDomTree" : NSStringFromSelector(@selector(enableDomTree:)),
    @"isDomTreeEnabled" : NSStringFromSelector(@selector(isDomTreeEnabled)),
    @"isIgnorePropErrorsEnabled" : NSStringFromSelector(@selector(isIgnorePropErrorsEnabled)),
    @"switchIgnorePropErrors" : NSStringFromSelector(@selector(switchIgnorePropErrors:)),
#if OS_IOS
    @"isQuickjsDebugEnabled" : NSStringFromSelector(@selector(isQuickjsDebugEnabled)),
    @"switchQuickjsDebug" : NSStringFromSelector(@selector(switchQuickjsDebug:)),
    @"isLongPressMenuEnabled" : NSStringFromSelector(@selector(isLongPressMenuEnabled)),
    @"switchLongPressMenu" : NSStringFromSelector(@selector(switchLongPressMenu:)),
    @"isPerfMonitorDebugEnabled" : NSStringFromSelector(@selector(isPerfMonitorDebugEnabled)),
    @"switchPerfMonitorDebug" : NSStringFromSelector(@selector(switchPerfMonitorDebug:)),
#endif
  };
}

- (instancetype)initWithLynxContext:(LynxContext *)context {
  self = [super init];
  if (self) {
    context_ = context;
  }
  return self;
}

- (BOOL)isDevtoolEnabled {
  return [LynxEnv.sharedInstance devtoolEnabled];
}

- (void)switchDevtool:(BOOL)arg {
  LynxEnv.sharedInstance.devtoolEnabled = arg;
}

- (BOOL)isRedBoxEnabled {
  return [LynxEnv.sharedInstance redBoxEnabled];
}

- (void)switchRedBox:(BOOL)arg {
  LynxEnv.sharedInstance.redBoxEnabled = arg;
}

- (BOOL)isRedBoxNextEnabled {
  return [LynxEnv.sharedInstance redBoxNextEnabled];
}

- (void)switchRedBoxNext:(BOOL)arg {
  [LynxEnv.sharedInstance setRedBoxNextEnabled:arg];
}

- (void)invokeCdp:(NSString *)type
          message:(NSString *)message
         callback:(LynxCallbackBlock)callback {
  if (context_ && context_.lynxView) {
    id<LynxBaseInspectorOwner> owner = context_.lynxView.baseInspectorOwner;
    if ([owner conformsToProtocol:@protocol(LynxBaseInspectorOwnerNG)]) {
      [(id<LynxBaseInspectorOwnerNG>)owner invokeCdp:type message:message callback:callback];
    }
  }
}

- (BOOL)isV8Enabled {
  return [LynxDevtoolEnv.sharedInstance v8Enabled];
}

- (void)switchV8:(BOOL)arg {
  [LynxDevtoolEnv.sharedInstance setV8Enabled:arg];
}

- (BOOL)isDomTreeEnabled {
  return [LynxDevtoolEnv.sharedInstance domTreeEnabled];
}

- (void)enableDomTree:(BOOL)arg {
  [LynxDevtoolEnv.sharedInstance setDomTreeEnabled:arg];
}

- (BOOL)isIgnorePropErrorsEnabled {
  return [LynxDevtoolEnv.sharedInstance get:SP_KEY_ENABLE_IGNORE_ERROR_CSS withDefaultValue:NO];
}

- (void)switchIgnorePropErrors:(BOOL)arg {
  [LynxDevtoolEnv.sharedInstance set:arg forKey:SP_KEY_ENABLE_IGNORE_ERROR_CSS];
}

#if OS_IOS
- (BOOL)isQuickjsDebugEnabled {
  return [LynxDevtoolEnv.sharedInstance quickjsDebugEnabled];
}

- (void)switchQuickjsDebug:(BOOL)arg {
  [LynxDevtoolEnv.sharedInstance setQuickjsDebugEnabled:arg];
}

- (BOOL)isLongPressMenuEnabled {
  return [LynxDevtoolEnv.sharedInstance longPressMenuEnabled];
}

- (void)switchLongPressMenu:(BOOL)arg {
  [LynxDevtoolEnv.sharedInstance setLongPressMenuEnabled:arg];
}

- (BOOL)isPerfMonitorDebugEnabled {
  return [LynxEnv.sharedInstance perfMonitorEnabled];
}

- (void)switchPerfMonitorDebug:(BOOL)arg {
  [LynxEnv.sharedInstance setPerfMonitorEnabled:arg];
}
#endif

@end
