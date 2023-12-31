// Copyright 2021 The Lynx Authors. All rights reserved.

#import <Lynx/LynxBasePerfMonitor.h>

@interface LynxPerfMonitorDarwin : NSObject <LynxBasePerfMonitor>

@property(nonatomic, readonly) CADisplayLink *uiDisplayLink;
@property(nonatomic, readonly) CADisplayLink *jsDisplayLink;

- (instancetype)initWithInspectorOwner:(id<LynxBaseInspectorOwner>)owner;

- (void)show;

- (void)hide;

@end
