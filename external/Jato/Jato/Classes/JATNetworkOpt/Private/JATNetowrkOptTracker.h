//
//  JATNetowrkOptTracker.h
//  TikTok
//
//  Created by zhangxiao on 2022/8/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const JATNetworkOptPathSwitchThreadCheckCost;
extern NSString *const JATNetworkOptTaskExecuteWaitCost;

@interface JATNetowrkOptTracker : NSObject

- (void)trackerService:(NSString *)service metric:(NSDictionary<NSString *, NSNumber *> *)metric;

@end

NS_ASSUME_NONNULL_END
