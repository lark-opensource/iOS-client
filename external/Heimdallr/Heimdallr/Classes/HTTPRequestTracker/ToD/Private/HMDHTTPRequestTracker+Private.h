//
//  HMDHTTPRequestTracker+Private.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/2/25.
//

#import "HMDHTTPRequestTracker.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HMDHTTPRequestTrackerRecordDelegate <NSObject>

@optional
- (void)asyncHMDHTTPRequestTackerDidCollectedRecord:(HMDHTTPDetailRecord *_Nullable)record;
- (void)asyncHMDHTTPRequestTackerWillCollectedRecord:(HMDHTTPDetailRecord *_Nullable)record;

@end


@interface HMDHTTPRequestTracker (Private)

- (void)addRecordVisitor:(id<HMDHTTPRequestTrackerRecordDelegate>)visitor;
- (void)removeRecordVisitor:(id<HMDHTTPRequestTrackerRecordDelegate>)visitor;

- (NSDictionary *)callHTTPRequestTrackerCallback:(HMDHTTPDetailRecord *)record;

@end

NS_ASSUME_NONNULL_END
