// Copyright 2021 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

#import "LynxBaseInspectorOwner.h"

@protocol LynxBasePerfMonitor <NSObject>

@required

- (void)show;

- (void)hide;

- (instancetype)initWithInspectorOwner:(id<LynxBaseInspectorOwner>)owner;

@end
