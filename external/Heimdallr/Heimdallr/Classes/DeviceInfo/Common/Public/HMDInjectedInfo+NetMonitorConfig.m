//
//  HMDInjectedInfo+NetMonitorConfig.m
//  Heimdallr
//
//  Created by ByteDance on 2023/6/30.
//

#import "HMDInjectedInfo+NetMonitorConfig.h"
#import <objc/runtime.h>

@implementation HMDInjectedInfo (NetMonitorConfig)

- (void)setAllowedURLRegularOptEnabled:(BOOL)allowedURLRegularOptEnabled {
    objc_setAssociatedObject(self, @selector(allowedURLRegularOptEnabled), @(allowedURLRegularOptEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)allowedURLRegularOptEnabled {
    NSNumber *res = objc_getAssociatedObject(self, _cmd);
    return [res boolValue];
}

- (void)setNotProductHTTPRecordUnHitEnabled:(BOOL)notProductHTTPRecordUnHitEnabled {
    objc_setAssociatedObject(self, @selector(notProductHTTPRecordUnHitEnabled), @(notProductHTTPRecordUnHitEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)notProductHTTPRecordUnHitEnabled {
    NSNumber *res = objc_getAssociatedObject(self, _cmd);
    return [res boolValue];
}

@end
