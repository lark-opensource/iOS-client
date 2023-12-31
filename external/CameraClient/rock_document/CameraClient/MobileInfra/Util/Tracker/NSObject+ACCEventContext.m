//
//  NSObject+ACCEventContext.m
//  Pods
//
//  Created by chengfei xiao on 2019/8/1.
//

#import "NSObject+ACCEventContext.h"
#import <objc/runtime.h>
#import <CreativeKit/ACCTrackProtocol.h>

@implementation NSObject (ACCEventContext)

- (ACCEventContext *)acc_eventContext
{
    ACCEventContext *context = objc_getAssociatedObject(self, _cmd);
    if (!context) {
        context = [[ACCEventContext alloc] init];
        self.acc_eventContext = context;
    }
    return context;
}

- (void)setAcc_eventContext:(ACCEventContext *)acc_eventContext
{
    objc_setAssociatedObject(self, @selector(acc_eventContext), acc_eventContext, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)acc_trackEvent:(NSString *)event
{
    [self acc_trackEvent:event context:self.acc_eventContext.baseContext];
}

- (void)acc_trackEvent:(NSString *)event attributes:(void (^)(ACCAttributeBuilder *))block
{
    [self acc_trackEvent:event context:[self.acc_eventContext makeAttributes:block]];
}

- (void)acc_trackEvent:(NSString *)event context:(ACCEventContext *)context
{
    [ACCTracker() trackEvent:event params:[context attributes]];
}

+ (void)acc_trackEvent:(NSString *)event context:(ACCEventContext *)context
{
    [ACCTracker() trackEvent:event params:[context attributes]];
}

@end
