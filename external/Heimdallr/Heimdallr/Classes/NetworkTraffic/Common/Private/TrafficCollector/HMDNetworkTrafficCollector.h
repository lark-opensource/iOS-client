//
//  HMDTTNetTraffic.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/2/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDNetworkTrafficCollector : NSObject

@property (atomic, assign, readonly) BOOL isRunning;

+ (instancetype)sharedInstance;

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
