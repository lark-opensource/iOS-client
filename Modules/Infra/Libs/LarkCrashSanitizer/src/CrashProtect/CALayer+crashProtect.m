//
//  CALayer+crashProtect.m
//  LarkCrashSanitizer
//
//  Created by sniperj on 2020/5/19.
//

#import "CALayer+crashProtect.h"
#import "LKHookUtil.h"
#import <LKLoadable/Loadable.h>
#import <LarkMonitor/LarkPowerOptimizeConfig.h>
#import <UIKit/UIKit.h>

///fix crash http://t.wtturl.cn/otDELR/

static CG_INLINE BOOL LarkCGRectIsNaN(CGRect rect) {
    return isnan(rect.size.width) || isnan(rect.size.height) || isnan(rect.origin.x) || isnan(rect.origin.y);
}

@implementation CALayer (crashProtect)

- (void)my_setBounds:(CGRect)bounds {
    if (LarkPowerOptimizeConfig.enableOptimizeCALayerCrash) {
        NSAssert(LarkCGRectIsNaN(bounds) == NO, @"bounds has NaN value");
        if (isnan(bounds.size.width)) {
            bounds.size.width = 0;
        }
        if (isnan(bounds.size.height)) {
            bounds.size.height = 0;
        }
        if (isnan(bounds.origin.x)) {
            bounds.origin.x = 0;
        }
        if (isnan(bounds.origin.y)) {
            bounds.origin.y = 0;
        }
        [self my_setBounds:bounds];
    } else {
        NSString *bounsString = NSStringFromCGRect(bounds);
        NSAssert([bounsString rangeOfString:@"nan"].length <= 0, @"bounds has NaN value");
        CGRect covertSafeBounds = CGRectFromString(bounsString);
        [self my_setBounds:covertSafeBounds];
    }
}

@end

LoadableRunloopIdleFuncBegin(LarkCrashSanitizer_CALayer)
SwizzleMethod([CALayer class],NSSelectorFromString(@"setBounds:"), [CALayer class] ,@selector(my_setBounds:));
LoadableRunloopIdleFuncEnd(LarkCrashSanitizer_CALayer)
