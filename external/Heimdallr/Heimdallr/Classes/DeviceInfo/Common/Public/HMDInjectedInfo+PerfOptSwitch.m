//
//  HMDInjectedInfo+PerfOptSwitch.m
//  Aweme
//
//  Created by ByteDance on 2023/8/23.
//

#import "HMDInjectedInfo+PerfOptSwitch.h"
#import <objc/runtime.h>

@implementation HMDInjectedInfo (PerfOptSwitch)

@dynamic ttMonitorSampleOptEnable;

- (void)setTtmonitorCodingProtocolOptEnabled:(BOOL)ttmonitorCodingProtocolOptEnabled {
    objc_setAssociatedObject(self, @selector(ttmonitorCodingProtocolOptEnabled), @(ttmonitorCodingProtocolOptEnabled), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)ttmonitorCodingProtocolOptEnabled {
    NSNumber *res = objc_getAssociatedObject(self, _cmd);
    return [res boolValue];
}

@end
