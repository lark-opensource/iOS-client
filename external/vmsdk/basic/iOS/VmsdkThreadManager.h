//  Copyright 2020 The Vmsdk Authors. All rights reserved.
//
//  encapsulate thread operation with GCD
//
//  Created by wangheyang on 2020/6/13.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VmsdkThreadManager : NSObject

typedef void (^dispatch_block_t)(void);

+ (void)createIOSThread:(NSString*)name runnable:(dispatch_block_t)runnable;
+ (BOOL)isMainQueue;
+ (void)runBlockInMainQueue:(dispatch_block_t _Nonnull)runnable;
+ (void)runInTargetQueue:(dispatch_queue_t)queue runnable:(dispatch_block_t)runnable;
+ (dispatch_queue_t)getCachedQueueWithPrefix:(NSString* _Nonnull)identifier;
@end

NS_ASSUME_NONNULL_END
