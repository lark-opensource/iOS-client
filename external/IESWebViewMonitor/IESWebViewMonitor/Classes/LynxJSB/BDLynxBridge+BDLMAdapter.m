//
//  BDLynxBridge+BDLMAdapter.m
//  IESWebViewMonitor
//
//  Created by zhangxiao on 2021/7/26.
//

#import "BDLynxBridge+BDLMAdapter.h"
#import "BDHybridMonitorWeakWrap.h"
#import <objc/runtime.h>

@implementation BDLynxBridge (BDLMAdapter)

- (void)setBdhm_jsbDelegate:(id<BDHMLynxJSBMonitorAdapterProtocol>)bdhm_jsbDelegate {
    BDHybridMonitorWeakWrap *weakWrap = [[BDHybridMonitorWeakWrap alloc] init];
    weakWrap.obj = bdhm_jsbDelegate;
    objc_setAssociatedObject(self, @selector(bdhm_jsbDelegate), weakWrap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<BDHMLynxJSBMonitorAdapterProtocol>)bdhm_jsbDelegate {
    BDHybridMonitorWeakWrap *weakWrap = objc_getAssociatedObject(self, _cmd);
    if ([weakWrap isKindOfClass:[BDHybridMonitorWeakWrap class]]) {
        return weakWrap.obj;
    }
    return nil;
}

@end
