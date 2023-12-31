//
//  BDPowerLogHighPowerConfig.m
//  Jato
//
//  Created by ByteDance on 2022/11/15.
//

#import "BDPowerLogHighPowerConfig.h"

@implementation BDPowerLogHighPowerConfig

- (instancetype)init {
    if (self = [super init]) {
        self.enable = NO;
        self.appTimeWindow = 60;
        self.appCPUTimeThreshold = 30;
        self.appTimeWindowMax = 180;
        self.deviceTimeWindow = 60;
        self.deviceCPUTimeThreshold = 60;
        self.deviceTimeWindowMax = 180;
        self.enableStackSample = NO;
        self.stackSampleInterval = 2;
        self.stackSampleThreadUsageThreshold = 5;
        self.stackSampleThreadCount = 5;
        self.stackSampleCoolDownInterval = 60*60;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    BDPowerLogHighPowerConfig *newObject = [[BDPowerLogHighPowerConfig alloc] init];
    newObject.enable = self.enable;
    newObject.appTimeWindow = self.appTimeWindow;
    newObject.appCPUTimeThreshold = self.appCPUTimeThreshold;
    newObject.appTimeWindowMax = self.appTimeWindowMax;
    newObject.deviceTimeWindow = self.deviceTimeWindow;
    newObject.deviceCPUTimeThreshold = self.deviceCPUTimeThreshold;
    newObject.deviceTimeWindowMax = self.deviceTimeWindowMax;
    newObject.enableStackSample = self.enableStackSample;
    newObject.stackSampleInterval = self.stackSampleInterval;
    newObject.stackSampleThreadUsageThreshold = self.stackSampleThreadUsageThreshold;
    newObject.stackSampleThreadCount = self.stackSampleThreadCount;
    newObject.stackSampleCoolDownInterval = self.stackSampleCoolDownInterval;
    return newObject;
}

- (double)appCPUUsageThreshold {
    double appUsageThreshold = self.appTimeWindow > 0 ? self.appCPUTimeThreshold * 100.0/self.appTimeWindow : INT_MAX;
    return appUsageThreshold;
}

- (double)deviceCPUUsageThreshold {
    double deviceUsageThreshold = self.deviceTimeWindow >0 ? self.deviceCPUTimeThreshold * 100.0/self.deviceTimeWindow : INT_MAX;
    return deviceUsageThreshold;;
}

@end
