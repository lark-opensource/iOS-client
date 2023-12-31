// Copyright 2020 The Lynx Authors. All rights reserved.

#import "LynxInspectorOwner.h"

@class LynxDevMenuItem;

@interface LynxDevMenu : NSObject

- (instancetype)initWithInspectorOwner:(LynxInspectorOwner*)owner;
- (BOOL)isActionSheetShown;
- (void)show;
- (void)reload;
- (void)setShowConsoleBlock:(LynxDevMenuShowConsoleBlock)block;

@end

@interface LynxDevMenuItem : NSObject

+ (instancetype)buttonItemWithTitle:(NSString*)title handler:(dispatch_block_t)handler;

@end
