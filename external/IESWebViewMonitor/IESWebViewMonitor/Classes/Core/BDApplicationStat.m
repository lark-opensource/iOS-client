//
//  BDApplicationStat.m
//  IESWebViewMonitor
//
//  Created by bytedance on 2020/6/11.
//

#import "BDApplicationStat.h"
#import "IESLiveMonitorUtils.h"
#import <objc/runtime.h>
#import "BDMonitorThreadManager.h"

static NSDate *mTouchDate = nil;
static IMP mUIApplicationStatIMP = nil;

@interface UIApplication(BDApplicationStat)

@end

@implementation UIApplication (BDApplicationStat)

- (void)bdhr_sendEvent:(UIEvent *)event {
    if (event.type == UIEventTypeTouches) {
        mTouchDate = [NSDate date];
    }
    [self bdhr_sendEvent:event];
}

@end

@implementation BDApplicationStat

+ (void)startCollectUpdatedClick {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mUIApplicationStatIMP = class_getMethodImplementation(UIApplication.class , @selector(bdhr_sendEvent:));
        [IESLiveMonitorUtils hookMethod:UIApplication.class
                             fromSelStr:@"sendEvent:"
                               toSelStr:@"bdhr_sendEvent:"
                              targetIMP:mUIApplicationStatIMP];
    });
}

+ (NSDate *)getLatestClickDate {
    return mTouchDate;
}

+ (long)getLatestClickTimestamp {
    __block long ts = 0;
    [BDMonitorThreadManager dispatchSyncHandlerForceOnMainThread:^{
        ts = (long)([mTouchDate timeIntervalSince1970] * 1000);
    }];
    return ts;
}

@end
