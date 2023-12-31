//
//  HMDANRMonitor.h
//  Heimdallr
//
//  Created by joy on 2018/4/26.
//

#import <Foundation/Foundation.h>


// 卡顿超时通知
// 说明：
// 1、该通知表示ANR模块内发现Runloop阻塞超出卡顿设定阈值（超出常规阈值 或 通过采样超过采样阈值），此时判定为“疑似”卡顿场景
// 2、该通知在非主线程触发（卡顿时，主线程处于阻塞状态）
// 3、若Runloop一直阻塞，则本次被判定为卡死，并不是卡顿，此通知仅为“疑似”卡顿通知，不等同于卡顿发生
// 4、根据本地策略，该卡顿数据后续可能会被过滤，并不一定会进行异常数据上报，该通知数据与Slardar平台卡顿数据并不能保持一致
// 5、通知Object是一个HMDANRMonitorInfo对象
extern NSString * _Nullable const HMDANRTimeoutNotification;

// 卡顿结束通知
// 说明：
// 1、该通知表示ANR模块内发现Runloop阻塞超出卡顿设定阈值后，等待卡顿结束，卡顿结束时发送该通知
// 2、该通知在非主线程触发（卡顿时，主线程处于阻塞状态）
// 3、发送该通知则必定被判定为一次卡顿
// 4、根据本地过滤策略，该卡顿数据后续可能会被过滤（去重、冷却等），并不一定会进行异常数据上报，该通知次数与Slardar平台卡顿数据量并不能保证完全一致
extern NSString * _Nullable const HMDANROverNotification;

// 默认值
// 若想修改默认行为逻辑，请在Heimdallr初始化前修改以下参数
extern NSTimeInterval HMDANRDefaultTimeoutInterval;
extern NSTimeInterval HMDANRDefaultSampleInterval;
extern NSTimeInterval HMDANRDefaultSampleTimeoutInterval;
extern NSTimeInterval HMDANRDefaultLaunchInterval;
extern BOOL HMDANRDefaultEnableSample;
extern BOOL HMDANRDefaultIgnoreBackground;
extern BOOL HMDANRDefaultIgnoreDuplicate;
extern BOOL HMDANRDefaultIgnoreBacktrace;
extern BOOL HMDANRDefaultSuspend;

@interface HMDANRMonitorInfo : NSObject
@property(nonatomic, assign)NSTimeInterval timestamp;
@property(nonatomic, assign)NSTimeInterval duration;
@property(nonatomic, assign)NSTimeInterval inAppTime;
@property(nonatomic, assign)uint64_t anrTime;
@property(nonatomic, strong, nullable)NSString *stackLog;
@property(nonatomic, assign)BOOL sampleFlag;
@property(nonatomic, assign)BOOL background;
@property(nonatomic, assign)BOOL isLaunch;
@property(nonatomic, assign)BOOL isUITrackingRunloopMode;
@property(nonatomic, assign)double mainThreadCPUUsage;
@property (nonatomic, strong, nullable) NSArray *flameGraph;
@property (nonatomic, strong, nullable) NSDictionary<NSString *,NSDictionary *> *binaryImages;
@end

@protocol HMDANRMonitorDelegate <NSObject>

- (void)didBlockWithInfo:(HMDANRMonitorInfo * _Nullable)info;

@end

@interface HMDANRMonitor : NSObject

+ (instancetype _Nullable )sharedInstance;

/**
 * 采样功能开关
 * 开启采样功能后，每个采样周期会对主线程进行堆栈采样，发生卡顿时，可获取更加准确的卡顿堆栈，默认为NO
 */
@property(nonatomic, assign)BOOL enableSample;

/**
 * 采样间隔
 * 采样功能开启时有效，定义初始采样间隔，默认为50ms，设置范围 50(ms) ~ 100(ms)
 */
@property(nonatomic, assign)NSTimeInterval sampleInterval;

/**
 * 采样卡顿阈值
 * 采样功能开启是，累计相似堆栈超过设定阈值，则判定为卡顿
 */
@property(nonatomic, assign)NSTimeInterval sampleTimeoutInterval;

/**
 * 当App处于后台时，是否忽略卡顿，默认为NO
 * YES：App处于后台状态时不采集卡顿信息；
 * NO：App处于后台状态时采集卡顿信息；
 */
@property(nonatomic, assign)BOOL ignoreBackground;

/**
 * 重复堆栈忽略控制，默认为NO
 * 重复堆栈是否上报，YES：重复堆栈不上报；NO：重复堆栈上报
 */
@property(nonatomic, assign)BOOL ignoreDuplicate;

/**
 * 忽略采集堆栈，默认为NO
 * 说明：
 * 1、常规模式下，不再采集堆栈信息进行上报（Slardar平台不展现任何数据）
 * 2、采样模式下，该功能失效
 * 3、该功能开启后，ANR模块只是一个卡顿时间计时器，仅通过HMDANRTimeoutNotification、HMDANROverNotification通知卡顿事件基本信息，业务方可以进行自定义的打点
 */
@property(nonatomic, assign)BOOL ignoreBacktrace;

/**
 * 抓取全线程堆栈时，是否suspend线程，默认为NO
 * YES：抓取堆栈时，suspend线程；NO：抓取堆栈时，不suspend线程
 */
@property(nonatomic, assign)BOOL suspend;

/**
 * 卡顿阈值
 * 主线程Runloop阻塞时间超出卡顿阈值，则判定为卡顿
 */
@property(nonatomic, assign)NSTimeInterval timeoutInterval;

/**
 * 启动阶段判定阈值
 */
@property(nonatomic, assign)NSTimeInterval launchThreshold;

/**
 * The maximum continuous reporting threshold.
 *  When the interval between two ANR reports is less than 10s, it is regarded as continuous reporting.
 *  When the number of consecutive reports exceeds the threshold, the ANR module will take a break.
 */
@property(nonatomic, assign) int maxContinuousReportTimes;

// Replace the main thread waking up the sub-monitor-thread through the sub-monitor-thread sleep.
// The advantage is that the monitoring thread will not be woken up frequently, but the disadvantage is that the monitoring will become inaccurate.
// Default: NO
@property(nonatomic, assign)BOOL enableRunloopMonitorV2;

// monitor thread sleep interval.
// Default: 50ms Range: [32ms, 1000ms]
@property(nonatomic, assign)NSUInteger runloopMonitorThreadSleepInterval;

/**
 * 卡顿事件代理
 * 未设置代理则无法开启卡顿监控
 */
@property(nonatomic, strong, nullable)id<HMDANRMonitorDelegate> delegate;

/**
 * 开启卡顿监控（异步）
 */
- (void)start;

/**
 * 关闭卡顿监控（异步）
 */
- (void)stop;

@end

