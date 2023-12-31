//
//  BDPowerLogHighPowerEvent.h
//  Alamofire
//
//  Created by ByteDance on 2022/11/15.
//

#import <Foundation/Foundation.h>
#import "BDPowerLogHighPowerConfig.h"

NS_ASSUME_NONNULL_BEGIN
@class BDPowerLogCPUMetrics;
@interface BDPowerLogHighPowerEvent : NSObject

@property(nonatomic, copy) BDPowerLogHighPowerConfig *config;

@property(nonatomic, assign) BOOL isForeground;

@property(nonatomic, copy) NSString *enterReason;

@property(nonatomic, copy) NSString *quitReason;

@property(nonatomic, copy) NSString *scene;

@property(nonatomic, copy) NSString *subscene;

@property(nonatomic, copy) NSString *thermalState;

@property(nonatomic, copy) NSString *powerMode;

@property(nonatomic, copy) NSString *batteryState;

@property(nonatomic, assign) int startBatteryLevel;

@property(nonatomic, assign) int endBatteryLevel;

@property(nonatomic, assign) int total_time;

@property(nonatomic, assign) int total_cpu_time;

@property(nonatomic, assign) int total_device_cpu_time;

@property(nonatomic, assign) long long start_time;

@property(nonatomic, assign) long long end_time;

@property(nonatomic, copy) NSString *stackUUID;

@property(nonatomic, assign) int peakThreadCount;

- (void)addCPUMetrics:(NSDictionary *)data;

- (void)addCPUMetricsArray:(NSArray *)cpuMetricsArray;

- (NSDictionary *)uploadLog;

- (double)appCPUUsage;

- (double)deviceCPUUsage;

@end

NS_ASSUME_NONNULL_END
