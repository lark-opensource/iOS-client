// Copyright 2021 The Lynx Authors. All rights reserved.

#import <UIKit/UIKit.h>
#import "LynxInspectorOwner+Internal.h"

@interface DevtoolLepusManagerDarwin : NSObject

- (instancetype)initWithInspectorOwner:(LynxInspectorOwner*)owner;

- (void)ResponseFromJSEngine:(std::string)response;

- (void)DispatchMessageToJSEngine:(std::string)message;

- (void)StopDebug;

- (void)DestroyDebug;

- (void)DispatchDebuggerDisableMessage;

+ (void)SetDebugActive:(bool)active;

- (intptr_t)getJavascriptDebugger:(NSString*)url;

@end
