//
//  BDAutoTrackMonitorStore.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/4/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDAutoTrackMetrics;
@interface BDAutoTrackMonitorStore : NSObject

+ (instancetype)sharedStore;

+ (void)sampling:(NSUInteger)monitorSamplingRate;

- (void)enqueue:(NSArray<BDAutoTrackMetrics *> *)metricsList;

- (void)dequeue:(NSString *)appId usingBlock:(BOOL (^)(NSArray<BDAutoTrackMetrics *> *metricsList))block;

- (void)updateProcess:(NSString *)procId;


@end

NS_ASSUME_NONNULL_END
