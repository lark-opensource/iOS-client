//
//  HMDBatteryMonitor.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import "HMDBatteryMonitor.h"
#import "HMDMonitorRecord+DBStore.h"
#import "HMDMonitor+Private.h"
#import "HMDPerformanceReporter.h"
#import "HMDBatteryMonitorRecord.h"
#import "HMDDynamicCall.h"
#import "hmd_section_data_utility.h"

static const NSUInteger kHMDOneMinuteTime = 60;

NSString *const kHMDModuleBatteryMonitor = @"battery";

HMD_MODULE_CONFIG(HMDBatteryMonitorConfig)

@implementation HMDBatteryMonitorConfig
+ (NSString *)configKey
{
    return kHMDModuleBatteryMonitor;
}

- (id<HeimdallrModule>)getModule
{
    return [HMDBatteryMonitor sharedMonitor];
}
@end


@interface HMDBatteryMonitor ()

@property(nonatomic, assign) NSTimeInterval lastRecordTimestamp;
@property(nonatomic, assign) double lastRecordBatteryLevel;
@property(nonatomic, assign) double sessionStartBatteryLevel;
@property(nonatomic, assign) double sessionUsedBatteryLevel;
@property(nonatomic, assign) double minuteRecordinterval;
@property(atomic, assign) BOOL didAddObserver;

@end

@implementation HMDBatteryMonitor

SHAREDMONITOR(HMDBatteryMonitor)

- (void)dealloc {
    [self stop];
    if (_didAddObserver) {
        _didAddObserver = NO;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (Class<HMDRecordStoreObject>)storeClass
{
    return [HMDBatteryMonitorRecord class];
}

- (HMDMonitorRecord *)refresh
{
    return [self recordForSpecificScene:nil];
}

- (HMDBatteryMonitorRecord *)recordForSpecificScene:(NSString *)scene
{
    if (!self.isRunning || ([UIDevice currentDevice].batteryState != UIDeviceBatteryStateUnplugged)) {
        return nil;
    }
    
    double betteryLevel = [UIDevice currentDevice].batteryLevel;
    UIDeviceBatteryState batteryState = [UIDevice currentDevice].batteryState;
    HMDBatteryMonitorRecord *record = [HMDBatteryMonitorRecord newRecord];
    record.batteryState = batteryState;
    record.batteryLevel = betteryLevel;
    
    //scene无论参数中有没有都记，有的话再记pageUsage
    record.scene = scene ?: DC_IS(DC_OB(DC_CL(HMDUITrackerManager, sharedManager), scene), NSString);
    
    if (scene && self.curPageUsage) {
        record.pageUsage = self.curPageUsage - record.batteryLevel;
    } else {
        record.pageUsage = -1;
    }
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] - self.lastRecordTimestamp;

    // 满足要求，则采集每分钟电量消耗
    if ((interval > self.minuteRecordinterval) && (self.lastRecordBatteryLevel > 0) && (self.lastRecordTimestamp != 0)) {
        record.perMinuteUsage = (kHMDOneMinuteTime / interval) * (self.lastRecordBatteryLevel - record.batteryLevel);
        
        self.lastRecordTimestamp = [[NSDate date] timeIntervalSince1970];
        self.lastRecordBatteryLevel = record.batteryLevel;
    } else {
        record.perMinuteUsage = -1;
    }
    // 开启采集时，初始化时间和电量
    if (self.lastRecordTimestamp == 0 || self.lastRecordBatteryLevel <= 0) {
        self.lastRecordTimestamp = [[NSDate date] timeIntervalSince1970];
        self.lastRecordBatteryLevel = record.batteryLevel;
    }
    
    // 记录一次 session 使用的电量
    record.sessionUsage = self.sessionUsedBatteryLevel;
    
    dispatch_on_monitor_queue(^{
        [self.curve pushRecord:record];
    });
    return record;
}

- (void)start {
    [super start];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self openBatteyMonitorInMainThread];
    });
}

- (void)stop {
    [super stop];
}

- (void)openBatteyMonitorInMainThread {
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    dispatch_on_monitor_queue(^{
        if (!self.didAddObserver) {
           [self recordForSpecificScene:nil];
            self.didAddObserver = YES;
           [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryLevelDidChange:) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
           [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryStateDidChange:) name:UIDeviceBatteryStateDidChangeNotification object:nil];
           [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
           [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        }
    });
}

- (void)batteryLevelDidChange:(NSNotification *)notifi
{
    [self recordForSpecificScene:nil];
}

- (void)batteryStateDidChange:(NSNotification *)notifi
{
    UIDeviceBatteryState batteryState = [UIDevice currentDevice].batteryState;
    if (batteryState != UIDeviceBatteryStateUnplugged) {
        self.lastRecordBatteryLevel = 0;
        self.lastRecordTimestamp = 0;
        self.curPageUsage = 0;
        
        [self stop];
    } else {
        [self start];
    }
}

- (void)willEnterForeground:(NSNotification *)notification {
    self.curPageUsage = [UIDevice currentDevice].batteryLevel;
    self.sessionStartBatteryLevel = [UIDevice currentDevice].batteryLevel;
    self.sessionUsedBatteryLevel = -1;
}

- (void)didEnterBackground:(NSNotification *)notification {
    // 计算 session 电量使用值
    self.sessionUsedBatteryLevel = [UIDevice currentDevice].batteryLevel - self.sessionStartBatteryLevel;
    // 记录
    [self recordForSpecificScene:DC_IS(DC_OB(DC_CL(HMDUITrackerManager, sharedManager), scene), NSString)];
}

#pragma mark HeimdallrModule
- (void)updateConfig:(HMDBatteryMonitorConfig *)config
{
    [super updateConfig:config];
    
    if (self.refreshInterval < 1) {
        self.refreshInterval = 30.0;
    }
    
    self.minuteRecordinterval = kHMDOneMinuteTime;
    if (self.refreshInterval > kHMDOneMinuteTime) {
        self.minuteRecordinterval = self.refreshInterval;
    }
}
#pragma mark - override

- (void)didEnterScene:(NSString *)scene {
    self.curPageUsage = [UIDevice currentDevice].batteryLevel;
}

- (void)willLeaveScene:(NSString *)scene {
    [self recordForSpecificScene:scene];
}

#pragma - mark upload

- (NSUInteger)reporterPriority {
    return HMDReporterPriorityBatteryMonitor;
}

@end
