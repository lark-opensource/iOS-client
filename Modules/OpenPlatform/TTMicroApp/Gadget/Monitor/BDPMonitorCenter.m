//
//  BDPMonitorCenter.m
//  Timor
//
//  Created by MacPu on 2018/10/19.
//

#import "BDPMonitorCenter.h"
#import "BDPCPUMonitor.h"
#import "BDPFPSMonitor.h"
#import "BDPFreezeMonitor.h"
#import "BDPMemoryMonitor.h"
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/EMAFeatureGating.h>

#define kBDPPreformDataUpdateTime 15.f
#define kBDPMonitorTimeIntervalNotSet -1.f

/// private methods
@interface BDPMonitor ()

- (void)recieveMonitorData:(BDPMonitorData *)data;
@end

@interface BDPMonitorCenter ()

@property (nonatomic, strong) BDPFreezeMonitor *freezeMonitor;
@property (nonatomic, strong) BDPFPSMonitor *fpsMonitor;
@property (nonatomic, strong) NSMutableArray<id<BDPMonitorProtocol>> *monitors;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSTimeInterval timerInterval;
@property (nonatomic, assign) NSTimeInterval reportInterval;
@property (nonatomic, assign) NSTimeInterval reportFirstFireDelay;

@end

@implementation BDPMonitorCenter

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static BDPMonitorCenter  *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BDPMonitorCenter alloc] _init];
    });
    return sharedInstance;
}

- (instancetype)_init
{
    self = [super init];
    if (self) {
        _monitors = [[NSMutableArray alloc] init];
        _timerInterval = kBDPPreformDataUpdateTime;
        _reportInterval = kBDPMonitorTimeIntervalNotSet;
        _reportFirstFireDelay = kBDPMonitorTimeIntervalNotSet;
    }
    return self;
}

- (void)dealloc
{
    [self stopMonitor];
}

- (void)addMonitor:(id<BDPMonitorProtocol>)monitor
{
    // 设置上报间隔
    NSTimeInterval reportInterval = _reportInterval;
    NSTimeInterval reportFirstFireDelay = _reportFirstFireDelay;
    
    if (reportInterval == kBDPMonitorTimeIntervalNotSet) {
        reportInterval = [monitor getDefaultIntervalOfReport];
    }
    if (reportFirstFireDelay == kBDPMonitorTimeIntervalNotSet) {
        reportFirstFireDelay = [monitor getDefaultFirstFireDelayOfReport];
    }
    [monitor resetIntervalOfReport:reportInterval firstFireDelay:reportFirstFireDelay];
    
    // 加入数组
    [_monitors addObject:monitor];
    if (_monitors.count == 1) {
        [self startMonitor];
    }
}

- (void)removeMonitror:(id<BDPMonitorProtocol>)monitor
{
    [_monitors removeObject:monitor];
    if (_monitors.count == 0) {
        [self stopMonitor];
    }
}

- (NSArray<id<BDPMonitorProtocol>>*)getMonitors
{
    return _monitors;
}

- (void)customCollectInterval:(NSTimeInterval)interval
              reportIntervals:(NSTimeInterval)reportInterval
         reportFirstFireDelay:(NSTimeInterval)reportFirstFireDelay;
{
    _timerInterval = interval;
    _reportInterval = reportInterval;
    _reportFirstFireDelay = reportFirstFireDelay;
    if (_timer) {
        [self _resetTimer];
    }
    for (BDPMonitor *monitor in _monitors) {
        [monitor resetIntervalOfReport:_reportInterval firstFireDelay:_reportFirstFireDelay];
    }
}

- (void)resetAllIntervalToDefault
{
    _timerInterval = kBDPPreformDataUpdateTime;
    _reportInterval = kBDPMonitorTimeIntervalNotSet;
    _reportFirstFireDelay = kBDPMonitorTimeIntervalNotSet;
    if (_timer) {
        [self _resetTimer];
    }
    for (BDPMonitor *monitor in _monitors) {
        NSTimeInterval reportInterval = [monitor getDefaultIntervalOfReport];
        NSTimeInterval reportFirstFireDelay = [monitor getDefaultFirstFireDelayOfReport];
        [monitor resetIntervalOfReport:reportInterval firstFireDelay:reportFirstFireDelay];
    }
}

#pragma mark Private Method

- (void)startMonitor
{
//    [BDPFreezeMonitor start];
    [BDPFPSMonitor start];
    [self _resetTimer];
}

- (void)stopMonitor
{
    
//    [BDPFreezeMonitor stop];
    [BDPFPSMonitor stop];
}

- (void)updateMonitorData
{
    if (_monitors.count == 0) {
        [self stopMonitor];
        return;
    }



    dispatch_async(dispatch_get_global_queue(0, 0), ^{

        BDPMonitorData *data= [[BDPMonitorData alloc] init];
        data.cpuRatio = [BDPCPUMonitor cpuUsage];
        data.memory = [BDPMemoryMonitor currentMemoryUsageInBytes];
        data.fps = [BDPFPSMonitor fps];
        BDPFreezeMonitorData *freezeData = [BDPFreezeMonitor freeze];
        data.freeze = freezeData.freezeCount;
        data.runloopTimes = freezeData.totalCount;

        BOOL featureOn = [EMAFeatureGating boolValueForKey:@"openplatform.gadget.cpu.usage"];
        BDPExecuteOnMainQueue(^{
            for (BDPMonitor *monitor in _monitors) {
                if (featureOn) {
                    data.cpuRatioForSingleApp = [BDPCPUMonitor cpuUsageForUniqueID:monitor.uniqueID];
                }
                [monitor recieveMonitorData:data];
            }
        });
    });
}

- (void) _resetTimer
{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    _timer = [NSTimer timerWithTimeInterval:_timerInterval target:self selector:@selector(updateMonitorData) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

@end
