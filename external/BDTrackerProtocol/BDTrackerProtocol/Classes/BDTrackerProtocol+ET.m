//
//  BDTrackerProtocol+ET.m
//  BDTrackerProtocol
//
//  Created by bob on 2020/12/17.
//

#import "BDTrackerProtocol+ET.h"
#import "BDTrackerProtocolHelper.h"
#import <objc/runtime.h>
#import <objc/message.h>


@implementation BDTrackerProtocol (ET)

+ (void)loginETWithScheme:(NSString *)scheme {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(loginETWithScheme:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(id, SEL, NSString *) = (void (*)(id, SEL, NSString *))objc_msgSend;
        action(cls, sel, scheme);
    }
}

@end
