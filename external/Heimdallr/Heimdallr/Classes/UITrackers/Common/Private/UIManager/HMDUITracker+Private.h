//
//  HMDUITracker+Private.h
//  HMDUITrackerRecreate
//
//  Created by bytedance on 2021/12/2.
//

#import "HMDUITracker.h"
#import "HMDUITrackableContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDUITracker (Private)

- (void)trackableContextDidStart:(HMDUITrackableContext *)context;

- (void)trackableContextDidEnd:(HMDUITrackableContext *)context;

- (void)trackableContext:(HMDUITrackableContext *)context
         didTriggerEvent:(HMDUITrackableEvents)event;

- (void)trackableContext:(HMDUITrackableContext *)context
         didTriggerEvent:(HMDUITrackableEvents)event parameters:(NSDictionary * _Nullable)parameters;

- (void)trackableContext:(HMDUITrackableContext *)context
           eventWithName:(NSString *)event parameters:(NSDictionary * _Nullable)parameters;

@end

NS_ASSUME_NONNULL_END
