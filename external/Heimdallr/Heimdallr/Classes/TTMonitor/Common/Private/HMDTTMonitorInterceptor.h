//
//  HMDTTMonitorInterceptor.h
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 29/4/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef DEBUG
#define TICK(category, name) \
    NSTimeInterval beginTime = CFAbsoluteTimeGetCurrent();
#else
#define TICK
#endif

#ifdef DEBUG
#define TOCK(category, name) \
    NSTimeInterval diff = CFAbsoluteTimeGetCurrent() - beginTime; \
    HMDALOG_PROTOCOL_DEBUG_TAG(category, @"name = %@, cost time = %f", name, diff);
#else
#define TOCK
#endif

@class HMDTTMonitorInterceptorParam;
@protocol HMDTTMonitorInterceptor <NSObject>
@required

- (void)handleRequest:(HMDTTMonitorInterceptorParam *)request;

- (void)setNextInterceptor:(id<HMDTTMonitorInterceptor>)interceptor;

@end



@interface HMDTTMonitorImmutableCopyInterceptor : NSObject<HMDTTMonitorInterceptor>
                    
@end

@class HMDTTMonitorTracker;
@interface HMDTTMonitorSampleInterceptor : NSObject<HMDTTMonitorInterceptor>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithQueue:(dispatch_queue_t)queue tracker:(HMDTTMonitorTracker *)tracker;

@end

@interface HMDTTMonitorBlacklistInterceptor : NSObject<HMDTTMonitorInterceptor>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithQueue:(dispatch_queue_t)queue;

@end

@interface HMDTTMonitorFrequenceDetectInterceptor : NSObject<HMDTTMonitorInterceptor>

@end

@class HMDTTMonitorTracker;
@interface HMDTTMonitorTrackerInterceptor : NSObject<HMDTTMonitorInterceptor>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithTracker:(HMDTTMonitorTracker *)tracker queue:(dispatch_queue_t)queue;

@end

NS_ASSUME_NONNULL_END
