//
//  BDTrackerProtocolHelper+BDTracker.m
//  BDTrackerProtocol
//
//  Created by bob on 2020/3/20.
//

#import "BDTrackerProtocolHelper+BDTracker.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation BDTrackerProtocolHelper (BDTracker)

+ (void)bdTrackEventWithCustomKeys:(NSString *)event
                             label:(NSString *)label
                             value:(NSString *)value
                            source:(NSString *)source
                          extraDic:(NSDictionary *)extraDic {
    Class cls = [BDTrackerProtocolHelper bdtrackerCls];
    SEL sel = @selector(bdTrackEventWithCustomKeys:label:value:source:extraDic:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(Class,SEL,NSString*,NSString*, NSString*, NSString*, NSDictionary*) = (void(*)(Class,SEL,NSString*,NSString*, NSString*, NSString*, NSDictionary*))objc_msgSend;
        action(cls, sel, event,label,value,source,extraDic);
    } else {
        // error
    }
}

@end
