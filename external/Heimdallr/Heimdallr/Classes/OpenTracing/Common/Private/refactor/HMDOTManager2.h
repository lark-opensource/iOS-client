//
//  HMDOTManager2.h
//  Heimdallr-8bda3036
//
//  Created by liuhan on 2022/4/18.
//

#import <Foundation/Foundation.h>
#import "HMDTracker.h"
#import "HeimdallrModule.h"

@class HMDOTSpan;
@class HMDOTTrace;
@class HMDOTConfig;

NS_ASSUME_NONNULL_BEGIN

@interface HMDOTManager2 : HeimdallrModule

@property (nonatomic, strong, readonly) dispatch_queue_t spanIOQueue;
@property (atomic, strong, readonly) HMDOTConfig *enternalConfig;/*确保单次生命周期内不变**/
@property (atomic, assign, readonly) BOOL hasStopped;/*模块是否停止接收数据，isRunning区分不出来初始状态还是停止的状态**/

+ (instancetype)sharedInstance;

- (void)startTrace:(HMDOTTrace *)trace;
- (void)finishTrace:(HMDOTTrace *)trace;
- (void)startSpan:(HMDOTSpan *)span;
- (void)finishSpan:(HMDOTSpan *)span;

//启动并且已经获取到采样率
- (BOOL)isValid;
// 清理某个 trace;
- (void)cleanupTrace:(HMDOTTrace *)trace;

// debug模式上报日志，默认不上报
- (void)enableDebugUpload;

- (void)uploadCache;

@end

NS_ASSUME_NONNULL_END
