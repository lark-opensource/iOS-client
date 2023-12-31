//
//  BDPMonitor.m
//  Timor
//
//  Created by MacPu on 2018/10/18.
//

#import "BDPMonitor.h"
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPTracker.h>
#import <OPFoundation/BDPMacroUtils.h>
#import <OPFoundation/BDPTimorClient.h>
#import "BDPMonitorCenter.h"
#import <OPFoundation/BDPVersionManager.h>
#import <OPFoundation/BDPI18n.h>
#import <OPFoundation/BDPUniqueID.h>
#import <ECOProbe/OPMonitorReportPlatform.h>

// 默认2分钟上报一次
#define kBDPMonitorDefaultReportTimeInterval (2*60.f)
// 第一次触发为30秒
#define kBDPMonitorDefaultReportFirstDelay (30.f)

@interface BDPMonitor ()

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSTimeInterval timerInterval;
@property (nonatomic, assign) NSTimeInterval firstFireDelay;
@property (nonatomic, strong) NSMutableArray<BDPMonitorData *> *recievedDatas;
@end

@implementation BDPMonitor

#pragma mark Life Cycle
- (instancetype)init
{
    self = [super init];
    if (self) {
        _timerInterval = kBDPMonitorDefaultReportTimeInterval;
        _firstFireDelay = kBDPMonitorDefaultReportFirstDelay;
    }
    return self;
}

- (void)dealloc
{
    [self stop];
}

#pragma mark <BDPMonitorProtocol>

- (void)start
{
    NSAssert(self.uniqueID.isValid, BDPI18n.bdpmonitor_mpid_must_non_null);
    [[BDPMonitorCenter sharedInstance] addMonitor:self];
    _timer = [NSTimer timerWithTimeInterval:2 * 60 target:self selector:@selector(reportData) userInfo:nil repeats:YES];
    _timer.fireDate = [NSDate dateWithTimeIntervalSinceNow:30];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)stop
{
    [[BDPMonitorCenter sharedInstance] removeMonitror:self];
    [_timer invalidate];
    _timer = nil;
}

- (void)resetIntervalOfReport:(NSTimeInterval)interval firstFireDelay:(NSTimeInterval)delay
{
    if (_timer) {
        [self _resetTimer:interval firstFireDelay:delay];
    }
    else {
        _timerInterval = interval;
        _firstFireDelay = delay;
    }
}

- (NSTimeInterval)intervalOfReport
{
    return _timerInterval;
}

- (NSTimeInterval)firstFireDelayOfReport
{
    return _firstFireDelay;
}

- (NSTimeInterval)getDefaultIntervalOfReport
{
    return kBDPMonitorDefaultReportTimeInterval;
}

- (NSTimeInterval)getDefaultFirstFireDelayOfReport
{
    return kBDPMonitorDefaultReportFirstDelay;
}


#pragma mark <BDPMonitorProtocol>

- (void)recieveMonitorData:(BDPMonitorData *)data
{
    [self.recievedDatas addObject:data];
}

- (NSMutableArray<BDPMonitorData *> *)recievedDatas
{
    if (!_recievedDatas) {
        _recievedDatas = [[NSMutableArray alloc] init];
    }
    return _recievedDatas;
}

#pragma mark Private Method

- (void)_resetTimer:(NSTimeInterval)interval firstFireDelay:(NSTimeInterval)delay
{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    _timerInterval = interval;
    _firstFireDelay = delay;
    _timer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(reportData) userInfo:nil repeats:YES];
    _timer.fireDate = [NSDate dateWithTimeIntervalSinceNow:delay];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)reportData
{
    if (self.recievedDatas.count == 0) {
        return;
    }
    
    CGFloat totalFPS = 0;
    CGFloat totalCPU = 0;
    CGFloat totalCPUS = 0;
    CGFloat totalMemory = 0;
//    NSInteger totalFreeze = 0;
//    NSUInteger totalRunloop = 0;
    CGFloat minFPS = CGFLOAT_MAX;
    CGFloat maxCPU = CGFLOAT_MIN;
    CGFloat maxCPUS = CGFLOAT_MIN;
    CGFloat maxMemory = CGFLOAT_MIN;
    
    int cpuErrorCount = 0;
    int cpuErrorCountS = 0;
    int memoryErrorCount = 0;
    int fpsErrorCount = 0;
    for (BDPMonitorData *data in self.recievedDatas) {
        if (data.cpuRatio > maxCPU) maxCPU = data.cpuRatio;
        if (data.cpuRatioForSingleApp > maxCPUS) maxCPUS = data.cpuRatioForSingleApp;
        if (data.fps < minFPS) minFPS = data.fps;
        if (data.memory > maxMemory) maxMemory = data.memory;
        (data.fps > 0 && data.fps < 65)?totalFPS += data.fps:fpsErrorCount++;
        data.cpuRatio >= 0?totalCPU += data.cpuRatio:cpuErrorCount++;
        data.cpuRatioForSingleApp >= 0?totalCPUS += data.cpuRatioForSingleApp:cpuErrorCountS++;
        data.memory > 0?totalMemory += data.memory:memoryErrorCount++;
        
//        totalFreeze += data.freeze;
//        totalRunloop += data.runloopTimes;
    }
    
    NSInteger cpuAverageRatio = maxCPU > 0?[self averageNumWithTotalAmount:totalCPU recievedCount:self.recievedDatas.count errorCount:cpuErrorCount]:0;
    
    NSInteger cpuAverageRatioS = maxCPUS > 0?[self averageNumWithTotalAmount:totalCPUS recievedCount:self.recievedDatas.count errorCount:cpuErrorCountS]:0;
 
    NSInteger memoryAverageOccupation = maxMemory > 0?[self averageNumWithTotalAmount:totalMemory recievedCount:self.recievedDatas.count errorCount:memoryErrorCount]:0;
    
    NSInteger averageFps = minFPS > 0?[self averageNumWithTotalAmount:totalFPS recievedCount:self.recievedDatas.count errorCount:fpsErrorCount]:0;
    
    long long physicalMemory = [NSProcessInfo processInfo].physicalMemory;
    
    NSDictionary *category = @{BDPTrackerAppIDKey:_uniqueID.appID ?: @"",
                               BDPTrackerLibVersionKey: [BDPVersionManager localLibVersionString],
                               BDPTrackerLibGreyHashKey: [BDPVersionManager localLibGreyHash],
                               BDPTrackerParamSpecialKey: BDPTrackerApp,
                               @"is_background":@(!self.isActive)};
    
    NSDictionary *metric = @{@"avg_cpu_front": @([@(cpuAverageRatioS) integerValue]),
                             @"avg_cpu_ratio": @(cpuAverageRatio),
                             @"avg_fps":@(averageFps),
                             @"avg_memory_occupation":@([@(memoryAverageOccupation / 1024) integerValue]),
                             @"avg_memory_ratio":@([@(memoryAverageOccupation / physicalMemory * 100) integerValue]),
                             //@"average_freezing":@(totalFreeze * 1.0 / totalRunloop),   // 每分钟卡顿率
                             @"max_cpu_ratio": @([@(maxCPU) integerValue]),
                             @"max_cpu_front": @([@(maxCPUS) integerValue]),
                             @"min_fps":@([@(minFPS) integerValue]),
                             @"max_memory_occupation":@([@(maxMemory  / 1024) integerValue]),
                             @"max_memory_ratio":@([@(maxMemory / physicalMemory * 100) integerValue])
                             };
    
    NSDictionary *extraValue = @{};
    
    NSMutableDictionary *allParam = [NSMutableDictionary dictionary];
    [allParam addEntriesFromDictionary:category];
    [allParam addEntriesFromDictionary:metric];
    [allParam addEntriesFromDictionary:extraValue];
    NSDictionary *params = [allParam copy];
    BDPPlugin(monitorPlugin, BDPMonitorPluginDelegate);
    if ([monitorPlugin respondsToSelector:@selector(bdp_monitorEventName:metric:category:extra:platform:)]) {
        [monitorPlugin bdp_monitorEventName:@"mp_performance_report"
                                     metric:metric
                                   category:category
                                      extra:extraValue
                                   platform:OPMonitorReportPlatformSlardar|OPMonitorReportPlatformTea];
    } else {
        [BDPTracker event:@"mp_performance_report" attributes:params uniqueID:nil];
    }
    
    BDPLogDebug(@"[TMA] preformance:%@",params);

    [self.recievedDatas removeAllObjects];
    
    NSString *info = [NSString stringWithFormat:@"%@:\r\n%@", @"性能状态", params];
}

- (NSInteger)averageNumWithTotalAmount:(NSInteger)totalAmount recievedCount:(NSInteger)recievedCount errorCount:(NSInteger)errorCount
{
    NSInteger averageNum = 0;
    if (errorCount < recievedCount) {
        averageNum = totalAmount/(recievedCount - errorCount);
    }
    return averageNum;
}


@end
