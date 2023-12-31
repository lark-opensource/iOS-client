//
//  BDTrackerProtocol.m
//  Pods-BDTrackerProtocol
//
//  Created by lizhuopeng on 2019/3/11.
//

#import "BDTrackerProtocol.h"
#import "BDTrackerProtocolHelper.h"
#import "BDTrackerProtocolHelper+TTTracker.h"
#import "BDTrackerProtocolHelper+BDTracker.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation BDTrackerProtocol

+ (void)eventV3:(NSString *_Nonnull)event params:(NSDictionary *_Nullable)params {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(eventV3:params:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(Class,SEL,NSString*,NSDictionary*) = (void(*)(Class,SEL,NSString*,NSDictionary*))objc_msgSend;
        action(cls, sel, event, params);
    } else {
        // error
    }
}

+ (void)eventV3:(NSString *_Nonnull)event params:(NSDictionary *_Nullable)params isDoubleSending:(BOOL)isDoubleSending {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(eventV3:params:isDoubleSending:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(Class,SEL,NSString*,NSDictionary*,BOOL) = (void(*)(Class,SEL,NSString*,NSDictionary*,BOOL))objc_msgSend;
        action(cls, sel, event, params,isDoubleSending);
    } else {
        // error
    }
}

#pragma mark - V1
//================================V1 Interface===================================
+ (void)event:(nonnull NSString *)event {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(event:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(Class,SEL,NSString*) = (void(*)(Class,SEL,NSString*))objc_msgSend;
        action(cls, sel, event);
    } else {
        // error
    }
}

+ (void)event:(nonnull NSString *)event label:(nonnull NSString *)label {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(event:label:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(Class,SEL,NSString*, NSString*) = (void(*)(Class,SEL,NSString*, NSString*))objc_msgSend;
        action(cls, sel, event,label);
    } else {
        // error
    }
}

+ (void)eventData:(nonnull NSDictionary *)event {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(eventData:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(Class,SEL,NSDictionary*) = (void(*)(Class,SEL,NSDictionary*))objc_msgSend;
        action(cls, sel, event);
    } else {
        // error
    }
}

+ (void)eventData:(nonnull NSDictionary *)event isV3Format:(BOOL)isV3Format {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(eventData:isV3Format:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(Class,SEL,NSDictionary*,BOOL) = (void(*)(Class,SEL,NSDictionary*,BOOL))objc_msgSend;
        action(cls, sel, event,isV3Format);
    } else {
        // error
    }
}

+ (void)event:(nonnull NSString *)event
        label:(nonnull NSString *)label
        value:(nullable id)value
     extValue:(nullable id)extValue
    extValue2:(nullable id)extValue2 {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(event:label:value:extValue:extValue2:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(Class,SEL,NSString*, NSString*, id, id, id) = (void(*)(Class,SEL,NSString*, NSString*, id, id, id))objc_msgSend;
        action(cls, sel, event,label,value,extValue,extValue2);
    } else {
        // error
    }
}

+ (void)event:(nonnull NSString *)event
        label:(nonnull NSString *)label
        value:(nullable id)value
     extValue:(nullable id)extValue
    extValue2:(nullable id)extValue2
         dict:(nullable NSDictionary *)aDict {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(event:label:value:extValue:extValue2:dict:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(Class,SEL,NSString*, NSString*, id, id, id, NSDictionary*) = (void(*)(Class,SEL,NSString*, NSString*, id, id, id, NSDictionary*))objc_msgSend;
        action(cls, sel, event,label,value,extValue,extValue2,aDict);
    } else {
        // error
    }
}

+ (void)event:(nonnull NSString *)event label:(nonnull NSString *)label json:(nullable NSString *)json {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(event:label:json:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(Class,SEL,NSString*, NSString*, NSString*) = (void(*)(Class,SEL,NSString*, NSString*, NSString*))objc_msgSend;
        action(cls, sel, event,label,json);
    } else {
        // error
    }
}

+ (void)category:(nonnull NSString *)category event:(nonnull NSString *)event label:(nonnull NSString *)label json:(nullable NSString *)json {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(category:event:label:json:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(Class,SEL,NSString*,NSString*, NSString*, NSString*) = (void(*)(Class,SEL,NSString*,NSString*, NSString*, NSString*))objc_msgSend;
        action(cls, sel, category,event,label,json);
    } else {
        // error
    }
}

+ (void)category:(nonnull NSString *)category event:(nonnull NSString *)event label:(nonnull NSString *)label dict:(nullable NSDictionary *)aDict {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(category:event:label:dict:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(Class,SEL,NSString*,NSString*, NSString*, NSDictionary*) = (void(*)(Class,SEL,NSString*,NSString*, NSString*, NSDictionary*))objc_msgSend;
        action(cls, sel, category,event,label,aDict);
    } else {
        // error
    }
}

+ (void)category:(nonnull NSString *)category event:(nonnull NSString *)event label:(nonnull NSString *)label dict:(nullable NSDictionary *)aDict json:(nullable NSString *)json {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(category:event:label:dict:json:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(Class,SEL,NSString*,NSString*, NSString*, NSDictionary*, NSString*) = (void(*)(Class,SEL,NSString*,NSString*, NSString*, NSDictionary*, NSString*))objc_msgSend;
        action(cls, sel, category,event,label,aDict,json);
    } else {
        // error
    }
}

+ (void)trackEventWithCustomKeys:(nonnull NSString *)event label:(nonnull NSString *)label value:(nullable NSString *)value source:(nullable NSString *)source extraDic:(nullable NSDictionary *)extraDic {
    
    if ([BDTrackerProtocolHelper trackerType] == kTrackerTypeBDtracker) {
        [BDTrackerProtocolHelper bdTrackEventWithCustomKeys:event
                                                      label:label
                                                      value:value
                                                     source:source
                                                   extraDic:extraDic];
    } else {
        [BDTrackerProtocolHelper ttTrackEventWithCustomKeys:event
                                                      label:label
                                                      value:value
                                                     source:source
                                                   extraDic:extraDic];
    }
}

+ (NSString *)sessionID {
    if ([BDTrackerProtocolHelper trackerType] == kTrackerTypeBDtracker) {
        NSString *sessionID = nil;
        Class cls = [BDTrackerProtocolHelper trackerCls];
        SEL sel = @selector(sessionID);
        if (cls && sel && [cls respondsToSelector:sel]) {
            id (*action)(Class, SEL) = (id (*)(Class, SEL))objc_msgSend;
            id obj = action(cls, sel);
            if ([obj isKindOfClass:[NSString class]]) {
                sessionID = obj;
            }
        }
        return sessionID;
    } else {
        return [BDTrackerProtocolHelper tttrackerSessionID];
    }
}

+ (NSString *)deviceID {
    if ([BDTrackerProtocolHelper trackerType] == kTrackerTypeBDtracker) {
        NSString *deviceID = nil;
        Class cls = [BDTrackerProtocolHelper trackerCls];
        SEL sel = @selector(deviceID);
        if (cls && sel && [cls respondsToSelector:sel]) {
            id (*action)(Class, SEL) = (id (*)(Class, SEL))objc_msgSend;
            id obj = action(cls, sel);
            if ([obj isKindOfClass:[NSString class]]) {
                deviceID = obj;
            }
        }
        return deviceID;
    } else {
        return [BDTrackerProtocolHelper tttrackerDeviceID];
    }
}

+ (NSString *)installID {
    if ([BDTrackerProtocolHelper trackerType] == kTrackerTypeBDtracker) {
        NSString *installID = nil;
        Class cls = [BDTrackerProtocolHelper trackerCls];
        SEL sel = @selector(installID);
        if (cls && sel && [cls respondsToSelector:sel]) {
            id (*action)(Class, SEL) = (id (*)(Class, SEL))objc_msgSend;
            id obj = action(cls, sel);
            if ([obj isKindOfClass:[NSString class]]) {
                installID = obj;
            }
        }
        return installID;
    } else {
        return [BDTrackerProtocolHelper tttrackerInstallID];
    }
}

+ (NSString *)clientDID
{
    if ([BDTrackerProtocolHelper trackerType] == kTrackerTypeBDtracker) {
        NSString *clientDID = nil;
        Class cls = [BDTrackerProtocolHelper trackerCls];
        SEL sel = @selector(clientDID);
        if (cls && sel && [cls respondsToSelector:sel]) {
            id (*action)(Class, SEL) = (id (*)(Class, SEL))objc_msgSend;
            id obj = action(cls, sel);
            if ([obj isKindOfClass:[NSString class]]) {
                clientDID = obj;
            }
        }
        return clientDID;
    } else {
        return [BDTrackerProtocolHelper tttrackerClientDID];
    }
}

+ (void)setLaunchFrom:(BDTrackerLaunchFrom)from {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(setLaunchFrom:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(id, SEL, NSUInteger) = (void (*)(id, SEL, NSUInteger))objc_msgSend;
        action(cls, sel, from);
    }
}

+ (BDTrackerLaunchFrom)launchFrom {
    BDTrackerLaunchFrom from = BDTrackerLaunchFromInitialState;
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(launchFrom);
    if (cls && sel && [cls respondsToSelector:sel]) {
        NSUInteger (*action)(id, SEL) = (NSUInteger (*)(id, SEL))objc_msgSend;
        from = action(cls, sel);
    }
    return from;
}

+ (NSString *)launchFromString {
    NSString *launchFromString = nil;
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(launchFromString);
    if (cls && sel && [cls respondsToSelector:sel]) {
        id (*action)(Class, SEL) = (id (*)(Class, SEL))objc_msgSend;
        id obj = action(cls, sel);
        if ([obj isKindOfClass:[NSString class]]) {
            launchFromString = obj;
        }
    }
    
    return launchFromString;
}


@end
