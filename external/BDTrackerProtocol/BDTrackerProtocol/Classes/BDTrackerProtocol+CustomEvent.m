//
//  BDTrackerProtocol+CustomEvent.m
//  BDTrackerProtocol
//
//  Created by bob on 2020/3/13.
//

#import "BDTrackerProtocol+CustomEvent.h"
#import "BDTrackerProtocolHelper.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation BDTrackerProtocol (CustomEvent)

+ (void)trackItemImpressionEvent:(NSDictionary *)event {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(trackItemImpressionEvent:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(id, SEL, NSDictionary *) = (void (*)(id, SEL, NSDictionary *))objc_msgSend;
        action(cls, sel, event);
    }
}

+ (void)trackLogDataEvent:(NSDictionary *)event {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(trackLogDataEvent:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(id, SEL, NSDictionary *) = (void (*)(id, SEL, NSDictionary *))objc_msgSend;
        action(cls, sel, event);
    }
}

+ (void)trackCustomKey:(NSString *)key withEvent:(NSDictionary *)event {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(trackCustomKey:withEvent:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(id, SEL, NSString *, NSDictionary *) = (void (*)(id, SEL, NSString *, NSDictionary *))objc_msgSend;
        action(cls, sel, key, event);
    }
}

@end
