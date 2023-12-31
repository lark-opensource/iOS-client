//
//  NSURLSessionTask+BDPowerLog.m
//  LarkMonitor
//
//  Created by ByteDance on 2022/9/13.
//

#import "NSURLSessionTask+BDPowerLog.h"
#import <objc/runtime.h>
#import "BDPowerLogUtility.h"
@implementation NSURLSessionTask (BDPowerLog)

#if DEBUG
- (void)dealloc {
    if ((self.bd_pl_initTime > 0 || self.bd_pl_startTime > 0) && self.bd_pl_endTime == 0) {
        BDPL_DEBUG_LOG_TAG(NET,@"urlsession task invalid %@ %@",self,self.originalRequest.URL);
    }
}
#endif

@dynamic bd_pl_initTime;
@dynamic bd_pl_startTime;
@dynamic bd_pl_endTime;

- (void)setBd_pl_initTime:(long long)bd_pl_initTime {
    objc_setAssociatedObject(self, @selector(bd_pl_initTime), @(bd_pl_initTime), OBJC_ASSOCIATION_RETAIN);
}

- (long long)bd_pl_initTime {
    return [objc_getAssociatedObject(self, @selector(bd_pl_initTime)) longLongValue];
}

- (void)setBd_pl_startTime:(long long)bd_pl_startTime{
    objc_setAssociatedObject(self, @selector(bd_pl_startTime), @(bd_pl_startTime), OBJC_ASSOCIATION_RETAIN);
}

- (long long)bd_pl_startTime {
    return [objc_getAssociatedObject(self, @selector(bd_pl_startTime)) longLongValue];
}

- (void)setBd_pl_endTime:(long long)bd_pl_endTime{
    objc_setAssociatedObject(self, @selector(bd_pl_endTime), @(bd_pl_endTime), OBJC_ASSOCIATION_RETAIN);
}

- (long long)bd_pl_endTime {
    return [objc_getAssociatedObject(self, @selector(bd_pl_endTime)) longLongValue];
}

@end
