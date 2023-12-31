//
//  HMDTTMonitor+Sample.h
//  Pods
//
//  Created by fengyadong on 2019/12/15.
//
#import "HMDTTMonitor.h"

@class HMDMonitorDataManager;

@interface HMDTTMonitor (Sample)

@property (nonatomic, strong, readonly, nullable) HMDMonitorDataManager *dataManager;

- (void)setdDefaultSampleEnabled:(BOOL)enabled forLogType:(nonnull NSString *)logType __attribute__((deprecated("deprecated. The new version does not need to invoke it")));
- (void)setdDefaultSampleEnabled:(BOOL)enabled forServiceName:(nonnull NSString *)serviceName __attribute__((deprecated("deprecated. The new version does not need to invoke it")));

@end

