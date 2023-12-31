
/*!@header HMDCrashLoadReport+Private.h
   @author somebody
   @abstract crash load launch report object
 */

#import "HMDCrashLoadReport.h"

@interface HMDCrashLoadReport (Private)

/// 是否上次启动发生崩溃
@property(nonatomic, readwrite, getter=isLastTimeCrash) BOOL lastTimeCrash;

/// 如果上次启动发生崩溃，是否是 Load 阶段崩溃
@property(nonatomic, readwrite, getter=isLastTimeLoadCrash) BOOL lastTimeLoadCrash;

/// 整体模块启动耗时
@property(nonatomic, readwrite) NSTimeInterval launchDuration;

/// CrashTracker 无法处理而转为 Load 上报的数量
/// 这些崩溃因为在正常上报流程中无法进行处理，所以转为在 Load 阶段上报
@property(nonatomic, readwrite) NSUInteger moveTrackerProcessFailedCount;

/// 无法处理而丢弃的崩溃数量
/// 这些崩溃因为长期在 Load 阶段处理失败而被丢弃，会导致 Slardar 平台统计数量减少
@property(nonatomic, readwrite) NSUInteger dropCrashIfProcessFailedCount;

+ (instancetype)report;

@end
