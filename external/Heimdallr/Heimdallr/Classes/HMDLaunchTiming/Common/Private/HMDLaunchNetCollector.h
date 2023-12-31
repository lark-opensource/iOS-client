//
//  HMDLaunchNetCollector.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/7/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDLaunchNetCollector : NSObject

@property (nonatomic, assign) long long launchEndTS;
@property (nonatomic, assign) long long launchStartTS;
@property (atomic, assign) BOOL isRunning;

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
