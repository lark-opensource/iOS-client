//
//  HMDPowerMonitorRecord.h
//  AppHost-Heimdallr-Unit-Tests
//
//  Created by bytedance on 2023/11/3.
//

#import "HMDMonitorRecord.h"

NS_ASSUME_NONNULL_BEGIN

#define HMDPowerLogAppSessionName @"app_state"
#define HMDPowerLogAppSessionSceneName @"ALL"

@interface HMDPowerMonitorRecord : HMDMonitorRecord

@property (nonatomic, assign) NSTimeInterval startTimestamp;
@property (nonatomic, assign) NSTimeInterval endTimestamp;
@property (nonatomic, assign) NSTimeInterval totalTime;

// metric
@property (nonatomic, assign) HMDMonitorRecordValue totalBatteryLevelCost;
@property (nonatomic, assign) HMDMonitorRecordValue thermalNominalTime;
@property (nonatomic, assign) HMDMonitorRecordValue thermalFairTime;
@property (nonatomic, assign) HMDMonitorRecordValue thermalSeriousTime;
@property (nonatomic, assign) HMDMonitorRecordValue thermalCriticalTime;
@property (nonatomic, assign) HMDMonitorRecordValue gpuUsage;
@property (nonatomic, assign) HMDMonitorRecordValue ioWrites;

// category
@property (nonatomic, assign) NSUInteger cpuCoreNum;
@property (nonatomic, assign) NSUInteger isBackground;
@property (nonatomic, assign) NSUInteger isLowPowerMode;
@property (nonatomic, copy, nullable) NSString *batteryState;
@property (nonatomic, copy, nullable) NSString *userInterfaceStyle;

@end

NS_ASSUME_NONNULL_END
