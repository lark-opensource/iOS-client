//
//  BDTrackerProtocol+ObserveDeviceID.m
//  BDTrackerProtocol
//
//  Created by on 2020/6/1.
//

#import "BDTrackerProtocol+ObserveDeviceID.h"
#import "BDTrackerProtocolHelper+TTTracker.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation BDTrackerProtocol (ObserveDeviceID)

+ (void)observeDeviceDidRegistered:(BDTrackerObserveDeviceIDCallback)callback
{
    if ([BDTrackerProtocolHelper trackerType] == kTrackerTypeBDtracker) {
        Class cls = [BDTrackerProtocolHelper trackerCls];
        SEL sel = @selector(setDidRegisterBlock:);
        if (cls && sel && [cls respondsToSelector:sel]) {
            void (*action)(Class, SEL, BDTrackerObserveDeviceIDCallback) = (void (*)(Class, SEL, BDTrackerObserveDeviceIDCallback))objc_msgSend;
            action(cls, sel, callback);
        }
    } else {
        [BDTrackerProtocolHelper observeDeviceDidRegistered:callback];
    }
}

+ (void)activateDeviceWithRetryTimes:(NSInteger)retryTimes
                   completionHandler:(BDTrackerProtocolActivateHandler)completionHandler {
    if ([BDTrackerProtocolHelper trackerType] == kTrackerTypeBDtracker) {
        Class cls = [BDTrackerProtocolHelper trackerCls];
        SEL sel = @selector(activateDeviceWithRetryTimes:completionHandler:);
        if (cls && sel && [cls respondsToSelector:sel]) {
            void (*action)(Class, SEL, NSInteger, BDTrackerProtocolActivateHandler) = (void (*)(Class, SEL, NSInteger, BDTrackerProtocolActivateHandler))objc_msgSend;
            action(cls, sel, retryTimes, completionHandler);
        }
    } else {
        [BDTrackerProtocolHelper activateDeviceWithRetryTimes:retryTimes completionHandler:completionHandler];
    }
}

+ (BOOL)isDeviceActivated {
    if ([BDTrackerProtocolHelper trackerType] == kTrackerTypeBDtracker) {
        Class cls = [BDTrackerProtocolHelper trackerCls];
        SEL sel = @selector(isDeviceActivated);
        if (cls && sel && [cls respondsToSelector:sel]) {
            BOOL (*action)(id, SEL) = (BOOL (*)(id, SEL))objc_msgSend;
            return action(cls, sel);
        }
    } else {
        return [BDTrackerProtocolHelper isDeviceActivated];
    }
    
    return NO;
}

@end
