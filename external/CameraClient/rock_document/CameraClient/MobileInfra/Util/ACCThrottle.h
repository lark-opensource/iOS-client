//
//  ACCThrottle.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/3/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACCThrottleExecutor)(NSDictionary *_Nullable userInfo);

@interface ACCThrottle : NSObject

+ (instancetype)throttleWithTimeInterval:(NSTimeInterval)timeInterval executor:(ACCThrottleExecutor)executor;

@property (nonatomic, copy) ACCThrottleExecutor executor;

/// second
@property (nonatomic, assign) NSTimeInterval timeInterval;

@property (nonatomic, assign, readonly) BOOL isIdle;

/// 空闲则立即执行，否则重新开始计时, 直到结束后执行
- (void)tryExecuteWithUserInfo:(NSDictionary *_Nullable)userInfo;

- (void)cancelExecute;

@end

NS_ASSUME_NONNULL_END
