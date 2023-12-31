//
//  AWECloudBackgroundTaskUtility.h
//  Heimdallr
//
//  Created by sunrunwang on 2019/4/22.
//
// 本来是想搞个全能复杂的
// 但这个具有许多默认设置的 更适合目前的状态
// 你想 以前 NS 框架里还有 NSSimpleTypeSetter

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^AWESimpleBackgroundTaskBlock)(void(^completeHandle)(void));

@interface AWECloudBackgroundTaskUtility : NSObject

+ (void)detachBackgroundTaskWithName:(NSString *)name
                                task:(AWESimpleBackgroundTaskBlock)task;

// ExpireTime 依赖于 NSTimer 意味着你的代码不能在主线程进行 backgroundTask
// 任何 dispatch_async detachNewThread 都可以 记得最后调用 completeHandle 就行
+ (void)detachBackgroundTaskWithName:(NSString *)name
                          expireTime:(NSTimeInterval)expireTime
                                task:(AWESimpleBackgroundTaskBlock)task;

#pragma mark - Additional method

/// 当不好直接调用 completeHandle 的时候可以使用这个方法传递相同字符串
+ (void)endBackgroundTaskWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
