// Copyright 2020 The Lynx Authors. All rights reserved.

#import "LynxDebugger.h"

#import <objc/message.h>

@implementation LynxDebugger

+ (Class<LynxDebuggerProtocol>)bridgeClass {
  return NSClassFromString(@"LynxDebugBridge");
}

+ (BOOL)enable:(NSURL *)schema withOptions:(NSDictionary *)options {
  if ([[LynxDebugger bridgeClass] respondsToSelector:@selector(singleton)]) {
    if ([[[LynxDebugger bridgeClass] singleton] respondsToSelector:@selector(enable:
                                                                        withOptions:)]) {
      return [[[LynxDebugger bridgeClass] singleton] enable:schema withOptions:options];
    }
  }
  return NO;
}

+ (void)setOpenCardCallback:(LynxOpenCardCallback)callback {
  [LynxDebugger addOpenCardCallback:callback];
}

+ (void)addOpenCardCallback:(LynxOpenCardCallback)callback {
  if ([[LynxDebugger bridgeClass] respondsToSelector:@selector(singleton)]) {
    if ([[[LynxDebugger bridgeClass] singleton]
            respondsToSelector:@selector(setOpenCardCallback:)]) {
      [[[LynxDebugger bridgeClass] singleton] setOpenCardCallback:callback];
    }
  }
}

+ (BOOL)hasSetOpenCardCallback {
  if ([[LynxDebugger bridgeClass] respondsToSelector:@selector(singleton)]) {
    if ([[[LynxDebugger bridgeClass] singleton]
            respondsToSelector:@selector(hasSetOpenCardCallback)]) {
      return [[[LynxDebugger bridgeClass] singleton] hasSetOpenCardCallback];
    }
  }
  return NO;
}

+ (void)onTracingComplete:(NSString *)traceFile {
  if ([[LynxDebugger bridgeClass] respondsToSelector:@selector(singleton)]) {
    if ([[[LynxDebugger bridgeClass] singleton] respondsToSelector:@selector(onTracingComplete:)]) {
      [[[LynxDebugger bridgeClass] singleton] onTracingComplete:traceFile];
    }
  }
}

+ (void)recordResource:(NSData *)data withKey:(NSString *)key {
  if ([[LynxDebugger bridgeClass] respondsToSelector:@selector(singleton)]) {
    if ([[[LynxDebugger bridgeClass] singleton] respondsToSelector:@selector(recordResource:
                                                                                    withKey:)]) {
      [[[LynxDebugger bridgeClass] singleton] recordResource:data withKey:key];
    }
  }
}

+ (BOOL)openDebugSettingPanel {
#if OS_OSX
  Class settingPanelClass = NSClassFromString(@"DebugSettingPanelManager");
  SEL sharedInstanceSel = NSSelectorFromString(@"sharedInstance");
  if (settingPanelClass && sharedInstanceSel &&
      [settingPanelClass respondsToSelector:sharedInstanceSel]) {
    id (*sharedInstance)(Class, SEL) = (id(*)(Class, SEL))objc_msgSend;
    BOOL (*openSettingPanel)(id, SEL) = (BOOL(*)(id, SEL))objc_msgSend;
    return openSettingPanel(sharedInstance(settingPanelClass, sharedInstanceSel),
                            NSSelectorFromString(@"openSettingPanel"));
  }
#endif
  return NO;
}

@end
