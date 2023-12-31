//
//  HMDOTManager.h
//  Pods
//
//  Created by fengyadong on 2019/12/12.
//

#import <Foundation/Foundation.h>
#import "HMDTracker.h"

@class HMDPerformanceReportRequest;
@class HMDOTSpan;
@class HMDOTTrace;
@class HMDOTConfig;

NS_ASSUME_NONNULL_BEGIN

@interface HMDOTManager : HeimdallrModule

@property (nonatomic, strong) HMDPerformanceReportRequest *reportingRequest;
@property (nonatomic, strong, readonly) dispatch_queue_t spanIOQueue;
@property (atomic, strong, readonly) HMDOTConfig *enternalConfig;/*确保单次生命周期内不变**/
@property (atomic, assign, readonly) BOOL hasStopped;/*模块是否停止接收数据，isRunning区分不出来初始状态还是停止的状态**/

+ (instancetype)sharedInstance;

- (void)insertTrace:(HMDOTTrace *)trace;
- (void)replaceTrace:(HMDOTTrace *)trace;

- (void)insertSpan:(HMDOTSpan *)span;
- (void)replaceSpan:(HMDOTSpan *)span;
- (void)insertCallbackSpans:(NSArray<HMDOTSpan *> *)spans forTrace:(HMDOTTrace *)trace;

//启动并且已经获取到采样率
- (BOOL)isValid;
// 清理某个 trace;
- (void)cleanupCachedTrace:(HMDOTTrace *)trace;

// debug模式上报日志，默认不上报
- (void)enableDebugUpload;

@end

NS_ASSUME_NONNULL_END
