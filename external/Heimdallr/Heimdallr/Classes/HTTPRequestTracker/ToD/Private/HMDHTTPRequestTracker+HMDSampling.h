//
//  HMDHTTPRequestTracker+HMDSampling.h
//  Heimdallr
//
//  Created by zhangyuzhong on 2022/1/6.
//

#import "HMDHTTPRequestTracker.h"

@class HMDHTTPDetailRecord;

NS_ASSUME_NONNULL_BEGIN

@interface HMDHTTPRequestTracker (HMDSampling)

- (BOOL)checkIfRequestCanceled:(NSURL *)url withError:(NSError *)error andNetType:(NSString *)netType;
- (BOOL)checkIfURLInBlockList:(NSURL *)url;
- (BOOL)checkIfURLInWhiteList:(NSURL *)url;
- (void)sampleAllowHeaderToRecord:(HMDHTTPDetailRecord *)record withRequestHeader:(NSDictionary *)requestHeader andResponseHeader:(NSDictionary *)responseHeader;
- (void)sampleAllowHeaderToRecord:(HMDHTTPDetailRecord *)record withRequestHeader:(NSDictionary *)requestHeader andResponseHeader:(NSDictionary *)responseHeader isMovingLine:(BOOL)isMovingLine;

@end

NS_ASSUME_NONNULL_END
