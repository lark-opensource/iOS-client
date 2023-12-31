//
//  URLSessionTask+Tracing.m
//  Timor
//
//  Created by changrong on 2020/9/16.
//

#import "NSURLSessionTask+Tracing.h"
#import <objc/runtime.h>
#import <ECOInfra/BDPLog.h>
#import <ECOInfra/ECOInfra-Swift.h>

static char kURLSessionTaskBDPTraceKey;

@implementation NSURLSessionTask(Tracing)

- (void)bindTrace:(OPTrace *)trace {
    if (!trace) {
        BDPLogWarn(@"trace is null");
        NSAssert(NO, @"trace is null");
        return;
    }
    if (self.trace) {
        // 实例重复绑定trace
        BDPLogWarn(@"bind trace repeat");
        NSAssert(NO, @"bind trace repeat");
        return;
    }
    objc_setAssociatedObject(self, &kURLSessionTaskBDPTraceKey, trace, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (OPTrace *)trace {
    return objc_getAssociatedObject(self, &kURLSessionTaskBDPTraceKey);
}

@end
