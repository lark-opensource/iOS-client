//
//  BDPowerLogHighPowerConfig.h
//  Jato
//
//  Created by ByteDance on 2022/11/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPowerLogHighPowerConfig : NSObject<NSCopying>

@property(nonatomic, assign) BOOL enable;

@property(nonatomic, assign) int appTimeWindow;
@property(nonatomic, assign) int appCPUTimeThreshold;
@property(nonatomic, assign) int appTimeWindowMax;

@property(nonatomic, assign) int deviceTimeWindow;
@property(nonatomic, assign) int deviceCPUTimeThreshold;
@property(nonatomic, assign) int deviceTimeWindowMax;

@property(nonatomic, assign) BOOL enableStackSample;
@property(nonatomic, assign) double stackSampleInterval;
@property(nonatomic, assign) double stackSampleThreadUsageThreshold;
@property(nonatomic, assign) int stackSampleThreadCount;
@property(nonatomic, assign) int stackSampleCoolDownInterval;

- (double)appCPUUsageThreshold;

- (double)deviceCPUUsageThreshold;

@end

NS_ASSUME_NONNULL_END
