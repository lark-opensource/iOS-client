//
//  BDTrackerProtocolHelper+TTTracker.m
//  BDTrackerProtocol
//
//  Created by bob on 2020/3/20.
//

#import "BDTrackerProtocolHelper+TTTracker.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation BDTrackerProtocolHelper (TTTracker)

+ (NSString *)tttrackerDeviceID {
    static id shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [BDTrackerProtocolHelper installInstance];
    });
    
    NSString *deviceID = nil;
    SEL sel = NSSelectorFromString(@"deviceID");
    if (shareInstance && sel && [shareInstance respondsToSelector:sel]) {
        id (*action)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
        id obj = action(shareInstance, sel);
        if ([obj isKindOfClass:[NSString class]]) {
            deviceID = obj;
        }
    }
    
    return deviceID;
}

+ (NSString *)tttrackerInstallID {
    static id shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [BDTrackerProtocolHelper installInstance];
    });
    
    NSString *installID = nil;
    SEL sel = NSSelectorFromString(@"installID");
    if (shareInstance && sel && [shareInstance respondsToSelector:sel]) {
        id (*action)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
        id obj = action(shareInstance, sel);
        if ([obj isKindOfClass:[NSString class]]) {
            installID = obj;
        }
    }
    
    return installID;
}

+ (nullable NSString *)tttrackerClientDID
{
    static id shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [BDTrackerProtocolHelper installInstance];
    });
    
    NSString *clientDID = nil;
    SEL sel = NSSelectorFromString(@"clientDID");
    if (shareInstance && sel && [shareInstance respondsToSelector:sel]) {
        id (*action)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
        id obj = action(shareInstance, sel);
        if ([obj isKindOfClass:[NSString class]]) {
            clientDID = obj;
        }
    }
    
    return clientDID;
}

+ (NSString *)tttrackerSessionID {
    static id shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [BDTrackerProtocolHelper sessionInstance];
    });
    
    NSString *sessionID = nil;
    SEL sel = NSSelectorFromString(@"sessionID");
    if (shareInstance && sel && [shareInstance respondsToSelector:sel]) {
        id (*action)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
        id obj = action(shareInstance, sel);
        if ([obj isKindOfClass:[NSString class]]) {
            sessionID = obj;
        }
    }
    
    return sessionID;
}

+ (void)ttTrackEventWithCustomKeys:(NSString *)event
                             label:(NSString *)label
                             value:(NSString *)value
                            source:(NSString *)source
                          extraDic:(NSDictionary *)extraDic {
    Class cls = [BDTrackerProtocolHelper tttrackerCls];
    SEL sel = @selector(ttTrackEventWithCustomKeys:label:value:source:extraDic:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(Class,SEL,NSString*,NSString*, NSString*, NSString*, NSDictionary*) = (void(*)(Class,SEL,NSString*,NSString*, NSString*, NSString*, NSDictionary*))objc_msgSend;
        action(cls, sel, event,label,value,source,extraDic);
    } else {
        // error
    }
}

+ (void)observeDeviceDidRegistered:(BDTrackerObserveDeviceIDCallback)callback {
    static id shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [BDTrackerProtocolHelper installInstance];
    });
    
    SEL sel = @selector(observeDeviceDidRegistered:);
    if (shareInstance && sel && [shareInstance respondsToSelector:sel]) {
        void (*action)(id, SEL, BDTrackerObserveDeviceIDCallback) = (void (*)(id, SEL, BDTrackerObserveDeviceIDCallback))objc_msgSend;
        action(shareInstance, sel, callback);
    }
}

+ (void)activateDeviceWithRetryTimes:(NSInteger)retryTimes
                   completionHandler:(BDTrackerProtocolActivateHandler)completionHandler {
    static id shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [BDTrackerProtocolHelper installInstance];
    });
    
    SEL sel = @selector(activateDeviceWithRetryTimes:completionHandler:);
    if (shareInstance && sel && [shareInstance respondsToSelector:sel]) {
        void (*action)(Class, SEL, NSInteger, BDTrackerProtocolActivateHandler) = (void (*)(Class, SEL, NSInteger, BDTrackerProtocolActivateHandler))objc_msgSend;
        action(shareInstance, sel, retryTimes, completionHandler);
    }
}

+ (BOOL)isDeviceActivated {
    static id shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [BDTrackerProtocolHelper installInstance];
    });
    
    SEL sel = @selector(isDeviceActivated);
    if (shareInstance && sel && [shareInstance respondsToSelector:sel]) {
        BOOL (*action)(id, SEL) = (BOOL (*)(id, SEL))objc_msgSend;
        return action(shareInstance, sel);
    }
    
    return NO;
}

+ (id)installInstance {
    Class cls = NSClassFromString(@"TTInstallIDManager");
    SEL shareInstanceSel = NSSelectorFromString(@"sharedInstance");
    id shareInstance = nil;
    if (cls && shareInstanceSel && [cls respondsToSelector:shareInstanceSel]) {
        id (*action)(Class, SEL) = (id (*)(Class, SEL))objc_msgSend;
        shareInstance = action(cls, shareInstanceSel);
    }
    return shareInstance;
}

+ (id)sessionInstance {
    Class cls = NSClassFromString(@"TTTrackerSessionHandler");
    SEL shareInstanceSel = NSSelectorFromString(@"sharedHandler");
    id shareInstance = nil;
    if (cls && shareInstanceSel && [cls respondsToSelector:shareInstanceSel]) {
        id (*action)(Class, SEL) = (id (*)(Class, SEL))objc_msgSend;
        shareInstance = action(cls, shareInstanceSel);
    }
    
    return shareInstance;
}

@end
