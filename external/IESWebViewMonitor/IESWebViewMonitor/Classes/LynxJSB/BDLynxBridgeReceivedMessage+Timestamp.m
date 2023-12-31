//
//  BDLynxBridgeReceivedMessage+Timestamp.m
//  IESWebViewMonitor
//
//  Created by Paklun Cheng on 2020/9/15.
//

#import "BDLynxBridgeReceivedMessage+Timestamp.h"
#import <objc/runtime.h>

@implementation BDLynxBridgeReceivedMessage (Timestamp)
- (long)bdwm_invokeTS {
    return [objc_getAssociatedObject(self, _cmd) longValue];
}

- (void)setBdwm_invokeTS:(long long)invokeTS {
    objc_setAssociatedObject(self, @selector(bdwm_invokeTS), @(invokeTS), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

@implementation BDLynxBridgeSendMessage (Timestamp)
- (long)bdwm_callbackTS {
    return [objc_getAssociatedObject(self, _cmd) longValue];
}

- (void)setBdwm_callbackTS:(long long)callbackTS {
    objc_setAssociatedObject(self, @selector(bdwm_callbackTS), @(callbackTS), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (long)bdwm_fireEventTS {
    return [objc_getAssociatedObject(self, _cmd) longValue];
}

- (void)setBdwm_fireEventTS:(long long)fireEventTS {
    objc_setAssociatedObject(self, @selector(bdwm_fireEventTS), @(fireEventTS), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (long)bdwm_endTS {
    return [objc_getAssociatedObject(self, _cmd) longValue];
}

- (void)setBdwm_endTS:(long long)endTS {
    objc_setAssociatedObject(self, @selector(bdwm_endTS), @(endTS), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
