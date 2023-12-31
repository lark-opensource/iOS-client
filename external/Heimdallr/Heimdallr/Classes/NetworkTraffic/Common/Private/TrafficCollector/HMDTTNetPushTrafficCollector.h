//
//  HMDTTNetPushMonitor.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/12/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDTTNetPushTrafficCollector : NSObject

@property (atomic, assign, readonly) BOOL isRunning;

+ (instancetype)sharedInstance;

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
