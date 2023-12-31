//
//  HMDPowerMonitorRecord.m
//  AppHost-Heimdallr-Unit-Tests
//
//  Created by bytedance on 2023/11/3.
//

#import "HMDPowerMonitorRecord.h"
#import "HMDMonitorRecord+Private.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDHermasCounter.h"
#import "HMDMacro.h"

CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

@interface HMDPowerMonitorRecordAggregateNode : HMDPowerMonitorRecord

@property (nonatomic, copy) NSString *aggregateKey;
@property (nonatomic, assign) NSUInteger gpuUsageCounter;

@end

@implementation HMDPowerMonitorRecordAggregateNode

- (instancetype)initWithRecord:(HMDPowerMonitorRecord *)record {
    if (self = [super init]) {
        // normal
        self.sessionID = record.sessionID;
        self.localID = record.localID;
        self.scene = record.scene;
        self.timestamp = record.timestamp;
        self.inAppTime = record.inAppTime;
        self.netQualityType = record.netQualityType;
        self.business = record.business;
        self.enableUpload = record.enableUpload;
        
        // metric
        self.totalTime = record.totalTime;
        self.totalBatteryLevelCost = record.totalBatteryLevelCost;
        self.thermalNominalTime = record.thermalNominalTime;
        self.thermalFairTime = record.thermalFairTime;
        self.thermalSeriousTime = record.thermalSeriousTime;
        self.thermalCriticalTime = record.thermalCriticalTime;
        self.ioWrites = record.ioWrites;
        self.gpuUsage = record.gpuUsage;
        self.gpuUsageCounter = 1;
        
        // category
        self.cpuCoreNum = record.cpuCoreNum;
        self.isBackground = record.isBackground;
        self.isLowPowerMode = record.isLowPowerMode;
        self.batteryState = record.batteryState;
        self.userInterfaceStyle = record.userInterfaceStyle;
        self.customScene = record.customScene;
        self.filters = record.filters;
        self.extraInfos = record.extraInfos;
    }
    return self;
}

- (void)appendRecord:(HMDPowerMonitorRecord *)record {
    self.totalTime += record.totalTime;
    self.totalBatteryLevelCost += record.totalBatteryLevelCost;
    self.thermalNominalTime += record.thermalNominalTime;
    self.thermalFairTime += record.thermalFairTime;
    self.thermalSeriousTime += record.thermalSeriousTime;
    self.thermalCriticalTime += record.thermalCriticalTime;
    self.ioWrites += record.ioWrites;
    self.gpuUsage += record.gpuUsage;
    self.gpuUsageCounter += 1;
    if (record.timestamp > self.timestamp) {
        self.timestamp = record.timestamp;
    }
    if (record.inAppTime > self.inAppTime) {
        self.inAppTime = record.inAppTime;
    }
    if (record.netQualityType > self.netQualityType) {
        self.netQualityType = record.netQualityType;
    }
}

- (NSDictionary *)reportDictionary {
    if (self.gpuUsageCounter > 0) {
        self.gpuUsage = self.gpuUsage/(double)self.gpuUsageCounter;
        self.gpuUsageCounter = 0;
    }
    return [super reportDictionary];
}

@end

@implementation HMDPowerMonitorRecord

- (NSDictionary *)reportDictionary {
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    
    [dataValue setValue:@"performance_monitor" forKey:@"log_type"];
    [dataValue setValue:@"power_consumption" forKey:@"service"];
   
    // normal
    long long time = MilliSecond(self.timestamp);
    [dataValue setValue:@(time) forKey:@"timestamp"];
    [dataValue setValue:self.sessionID forKey:@"session_id"];
    [dataValue setValue:@(self.inAppTime) forKey:@"inapp_time"];
    [dataValue setValue:@(self.localID) forKey:@"log_id"];
    [dataValue setValue:@"HMDPowerMonitorRecord" forKey:@"class_name"];
    [dataValue setValue:@(self.netQualityType) forKey:@"network_quality"];
    [dataValue setValue:self.business forKey:@"business"];
    
    // metric
    NSMutableDictionary *metric = [NSMutableDictionary dictionary];
    [metric hmd_setSafeObject:@(self.startTimestamp) forKey:@"start_ts"];
    [metric hmd_setSafeObject:@(self.endTimestamp) forKey:@"end_ts"];
    [metric hmd_setSafeObject:@(self.totalTime) forKey:@"total_time"];
    [metric hmd_setSafeObject:@(self.totalBatteryLevelCost > 0 ?: 0) forKey:@"total_battery_level_cost"];
    [metric hmd_setSafeObject:@(self.thermalNominalTime) forKey:@"thermal_nominal_time"];
    [metric hmd_setSafeObject:@(self.thermalFairTime) forKey:@"thermal_fair_time"];
    [metric hmd_setSafeObject:@(self.thermalSeriousTime) forKey:@"thermal_serious_time"];
    [metric hmd_setSafeObject:@(self.thermalCriticalTime) forKey:@"thermal_critical_time"];
    [metric hmd_setSafeObject:@(self.gpuUsage) forKey:@"gpu_usage"];
    [metric hmd_setSafeObject:@(self.ioWrites) forKey:@"io_writes"];
    
    [dataValue hmd_setSafeObject:metric forKey:@"metric"];
    
    // category
    NSMutableDictionary *category = [NSMutableDictionary dictionary];
    [category hmd_setSafeObject:self.scene forKey:@"scene"];
    [category hmd_setSafeObject:@(self.isLowPowerMode) forKey:@"is_low_power_mode"];
    [category hmd_setSafeObject:@(self.cpuCoreNum) forKey:@"cpu_core_num"];
    [category hmd_setSafeObject:self.batteryState forKey:@"battery_state"];
    [category hmd_setSafeObject:self.userInterfaceStyle forKey:@"user_interface_style"];
    [category hmd_setSafeObject:@(self.isBackground) forKey:@"is_background"];
    [category hmd_setSafeObject:@(self.baseSample) forKey:@"base_sample"];
    if (self.customScene.length > 0) {
        [category hmd_setSafeObject:self.customScene forKey:@"custom_scene"];
    }
    NSString *tmaID = [self.filters valueForKey:@"tma_app_id"];
    if (tmaID && [tmaID isKindOfClass:[NSString class]]) {
        [category hmd_setSafeObject:tmaID forKey:@"tma_app_id"];
    }
    [category hmd_addEntriesFromDict:[HMDMonitorRecord getInjectedPatchFilters]];
    
    [dataValue hmd_setSafeObject:category forKey:@"category"];
    
    // extra
    [dataValue hmd_setSafeObject:self.extraInfos forKey:@"extra"];
    
    // enable_upload
    [dataValue setValue:@(self.enableUpload) forKey:@"enable_upload"];
    
    if (hermas_enabled()) {
        self.sequenceCode = self.enableUpload ? [[HMDHermasCounter shared] generateSequenceCode:NSStringFromClass([self class])] : -1;
        [dataValue setValue:@(self.sequenceCode) forKey:@"sequence_code"];
    }
    
    return dataValue;
}

- (BOOL)isAppStateSession {
    return [self.scene isEqualToString:HMDPowerLogAppSessionSceneName];
}

+ (NSArray *)aggregateDataWithRecords:(NSArray<HMDPowerMonitorRecord *> *)records {
    NSMutableArray *dataArray = [NSMutableArray array];
    NSMutableDictionary *aggregateDict = [NSMutableDictionary dictionary];
    for (HMDPowerMonitorRecord *record in records) {
        if ([record isAppStateSession]) {
            NSDictionary *dataValue = [record reportDictionary];
            if (dataValue) {
                [dataArray addObject:dataValue];
            }
        } else {
            NSString *aggregateKey = [NSString stringWithFormat:@"%@_%@_%@_%@_%@_%@", record.sessionID, record.scene, record.batteryState, record.userInterfaceStyle, @(record.isLowPowerMode), @(record.isBackground)];
            HMDPowerMonitorRecordAggregateNode *aggregateNode = [aggregateDict objectForKey:aggregateKey];
            if (aggregateNode) {
                [aggregateNode appendRecord:record];
            } else {
                aggregateNode = [[HMDPowerMonitorRecordAggregateNode alloc] initWithRecord:record];
                [aggregateDict hmd_setSafeObject:aggregateNode forKey:aggregateKey];
            }
        }
    }
    [aggregateDict enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, HMDPowerMonitorRecordAggregateNode * _Nonnull obj, BOOL * _Nonnull stop) {
        NSDictionary *dataValue = [obj reportDictionary];
        if (dataValue) {
            [dataArray addObject:dataValue];
        }
    }];
    return dataArray;
}

@end
