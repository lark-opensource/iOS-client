//
//  HMDLaunchTiming+Private.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/7/21.
//

#import "HMDLaunchTiming.h"

@class HMDLaunchTimingRecord;
@class HMDLaunchTaskSpan;

NS_ASSUME_NONNULL_BEGIN

@protocol HMDLaunchTimingListener <NSObject>

@optional
- (void)hmdLaunchTimingDefaultTaskSpans:(NSArray<HMDLaunchTaskSpan *> *)spans;

@end

@interface HMDLaunchTiming (Private)

@property (nonatomic, strong) dispatch_queue_t operationQueue;

- (void)hmdLaunchCollectRecord:(HMDLaunchTimingRecord *)record;
- (void)addTimingListener:(id<HMDLaunchTimingListener>)listener;
- (void)removeTimingListener:(id<HMDLaunchTimingListener>)listener;

@end

NS_ASSUME_NONNULL_END
