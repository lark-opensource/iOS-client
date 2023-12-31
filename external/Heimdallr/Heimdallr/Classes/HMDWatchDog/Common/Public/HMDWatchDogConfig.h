//
//  HMDWatchDogConfig.h
//  Heimdallr
//
//  Created by sunrunwang on don't matter time
//

#import "HMDTrackerConfig.h"

extern NSString *const kHMDModuleWatchDogKey;//卡死监控

@interface HMDWatchDogConfig : HMDTrackerConfig

// 超时时间，超过该时间阈值后则判定为疑似卡死，进行抓栈
// Default: 8.0 Range: [1.0, 20.0]
@property(nonatomic, assign) NSTimeInterval timeoutInterval;

// 超时后，环境采样间隔，间隔越小精度越高
// Default: 1.0 Range: [0.5, 2.0]
@property(nonatomic, assign) NSTimeInterval sampleInterval;

// 额外上报的主线程堆栈数量（上报最后N次采样时获取的主线程堆栈）
// Default: 3 Range: [0, 10]
@property(nonatomic, assign) NSUInteger lastThreadsCount;

// 启动崩溃时间阈值
// Default: 5.0 Range: [1.0, 60.0]
@property(nonatomic, assign) NSTimeInterval launchCrashThreshold;

// 抓栈是是否suspend目标线程
// Default: NO
@property(nonatomic, assign) BOOL suspend;

// 是否忽略后台场景
// Default: NO
@property(nonatomic, assign) BOOL ignoreBackground;

// 在上传卡死日志时是否同步上传Alog日志
// Default: NO
@property(nonatomic, assign)BOOL uploadAlog;

// 在上传卡死日志时是否上传memorylog，用于展示内存趋势图
// Default: NO
@property(nonatomic, assign)BOOL uploadMemoryLog;

// 主线程执行缓慢时，是否提升主线程优先级
// Default: NO
@property(nonatomic, assign)BOOL raiseMainThreadPriority;

// 提升主线程优先级的时间，开启raiseMainThreadPriority后生效 default：8s range：[3,8]
// Default: NO
@property(nonatomic, assign)NSTimeInterval raiseMainThreadPriorityInterval;

// Replace the main thread waking up the sub-monitor-thread through the sub-monitor-thread sleep.
// The advantage is that the monitoring thread will not be woken up frequently, but the disadvantage is that the monitoring will become inaccurate.
// Default: NO
@property(nonatomic, assign)BOOL enableRunloopMonitorV2;

// monitor thread sleep interval.
// Default: 500ms Range: [32ms, 1000ms]
@property(nonatomic, assign)NSUInteger runloopMonitorThreadSleepInterval;

// kCFRunLoopEntry, kCFRunLoopAfterWaiting will be considered the start of a runloop, and kCFRunLoopBeforeWaiting will be end. Instead of monitoring the interval between two activities.
// Default: NO
@property(nonatomic, assign)BOOL enableMonitorCompleteRunloop;

@end
