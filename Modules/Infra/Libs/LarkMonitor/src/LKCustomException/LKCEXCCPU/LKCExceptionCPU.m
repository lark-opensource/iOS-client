//
//  LKCExceptionCPU.m
//  LarkMonitor
//
//  Created by sniperj on 2020/1/2.
//

#import "LKCExceptionCPU.h"
#import "LKCExcptionCPUConfig.h"
#import "LarkMonitor.h"
#import <LarkMonitor/LarkMonitor-Swift.h>
#include <sys/times.h>
#import <mach/mach.h>
#import <os/lock.h>
#import <UIKit/UIKit.h>

double LKCEXCCPUDefaultLowUsageRate = 0.5;
double LKCEXCCPUDefaultMiddleUsageRate = 0.8;
double LKCEXCCPUDefaultHighUsageRate = 1;

const int LKCEXCCPUTimeInterval = 5;
const int LKCEXCCPUUploadTimeInterval = 10;
const int LKCEXCCPURunningTime = 60;

const NSString *launchCPUUsageEvent = @"app_one_minute_cpu_usage";
const NSString *exceptionCPUUsageEvent = @"cpu_usage_exception";

const NSString *processName = @"process_name";

const NSString *cpuExceptionLow = @"cpu_over_low_exception_times";
const NSString *cpuExceptionMiddle = @"cpu_over_middle_exception_times";
const NSString *cpuExceptionHigh = @"cpu_over_high_exception_times";
const NSString *vcCpuExceptionLow = @"vc_cpu_over_low_exception_times";
const NSString *vcCpuExceptionMiddle = @"vc_cpu_over_middle_exception_times";
const NSString *vcCpuExceptionHigh = @"vc_cpu_over_high_exception_times";

typedef NS_ENUM(NSInteger, LKExceptionLevel) {
    LKExceptionLevel_LOW = 1,
    LKExceptionLevel_MIDDLE = 2,
    LKExceptionLevel_HIGH = 3,
};


@interface LKCExceptionCPU()
{
    dispatch_source_t _timer;
    os_unfair_lock _lock;
    ///Counter, used to save the running time of abnormal monitoring, unit s
    long long _counter;
    /// Record CPU start time
    long startCPUTime;
    double prevCPUUsage;
    /// Whether vc is running
    BOOL isVCState;
    BOOL isReadyToReport;
    /// whether is cold launch
    BOOL isColdLaunch;
    BOOL timerRun;
    double startTimestamp;
    double enterForebackgroundTimestamp;
    NSInteger cpuCount;
}

@property (nonatomic, strong) NSMutableDictionary *exceptionExtra;

@end


@implementation LKCExceptionCPU

+ (instancetype)sharedInstance {
    static LKCExceptionCPU *monitor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        monitor = [[LKCExceptionCPU alloc] init];
    });
    return monitor;
}

#pragma mark - Initalize

- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = OS_UNFAIR_LOCK_INIT;
        _counter = 0;
        _lowUsageRate = LKCEXCCPUDefaultLowUsageRate;
        _middleUsageRate = LKCEXCCPUDefaultMiddleUsageRate;
        _highUsageRate = LKCEXCCPUDefaultHighUsageRate;
        startTimestamp = CACurrentMediaTime();
        isColdLaunch = YES;
        timerRun = NO;
        cpuCount = NSProcessInfo.processInfo.activeProcessorCount;
        [self resetExceptionExtraAndState];
        [self registerNotifications];
    }
    return self;
}

#pragma mark - ExceptionMonitor

- (void)start {
    if (!self.isRunning) {
        os_unfair_lock_lock(&_lock);
        [super start];
        [self startMonitorWithInterval:1];
        os_unfair_lock_unlock(&_lock);
    }
}

- (void)end {
    if (self.isRunning) {
        os_unfair_lock_lock(&_lock);
        [super end];
        [self setMonitorTimeInterval:0.0];
        os_unfair_lock_unlock(&_lock);
    }
}

- (void)updateConfig:(LKCExcptionCPUConfig *)config {
    [super updateConfig:config];
    self.highUsageRate = config.highUsageRate;
    self.middleUsageRate = config.middleUsageRate;
    self.lowUsageRate = config.lowUsageRate;
}

#pragma mark - customMethod

- (void)resetCPUClock {
    struct tms begin_tms;
    clock_t begin;
    begin = times(&begin_tms);
    self->startCPUTime = begin_tms.tms_utime + begin_tms.tms_stime;
}

- (void)startMonitorWithInterval:(double)interval {
    [self setMonitorTimeInterval:interval];
}

-(void)setMonitorTimeInterval:(double)monitorTimeInterval {
    if(monitorTimeInterval == 0) {  // request to cancel the timer
        if(_timer != nil) {
            dispatch_source_cancel(_timer);
            _timer = nil;
        }
    }
    else {
        if(_timer == nil) {     // request to start new timer
            _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_queue_create("com.cpu.monitor", 0));
            dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, monitorTimeInterval * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
            __weak LKCExceptionCPU *weakSelf = self;
            dispatch_source_set_event_handler(_timer, ^{
                self->_counter += monitorTimeInterval;
                if (self->_counter == LKCEXCCPURunningTime) {
                    [weakSelf uploadOneMinuesCPUUsage:YES];
                }
                if (self->_counter > LKCEXCCPURunningTime && self->_counter % LKCEXCCPUUploadTimeInterval == 0) {
                    double CPUUsage = [weakSelf getCPUUsageWithTimeInterval: LKCEXCCPUTimeInterval];
                    double averageCPUUsage = (CPUUsage + self->prevCPUUsage) / 2 / 100;
                    if(averageCPUUsage >= weakSelf.highUsageRate) {
                        [weakSelf updateExceptionContentWithType: LKExceptionLevel_HIGH];
                    } else if (averageCPUUsage >= weakSelf.middleUsageRate) {
                        [weakSelf updateExceptionContentWithType: LKExceptionLevel_MIDDLE];
                    } else if (averageCPUUsage >= weakSelf.lowUsageRate) {
                        [weakSelf updateExceptionContentWithType: LKExceptionLevel_LOW];
                    }
                } else if (self->_counter > LKCEXCCPURunningTime && self->_counter % LKCEXCCPUTimeInterval == 0) {
                    self->prevCPUUsage = [weakSelf getCPUUsageWithTimeInterval: LKCEXCCPUTimeInterval];
                }
            });
            dispatch_resume(_timer);
            timerRun = YES;
        }
    }
}

- (void)resetExceptionExtraAndState {
    os_unfair_lock_lock(&_lock);
    if (!_exceptionExtra) {
        _exceptionExtra = [NSMutableDictionary dictionary];
    }
    _exceptionExtra[processName] = @"app";
    _exceptionExtra[cpuExceptionLow] = @(0);
    _exceptionExtra[cpuExceptionMiddle] = @(0);
    _exceptionExtra[cpuExceptionHigh] = @(0);
    _exceptionExtra[vcCpuExceptionLow] = @(0);
    _exceptionExtra[vcCpuExceptionMiddle] = @(0);
    _exceptionExtra[vcCpuExceptionHigh] = @(0);
    os_unfair_lock_unlock(&_lock);
    self->isReadyToReport = NO;
}

- (void)updateExceptionContentWithType:(LKExceptionLevel)level {
    self->isReadyToReport = YES;
    os_unfair_lock_lock(&_lock);
    switch (level) {
        case LKExceptionLevel_LOW:
            if (isVCState) {
                _exceptionExtra[vcCpuExceptionLow] = @([_exceptionExtra[vcCpuExceptionLow] integerValue] + 1);
            } else {
                _exceptionExtra[cpuExceptionLow] = @([_exceptionExtra[cpuExceptionLow] integerValue] + 1);
            }
            break;
        case LKExceptionLevel_MIDDLE:
            if (isVCState) {
                _exceptionExtra[vcCpuExceptionMiddle] = @([_exceptionExtra[vcCpuExceptionMiddle] integerValue] + 1);
            } else {
                _exceptionExtra[cpuExceptionMiddle] = @([_exceptionExtra[cpuExceptionMiddle] integerValue] + 1);
            }
            break;
        case LKExceptionLevel_HIGH:
            if (isVCState) {
                _exceptionExtra[vcCpuExceptionHigh] = @([_exceptionExtra[vcCpuExceptionHigh] integerValue] + 1);
            } else {
                _exceptionExtra[cpuExceptionHigh] = @([_exceptionExtra[cpuExceptionHigh] integerValue] + 1);
            }
            break;
        default:
            break;
    }
    os_unfair_lock_unlock(&_lock);
}


- (double)getCPUUsageWithTimeInterval:(long long)interval {
    struct tms end_tms;
    clock_t end;
    end = times(&end_tms);
    long endCPU = end_tms.tms_utime + end_tms.tms_stime;
    double result = (endCPU - self->startCPUTime) / (double)interval;
    [self resetCPUClock];
    return result;
}

#pragma mark - notification

- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openVC) name:@"VCWillStartNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeVC) name:@"VCWillEndNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidbecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)openVC {
    isVCState = YES;
}

- (void)closeVC {
    isVCState = NO;
}

- (void)uploadOneMinuesCPUUsage:(BOOL)isFullOneMinues {
    double CPUUsage = [self getCPUUsageWithTimeInterval: self->_counter];
    double sinceStartup = (CACurrentMediaTime() - startTimestamp) * 1000;
    double sinceLatestEnterForeground = (CACurrentMediaTime() - enterForebackgroundTimestamp) * 1000;
    [LarkAllActionLoggerLoad logNarmalInfoWithInfo:[NSString stringWithFormat:@"App running 1minute CPUUsage %f", CPUUsage]];
    [LarkMonitor trackService:launchCPUUsageEvent metric:@{@"cpu_usage": @(CPUUsage),
                                                           @"use_full_one_minute": isFullOneMinues ? @(1) : @(0),
                                                           @"have_vc_use": self->isVCState ? @(1) : @(0),
                                                           @"cpu_count":@(cpuCount)}
                     category:@{@"is_cold_launch": isColdLaunch ? @(1) : @(0)}
                        extra:@{@"since_startup": @(sinceStartup),
                                @"since_latest_enter_foreground": @(sinceLatestEnterForeground)}];
    if (isColdLaunch) {
        isColdLaunch = NO;
    }
}

- (void)appDidEnterBackground {
    if (timerRun) {
        dispatch_suspend(_timer);
        timerRun = NO;
    }
    // not 60s upload data
    if (self->_counter < LKCEXCCPURunningTime) {
        [self uploadOneMinuesCPUUsage:NO];
    }
    self->_counter = 0;
}

- (void)appDidbecomeActive {
    [self resetCPUClock];
    enterForebackgroundTimestamp = CACurrentMediaTime();
    if (!timerRun) {
        dispatch_resume(_timer);
        timerRun = YES;
    }
    if (_exceptionExtra && self->isReadyToReport) {
        [LarkMonitor trackService:exceptionCPUUsageEvent metric:_exceptionExtra category:nil extra:nil];
    }
}

@end
