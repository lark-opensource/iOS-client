//
//  HMDURLProtocol+Entry.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/4/25.
//

#import "HMDURLProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class HMDHTTPTrackerConfig;

@interface HMDURLProtocol (Entry)

+ (void)start;
+ (void)stop;
+ (void)updateHMDURLProtocolConfig:(HMDHTTPTrackerConfig *)config;

@end

NS_ASSUME_NONNULL_END
