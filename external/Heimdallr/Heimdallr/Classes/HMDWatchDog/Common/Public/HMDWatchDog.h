//
//  HMDWatchDog.h
//  CLT
//
//  Created by sunrunwang on 2019/3/15.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol HMDWatchDogDelegate;

extern NSString * _Nullable const kHMDModuleWatchDogKey;//卡死监控模块ID

// 疑似卡死通知
// 说明：
// 1、该通知表示WatchDog模块内发现Runloop阻塞超过2s，存在卡死风险
// 2、该通知在非主线程异步发出（卡死时，主线程处于阻塞状态）
// 3、若后续Runloop阻塞恢复，则此次不被判定为卡死，此通知仅为”疑似”卡死通知，不等同于卡死发生
// 4、根据本地策略，该卡死数据后续可能会被过滤，并不一定会进行异常数据上报，该通知数据与Slardar平台卡顿数据并不能保持一致
extern NSString * _Nullable HMDWatchDogMaybeHappenNotification;

// 卡死超时通知
// 说明：
// 1、该通知表示WatchDog模块内发现Runloop阻塞超过timeout_duration（默认8s），高概率发生卡死
// 2、该通知在非主线程异步发出（卡死时，主线程处于阻塞状态）
// 3、若后续Runloop阻塞恢复，则此次不被判定为卡死，此通知为高概率卡死通知，不等同于卡死发生
// 4、根据本地策略，该卡死数据后续可能会被过滤，并不一定会进行异常数据上报，该通知数据与Slardar平台卡顿数据并不能保持一致
extern NSString * _Nullable HMDWatchDogTimeoutNotification;

// 卡死恢复通知
// 说明：
// 1、若通过HMDWatchDogMaybeHappenNotification 或 HMDWatchDogTimeoutNotification发出过通过后Runloop恢复运行，则会发出该通知
// 2、该通知在非主线程异步发出
extern NSString * _Nullable HMDWatchDogRecoverNotification;

// 默认值
// 若想修改默认行为逻辑，请在Heimdallr初始化前修改以下参数
extern NSTimeInterval HMDWatchDogDefaultTimeoutInterval; // Default: 8.0 Range: [1.0, 20.0]
extern NSTimeInterval HMDWatchDogDefaultSampleInterval; // Default: 1.0 Range: [0.5, 2.0]
extern NSUInteger HMDWatchdogDefaultLastThreadsCount; // Default: 3 Range: [0, 10]
extern NSTimeInterval HMDWatchDogDefaultLaunchCrashThreshold; // 启动崩溃时间阈值
// Default: 5.0 Range: [1.0, 60.0]
extern BOOL HMDWatchDogDefaultSuspend; // Default: NO
extern BOOL HMDWatchDogDefaultIgnoreBackground; // Default: NO
extern BOOL HMDWatchDogDefaultUploadAlog; // Default: NO
extern BOOL HMDWatchDogDefaultUploadMemoryLog; //Default: NO
extern BOOL HMDWatchDogDefaultRaiseMainThreadPriority; //Default: NO
extern NSTimeInterval HMDWatchdogDefaultRaiseMainThreadPriorityInterval; //Default: 8s
extern BOOL HMDWatchDogEnableRunloopMonitorV2; //Default: NO
extern NSUInteger HMDWatchDogRunloopMonitorThreadSleepInterval; //Default:500ms
extern BOOL HMDWatchDogDefaultEnableMonitorCompleteRunloop; //Default:NO

@interface HMDWatchDog : NSObject

+ (instancetype _Nullable )sharedInstance;

// 超时时间，超过该时间阈值后则判定为疑似卡死，进行抓栈
// Default: 8.0 Range: [1.0, 20.0]
@property(nonatomic, assign)NSTimeInterval timeoutInterval;

// 超时后，环境采样间隔，间隔越小精度越高
// Default: 1.0 Range: [0.5, 2.0]
@property(nonatomic, assign)NSTimeInterval sampleInterval;

// 额外上报的主线程堆栈数量（上报最后N次采样时获取的主线程堆栈）
// Default: 3 Range: [0, 10]
@property(nonatomic, assign) NSUInteger lastThreadsCount;

// 启动崩溃时间阈值
// Default: 5.0 Range: [1.0, 60.0]
@property(nonatomic, assign)NSTimeInterval launchCrashThreshold;

// 抓栈是是否suspend目标线程
// YES：抓栈时目标线程无法运行，堆栈回溯准确。NO：抓栈时堆栈线程仍然运行，可能造成堆栈错误
// Default: NO
@property(nonatomic, assign)BOOL suspend;

// 是否忽略后台场景
// Default: NO
@property(nonatomic, assign)BOOL ignoreBackground;

// 在上传卡死日志时是否同步上传Alog日志
// Default: NO
@property(nonatomic, assign)BOOL uploadAlog;

// 在上传卡死日志时是否上传memorylog，用于展示内存趋势图
// Default: NO
@property(nonatomic, assign)BOOL uploadMemoryLog;

// 检测到卡死时，是否提升主线程优先级
// Default: NO
@property(nonatomic, assign)BOOL raiseMainThreadPriority;

// 提升主线程优先级的时间，开启raiseMainThreadPriority后生效 default：8s range：[3,8]
// Default: 8s Range: [3, 8]
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


@property(nonatomic, weak, nullable)id<HMDWatchDogDelegate> delegate;

- (void)start;
- (void)stop;

@end

