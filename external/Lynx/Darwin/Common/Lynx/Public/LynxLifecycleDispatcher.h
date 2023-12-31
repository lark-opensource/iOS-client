// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_LYNXLIFECYCLEDISPATCHER_H_
#define DARWIN_COMMON_LYNX_LYNXLIFECYCLEDISPATCHER_H_

#import <Foundation/Foundation.h>
#import "LynxViewClient.h"

NS_ASSUME_NONNULL_BEGIN

@class LynxView;

@interface LynxLifecycleDispatcher : NSObject <LynxViewLifecycle>

@property(nonatomic, readonly) NSArray<id<LynxViewLifecycle>>* lifecycleClients;

- (void)addLifecycleClient:(id<LynxViewLifecycle>)lifecycleClient;
- (void)removeLifecycleClient:(id<LynxViewLifecycle>)lifecycleClient;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_LYNXLIFECYCLEDISPATCHER_H_
