//
//  BDPLLogMonitorConfig.m
//  LarkMonitor
//
//  Created by ByteDance on 2023/4/24.
//

#import "BDPLLogMonitorConfig.h"

@implementation BDPLLogMonitorConfig

- (instancetype)init {
    if (self = [super init]) {
        self.timewindow = 60;
        self.logThreshold = 6000;
    }
    return self;
}

- (double)logThresholdPerSecond {
    return self.timewindow > 0?(self.logThreshold * 1.0/self.timewindow):100;
}

- (id)copyWithZone:(NSZone *)zone {
    BDPLLogMonitorConfig *newObject = [[BDPLLogMonitorConfig alloc] init];
    newObject.timewindow = self.timewindow;
    newObject.logThreshold = self.logThreshold;
    newObject.enableLogCountMetrics = self.enableLogCountMetrics;
    return newObject;
}
@end
