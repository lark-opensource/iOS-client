//
//  HMDInjectedInfo+LegacyDBOptimize.m
//  Heimdallr
//
//  Created by ByteDance on 2023/8/8.
//

#import "HMDInjectedInfo+LegacyDBOptimize.h"
#import <objc/runtime.h>

@implementation HMDInjectedInfo (LegacyDBOptimize)

- (void)setEnableLegacyDBOptimize:(BOOL)enableLegacyDBOptimize {
    objc_setAssociatedObject(self, @selector(enableLegacyDBOptimize), @(enableLegacyDBOptimize), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)enableLegacyDBOptimize {
    NSNumber *res = objc_getAssociatedObject(self, _cmd);
    return [res boolValue];
}

@end
