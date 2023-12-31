//
//  BDTrackerProtocol+Hooker.m
//  BDTrackerProtocol
//
//  Created by bob on 2020/12/16.
//

#import "BDTrackerProtocol+Hooker.h"
#import "BDTrackerProtocolHelper.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation BDTrackerProtocol (Hooker)

+ (void)addHooker:(id<BDTrackerProtocolHooker>)hooker forKey:(NSString *)key {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(addHooker:forKey:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(id, SEL, id, NSString *) = (void (*)(id, SEL, id, NSString *))objc_msgSend;
        action(cls, sel, hooker, key);
    }
}

+ (void)removeHookerForKey:(NSString *)key {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(removeHookerForKey:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(id, SEL, NSString *) = (void (*)(id, SEL, NSString *))objc_msgSend;
        action(cls, sel, key);
    }
}

@end
