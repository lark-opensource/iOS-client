//  Copyright 2020 The Lynx Authors. All rights reserved.
//
//  encapsulate thread operation with GCD
//
//  Created by wangheyang on 2020/6/13.

#ifndef DARWIN_COMMON_LYNX_BASE_LYNXTHREADMANAGER_H_
#define DARWIN_COMMON_LYNX_BASE_LYNXTHREADMANAGER_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxThreadManager : NSObject

typedef void (^dispatch_block_t)(void);

+ (void)createIOSThread:(NSString*)name runnable:(dispatch_block_t)runnable;
+ (BOOL)isMainQueue;
+ (void)runBlockInMainQueue:(dispatch_block_t _Nonnull)runnable;
+ (void)runInTargetQueue:(dispatch_queue_t)queue runnable:(dispatch_block_t)runnable;
+ (dispatch_queue_t)getCachedQueueWithPrefix:(NSString* _Nonnull)identifier;
@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_BASE_LYNXTHREADMANAGER_H_
