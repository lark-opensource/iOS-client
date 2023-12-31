// Copyright 2022 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

@interface LynxInstanceTrace : NSObject
+ (instancetype)shareInstance;
- (intptr_t)getInstanceTracePlugin;
@end
