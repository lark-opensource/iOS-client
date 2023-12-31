//
//  BDMonitorThreadManager.h
//  IESWebViewMonitor
//
//  Created by bytedance on 2020/7/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDMonitorThreadManager : NSObject

// handle events on mainthread
+ (void)dispatchAsyncHandlerForceOnMainThread:(void(^)(void))handler;
+ (void)dispatchSyncHandlerForceOnMainThread:(void(^)(void))handler;
// handle events on mainthread force on next runloop
+ (void)dispatchForceAsyncOnMainThread:(void (^)(void))handler;

// handle events on monitor thread
+ (void)dispatchAsyncHandlerForceOnMonitorThread:(void (^)(void))handler;
+ (BOOL)isMonitorThread;

@end

NS_ASSUME_NONNULL_END
