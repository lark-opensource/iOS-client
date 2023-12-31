//
//  BDPAppPage+BAPTracing.m
//  Timor
//
//  Created by Chang Rong on 2020/2/17.
//

#import "BDPAppPage+BAPTracing.h"
#import <objc/runtime.h>
#import <ECOInfra/BDPLog.h>

static char kAppPageTraceKey;

@implementation BDPAppPage(BAPTracing)

- (void)bap_bindTracing:(BDPTracing *)trace {
    if (!trace) {
        BDPLogWarn(@"traceId is null");
        NSAssert(NO, @"traceId is null");
        return;
    }
    if (self.bap_trace) {
        // 实例重复绑定trace
        BDPLogWarn(@"bind traceId repeat");
        NSAssert(NO, @"bind traceId repeat");
        return;
    }
    objc_setAssociatedObject(self, &kAppPageTraceKey, trace, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BDPTracing *)bap_trace {
    return objc_getAssociatedObject(self, &kAppPageTraceKey);
}

@end
