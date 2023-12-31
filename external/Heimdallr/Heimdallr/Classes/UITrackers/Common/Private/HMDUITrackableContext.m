//
//  HMDUITrackableContext.m
//  HMDUITrackerRecreate
//
//  Created by bytedance on 2021/12/2.
//

#include <objc/runtime.h>
#import "HMDUITrackableContext.h"
#import "HMDUITracker.h"
#import "HMDUITracker+Private.h"

@implementation HMDUITrackableContext

- (void)trackableDidTrigger:(NSDictionary *)info {
    [HMDUITracker.sharedInstance trackableContext:self
                                  didTriggerEvent:HMDUITrackableEventTrigger
                                       parameters:info];
}

- (void)trackableEvent:(NSString *)eventName info:(NSDictionary *)info {
    [HMDUITracker.sharedInstance trackableContext:self
                                    eventWithName:eventName parameters:info];
}

- (void)trackableDidLoadWithDuration:(CFTimeInterval)duration {
    self.trackableState = HMDUITrackableStateLoad;
    [HMDUITracker.sharedInstance trackableContext:self
                                  didTriggerEvent:HMDUITrackableEventLoad];
}

- (void)trackableWillAppear {
    self.trackableState = HMDUITrackableStateAppear;
    [[HMDUITracker sharedInstance] trackableContext:self didTriggerEvent:HMDUITrackableEventAppear];
}

- (void)trackableDidAppear {
    
}

- (void)trackableWillDisappear {
    
}

- (void)trackableDidUnload {
    
}

- (void)trackableDidDisappear {
    self.trackableState = HMDUITrackableStateDisappear;
    [HMDUITracker.sharedInstance trackableContext:self didTriggerEvent:HMDUITrackableEventDisappear];
}

- (void)trackableDidSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *indexString = [NSString stringWithFormat:@"%li-%li",indexPath.section,indexPath.item];
    
    [HMDUITracker.sharedInstance trackableContext:self
                                    eventWithName:@"select_item"
                                       parameters:@{@"index":indexString?:@""}];
}

@end

@implementation NSObject (HMDTrackable)

- (void)setHmd_trackContext:(id)object {
    objc_setAssociatedObject(self, @selector(hmd_trackContext), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)hmd_trackContext {
    if (![self hmd_trackEnabled]) {
        return nil;
    }
    HMDUITrackableContext *context = objc_getAssociatedObject(self, @selector(hmd_trackContext));
    if (context == nil) {
        context = [[HMDUITrackableContext alloc] init];
        context.trackable = self;
        context.trackName = [self hmd_defaultTrackName];
        [self setHmd_trackContext:context];
    }
    return context;
}

- (NSString *)hmd_defaultTrackName {
    NSString *name = NSStringFromClass([self class]);
    return name;
}

- (BOOL)hmd_trackEnabled {
    return NO;
}

@end
