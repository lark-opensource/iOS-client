//
//  BDTrackerProtocol+AppExtension.m
//  BDTrackerProtocol
//
//  Created by bob on 2020/11/5.
//

#import "BDTrackerProtocol+AppExtension.h"
#import "BDTrackerProtocolHelper.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation BDTrackerProtocol (AppExtension)

+ (void)eventV3:(NSString *)event
         params:(NSDictionary *)params
      localTime:(long long)localTime {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(eventV3:params:localTime:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(Class,SEL,NSString*,NSDictionary*, long long) = (void(*)(Class,SEL,NSString*,NSDictionary*, long long))objc_msgSend;
        action(cls, sel, event, params, localTime);
    } else {
        /// fallback to v3
        [self eventV3:event params:params];
    }
}

@end
