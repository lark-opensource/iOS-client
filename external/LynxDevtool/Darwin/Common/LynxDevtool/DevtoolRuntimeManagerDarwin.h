// Copyright 2020 The Lynx Authors. All rights reserved.
#import "LynxInspectorOwner+Internal.h"
#include "inspector/inspector_manager.h"

@interface DevtoolRuntimeManagerDarwin : NSObject

- (instancetype)initWithInspectorOwner:(LynxInspectorOwner*)owner;

- (intptr_t)createInspectorRuntimeManager;

- (bool)ResponseFromJSEngine:(std::string)response;

- (void)DispatchMessageToJSEngine:(std::string)message;

- (void)StopDebug;

- (void)DestroyDebug;

- (void)DispatchDebuggerDisableMessage;

- (intptr_t)getJavascriptDebugger;

- (void)setSharedVM:(LynxGroup*)group;

- (NSString*)groupName;

- (void)setInspectorManager:(const std::shared_ptr<lynx::devtool::InspectorManager>&)manager;

- (void)setViewDestroyed:(bool)destroyed;

- (void)setEnableNeeded:(BOOL)enable;

+ (void)setDebugActive:(BOOL)active;

@end
