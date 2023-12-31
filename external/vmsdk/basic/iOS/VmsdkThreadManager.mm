//  Copyright 2020 The Vmsdk Authors. All rights reserved.
//  Created by wangheyang on 2020/6/13.

#import "basic/iOS/VmsdkThreadManager.h"

#include "monitor/common/vmsdk_monitor.h"

@implementation VmsdkThreadManager

+ (NSMutableDictionary*)queueDictionary {
  static NSMutableDictionary* dic = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dic = [NSMutableDictionary dictionary];
  });
  return dic;
}

+ (dispatch_queue_t)getCachedQueueWithPrefix:(NSString* _Nonnull)identifier {
  return [[self queueDictionary] valueForKey:identifier];
}

+ (dispatch_queue_t)getQueueWithPrefix:(NSString* _Nonnull)identifier {
  NSMutableDictionary* dic = [self queueDictionary];
  dispatch_queue_t queue = [dic valueForKey:identifier];
  if (queue != nil) {
    return queue;
  }
  NSString* fullName = [@"com.bytedance.vmsdk." stringByAppendingString:identifier];
  queue = dispatch_queue_create([fullName UTF8String], DISPATCH_QUEUE_CONCURRENT);
  dispatch_set_target_queue(queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
  [dic setObject:queue forKey:identifier];
  return queue;
}

+ (void)threadRun:(dispatch_block_t)runnable {
  @autoreleasepool {
    [self executeRunloop:runnable];
  }
}

+ (void)executeRunloop:(dispatch_block_t)runnable {
  runnable();
  // get runLoop of current thread and run
  NSRunLoop* currentRunLoop = [NSRunLoop currentRunLoop];
  // check status of thread and its corresponding runLoop
  if (currentRunLoop != nil) {
    [currentRunLoop run];
  }
}

+ (void)createIOSThread:(NSString*)name runnable:(dispatch_block_t)runnable {
  bool shouldCreateNewThread = GetSettingsWithKey("enable_ios_runloop_thread");
  if (shouldCreateNewThread) {
    NSThread* newThread = [[NSThread alloc] initWithTarget:self
                                                  selector:@selector(threadRun:)
                                                    object:runnable];
    if (newThread) {
      [newThread start];
    }
  } else {
    dispatch_async([self.class getQueueWithPrefix:name], ^{
      [self executeRunloop:runnable];
    });
  }
}

// judge whether current is run in main queue
+ (BOOL)isMainQueue {
  return dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) ==
         dispatch_queue_get_label(dispatch_get_main_queue());
}

+ (void)runBlockInMainQueue:(dispatch_block_t _Nonnull)runnable {
  dispatch_async(dispatch_get_main_queue(), runnable);
}

+ (void)runInTargetQueue:(dispatch_queue_t)queue runnable:(dispatch_block_t)runnable {
  dispatch_async(queue, runnable);
}

@end
