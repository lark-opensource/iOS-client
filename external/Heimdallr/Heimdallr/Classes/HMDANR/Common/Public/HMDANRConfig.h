//
//  HMDANRConfig.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/14.
//

#import "HMDTrackerConfig.h"

extern NSString *const kHMDModuleANRTracker;//卡顿监控

@interface HMDANRConfig : HMDTrackerConfig

@property (nonatomic, assign) double timeoutInterval;
@property (nonatomic, assign) NSInteger maxUploadCount;
@property (nonatomic, assign) BOOL enableSample;
@property (nonatomic, assign) double sampleInterval;
@property (nonatomic, assign) double sampleTimeoutInterval;
@property (nonatomic, assign) double launchThreshold;
@property (nonatomic, assign) BOOL ignoreBackground;
@property (nonatomic, assign) BOOL ignoreDuplicate;
@property (nonatomic, assign) BOOL ignoreBacktrace;
@property (nonatomic, assign) BOOL suspend;
@property (nonatomic, assign) int maxContinuousReportTimes;

// Replace the main thread waking up the sub-monitor-thread through the sub-monitor-thread sleep.
// The advantage is that the monitoring thread will not be woken up frequently, but the disadvantage is that the monitoring will become inaccurate.
// Default: NO
@property(nonatomic, assign)BOOL enableRunloopMonitorV2;

// monitor thread sleep interval.
// Default: 50ms Range: [32ms, 1000ms]
@property(nonatomic, assign)NSUInteger runloopMonitorThreadSleepInterval;

@end

