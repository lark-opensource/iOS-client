//
//  BDAutoTrackConfig+BDroneMonitor.m
//  Pods
//
//  Created by bytedance on 2023/4/27.
//

#import <objc/runtime.h>
#import "BDAutoTrackConfig+BDroneMonitor.h"

@implementation BDAutoTrackConfig (BDroneMonitor)

/* monitorSamplingRate */
- (NSUInteger)monitorSamplingRate {
    return [objc_getAssociatedObject(self, @selector(monitorSamplingRate)) unsignedIntValue];
}

- (void)setMonitorSamplingRate:(NSUInteger)rate {
    objc_setAssociatedObject(self, @selector(monitorSamplingRate), @(rate), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
