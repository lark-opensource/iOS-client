//
//  HMDMemoryMonitor.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import "HMDMemoryMonitor.h"
#import "HMDMonitorRecord+DBStore.h"
#import "HMDSessionTracker.h"
#import "HMDMacro.h"
#import "HMDMemoryUsage.h"
#import "HMDMonitor+Private.h"
#import "HMDStoreIMP.h"
#import "HMDMemoryMonitorRecord.h"
#import "HMDPerformanceReporter.h"
#import "hmd_section_data_utility.h"
#import "NSObject+HMDAttributes.h"
#import "NSDictionary+HMDSafe.h"

extern HMDMonitorName const kHMDModuleMemoryMonitor = @"memory";
NSString* const KHMDMemoryMonitorMemoryWarningNotificationName = @"KHMDMemoryMonitorMemoryWarningNotificationName";

HMD_MODULE_CONFIG(HMDMemoryMonitorConfig)

@implementation HMDMemoryMonitorConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(enableNotify, enable_notify, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(notifyMinInterval, notify_min_interval, @(10), @(10))
        HMD_ATTR_MAP_DEFAULT(highWaterPercentage, high_water_percentage, @(0.6), @(0.6))
    };
}

+ (NSString *)configKey {
    return kHMDModuleMemoryMonitor;
}

- (id<HeimdallrModule>)getModule {
    return [HMDMemoryMonitor sharedMonitor];
}
@end

@interface HMDMemoryMonitor ()

@property (nonatomic, assign) NSTimeInterval lastWarningTime;
@property (nonatomic, assign) HMDMemoryStatusType lastWarningType;
@property (nonatomic, strong) dispatch_source_t memoryPressureSource;
@property (nonatomic, strong) NSMutableDictionary *customData;

@end

@implementation HMDMemoryMonitor

SHAREDMONITOR(HMDMemoryMonitor)

- (void)customTrackBeginWithIdentifier:(NSString *)identifier {
    dispatch_on_monitor_queue(^{
        uint64_t curMemoryUsage = hmd_getAppMemoryBytes();
        [self.customData hmd_setSafeObject:@(curMemoryUsage) forKey:identifier];
    });
}

- (void)customTrackEndWithIdentifier:(NSString *)identifier {
    dispatch_on_monitor_queue(^{
        [self refresh:HMDMemoryStatusTypeDefault relativeforScene:nil identifier:identifier];
    });
}

- (Class<HMDRecordStoreObject>)storeClass
{
    return [HMDMemoryMonitorRecord class];
}

- (HMDMemoryMonitorRecord *)refresh
{
    return [self refresh:HMDMemoryStatusTypeDefault relativeforScene:nil identifier:nil];
}

- (HMDMemoryMonitorRecord *)refresh:(HMDMemoryStatusType)type relativeforScene:(NSString *)scene identifier:(NSString*)identify
{
    if(!self.isRunning) {
        return nil;
    }

    hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
    uint64_t appUsage = memoryBytes.appMemory;
    
    HMDMemoryMonitorConfig *config = (HMDMemoryMonitorConfig*)self.config;

    HMDMemoryMonitorRecord *record = [HMDMemoryMonitorRecord newRecord];
    record.appUsedMemory = appUsage;
    record.usedMemory = memoryBytes.usedMemory;
    record.totalMemory = memoryBytes.totalMemory;
    record.availableMemory = memoryBytes.availabelMemory;
    record.isBackground = [HMDSessionTracker currentSession].backgroundStatus;
    if ((type & HMDMemoryStatusWarningMask) == type) {
        record.memoryWarning= YES;
    }
    
    [HMDSessionTracker currentSession].memoryUsage = record.value;
    [HMDSessionTracker currentSession].freeMemory = record.availableMemory/HMD_MB;
    [HMDSessionTracker currentSession].deviceMemoryUsage = memoryBytes.usedMemory/HMD_MB;
    
    if (config.enableNotify) {
        static bool memoryHighWaterFlaglast = false;
        static uint64_t deviceMemoryLimit = hmd_getDeviceMemoryLimit();
        HMDMemoryStatusType warnType = type;
        if ((warnType & HMDMemoryStatusWarningMask) == warnType) {
            NSTimeInterval curTime = [[NSDate date]timeIntervalSince1970];
            if ((curTime - self.lastWarningTime >= config.notifyMinInterval) || self.lastWarningType < warnType) {
                self.lastWarningType = warnType;
                self.lastWarningTime = curTime;
                [[NSNotificationCenter defaultCenter] postNotificationName:KHMDMemoryMonitorMemoryWarningNotificationName object:nil userInfo:@{@"type": @(warnType)}];
            }
            CGFloat memoryRate = (appUsage*1.0)/deviceMemoryLimit;
            memoryHighWaterFlaglast = memoryRate > config.highWaterPercentage;
        }else {
            CGFloat memoryRate = (appUsage*1.0)/deviceMemoryLimit;
            NSTimeInterval curTime = [[NSDate date]timeIntervalSince1970];
            BOOL memoryHighWaterFlagCurrent = memoryRate > config.highWaterPercentage;
            if ((self.lastWarningType & HMDMemoryStatusWarningMask) == self.lastWarningType && memoryHighWaterFlagCurrent == YES && curTime - self.lastWarningTime < config.notifyMinInterval) {
                // 上一次为内存警告，这一次为高水位而且小于最小间隔不发送通知
            }else if((self.lastWarningType == HMDMemoryStatusTypeNormalLevel || self.lastWarningType == 0) && memoryHighWaterFlagCurrent == NO) {
                // 内存阈值连续低于hightwater，不发送通知
            }else {
                if (memoryHighWaterFlagCurrent != memoryHighWaterFlaglast ||
                    (curTime - self.lastWarningTime) >= config.notifyMinInterval) {
                    self.lastWarningTime = curTime;
                    warnType = memoryHighWaterFlagCurrent ? HMDMemoryStatusTypeHighWater : HMDMemoryStatusTypeNormalLevel;
                    self.lastWarningType = warnType;
                    [[NSNotificationCenter defaultCenter] postNotificationName:KHMDMemoryMonitorMemoryWarningNotificationName object:nil userInfo:@{@"type": @(warnType)}];
                }
            }
            memoryHighWaterFlaglast = memoryHighWaterFlagCurrent;
        }
    }
    
    if (scene) {
        double pageUsage = record.appUsedMemory - self.curPageUsage;
        record.scene = scene;
        record.pageUsedMemory = pageUsage;
    }

////因为稳定性和性能的问题内存dump功能暂时关闭
//    if (record.appUsedMemory > _dumpThreshold) {
//        //防止超过阈值之后的频繁dump
//        _dumpThreshold += _dumpIncreaseStep;
//        [[HMDMemoryDumper sharedInstance] snapShotLiveObjects:^(NSArray<HMDMemoryLiveObject *> *dumpInfo) {
//            if (dumpInfo.count > 0) {
//                NSMutableArray<NSDictionary *> *dumpDataArray = [NSMutableArray array];
//                __weak HMDMemoryMonitor *weakSelf = self;
//                __strong HMDMemoryMonitor *strongSelf = weakSelf;
//                
//                [dumpInfo enumerateObjectsUsingBlock:^(HMDMemoryLiveObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//                    if ([obj respondsToSelector:@selector(jsonObject)]) {
//                        [dumpDataArray addObject:[obj jsonObject]];
//                    }
//                    if(strongSelf != nil) {
//                        if (dumpDataArray.count >= strongSelf->_dumpTopCount) {
//                            *stop = YES;
//                        }
//                    }
//                    
//                }];
//                record.dumpInfo = [dumpDataArray copy];
//            }
//        }];
//    }

    if (identify.length > 0) {
        NSNumber *customMemory = [self.customData hmd_objectForKey:identify class:[NSNumber class]];
        if (customMemory) {
            double customUsage = record.appUsedMemory - customMemory.doubleValue;
            record.customUsedMemory = customUsage;
            record.customScene = identify;
            [self.customData removeObjectForKey:identify];
        }DEBUG_ELSE
    }

    
    [self.curve pushRecord:record];

    return record;
}

- (void)startWithInterval:(CFTimeInterval)interval
{
    [super startWithInterval:interval];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMemoryWarning:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
    
    // 监听内存压力通知
    dispatch_source_t source;
    unsigned long mask = DISPATCH_MEMORYPRESSURE_WARN|DISPATCH_MEMORYPRESSURE_CRITICAL|0x8|0x10|0x20;
    
    source = dispatch_source_create(
                                    DISPATCH_SOURCE_TYPE_MEMORYPRESSURE,
                                    0,
                                    mask,
                                    hmd_get_monitor_queue()
                                    );
    
    if (!source) {
        // 不支持的系统上会出现 source 为空，fallback 为
        // DISPATCH_MEMORYPRESSURE_WARN|DISPATCH_MEMORYPRESSURE_CRITICAL
        mask = DISPATCH_MEMORYPRESSURE_WARN|DISPATCH_MEMORYPRESSURE_CRITICAL;
        source = dispatch_source_create(
                                        DISPATCH_SOURCE_TYPE_MEMORYPRESSURE,
                                        0,
                                        mask,
                                        hmd_get_monitor_queue()
                                        );
    }
    
    if (source) {
        dispatch_source_set_event_handler(source, ^{
            dispatch_source_memorypressure_flags_t memory_pressure = dispatch_source_get_data(source);
            HMDMemoryStatusType type = HMDMemoryStatusTypeDefault;
            switch (memory_pressure) {
                case DISPATCH_MEMORYPRESSURE_WARN:
                    type = HMDMemoryStatusTypeMemoryPressure2;
                    break;
                case DISPATCH_MEMORYPRESSURE_CRITICAL:
                    type = HMDMemoryStatusTypeMemoryPressure4;
                    break;
                case 0x8:
                    type = HMDMemoryStatusTypeMemoryPressure8;
                    break;
                case 0x10:
                    type = HMDMemoryStatusTypeMemoryPressure16;
                    break;
                case 0x20:
                    type = HMDMemoryStatusTypeMemoryPressure32;
                    break;
                default:
                    break;
            }
            [self refresh:type relativeforScene:nil identifier:nil];
        });
        dispatch_resume(source);
        self.memoryPressureSource = source;
    }
}

- (void)stop
{
    [super stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    if (self.memoryPressureSource) {
        dispatch_source_cancel(self.memoryPressureSource);
    }
}

- (void)didReceiveMemoryWarning:(NSNotification *)notifi
{
    dispatch_on_monitor_queue(^{
        [self refresh:HMDMemoryStatusTypeSystemWarning relativeforScene:nil identifier:nil];
    });
}


#pragma mark HeimdallrModule

- (void)didEnterScene:(NSString *)scene {
    if (scene) {
        self.curPageUsage = hmd_getAppMemoryBytes();
    }
}

- (void)willLeaveScene:(NSString *)scene {
    if (scene) {
        [self refresh:HMDMemoryStatusTypeDefault relativeforScene:scene identifier:nil];
    }
}

#pragma - mark upload

- (NSUInteger)reporterPriority {
    return HMDReporterPriorityMemoryMonitor;
}

#pragma - mark 懒加载
- (NSMutableDictionary *)customData {
    if (!_customData) {
        _customData = [NSMutableDictionary dictionary];
    }
    return _customData;
}

@end
