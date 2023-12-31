//
//  IESBridgeEngine+BDWMAdapter.m
//  IESWebViewMonitor
//
//  Created by zhangxiao on 2021/7/26.
//

#import "IESBridgeEngine+BDWMAdapter.h"
#import "BDHybridMonitorWeakWrap.h"
#import <objc/runtime.h>

@implementation IESBridgeEngine (BDWMAdapter)

- (void)setBdhm_jsbDelegate:(id<BDHMWebViewJSBMonitorAdapterProtocol>)bdhm_jsbDelegate {
    BDHybridMonitorWeakWrap *weakWrap = [[BDHybridMonitorWeakWrap alloc] init];
    weakWrap.obj = bdhm_jsbDelegate;
    objc_setAssociatedObject(self, @selector(bdhm_jsbDelegate), weakWrap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<BDHMWebViewJSBMonitorAdapterProtocol>)bdhm_jsbDelegate {
    BDHybridMonitorWeakWrap *weakWrap = objc_getAssociatedObject(self, _cmd);
    if ([weakWrap isKindOfClass:[BDHybridMonitorWeakWrap class]]) {
        return weakWrap.obj;
    }
    return nil;
}

@end
